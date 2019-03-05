# consulta o mes de referencia dos precos disponibilizados e retorna o codigo correspondente
#
get_reference <-  function(date) {

  date_month <- lubridate::floor_date(check_date(date), "month")

  httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarTabelaDeReferencia",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/")
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  dplyr::mutate(date = lubridate::dmy(paste0("01/", Mes))) %>%
  dplyr::select(date, reference_code = Codigo) %>%
  dplyr::filter(date %in% date_month) %>%
  dplyr::pull(reference_code)
}


# retira caracteres especiais e simflifica a grafica para facilitar o match dos nomes
#
clean_name <- function(x) {
  x %>%
    stringr::str_to_lower() %>%
     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT')
}


# consulta as marcas disponiveis para um determinado mes de referencia e retorna o codigo correspondente
#
get_make <- function(make = NULL, reference_code) {

  table_make <- httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarMarcas",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTabelaReferencia = reference_code,
      codigoTipoVeiculo = 1
    )
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  dplyr::rename(make_name = Label, make_code = Value) %>%
  dplyr::mutate(make_code = as.integer(make_code))

  if (is.null(make)) {

    table_make %>%
      dplyr::pull(make_code) %>%
      return()

  } else {

    table_make %>%
      dplyr::filter(clean_name(make_name) %in% clean_name(make)) %>%
      dplyr::pull(make_code) %>%
      return()
  }
}


# consulta os modelos disponiveis para um determinado mes de referencia e marca e retorna o codigo correspondente
#
get_model <- function(model, make = NULL, reference_code) {

  reference_code_max <- reference_code[which.max(reference_code)]

  make_code <- get_make(make, reference_code_max)

  models <- paste0(stringr::str_to_lower(model), collapse = "|")

  purrr::map_dfr(
    make_code,
    ~httr::POST(
      "http://veiculos.fipe.org.br/api/veiculos/ConsultarModelos",
      httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
      body = list(
        codigoTipoVeiculo = 1,
        codigoTabelaReferencia = reference_code_max,
        codigoMarca = .x
      )
    ) %>%
    httr::content("text", encoding = "UTF-8") %>%
    jsonlite::fromJSON() %>%
    '[['(1) %>%
    tibble::rownames_to_column() %>%
    dplyr::select(model_name = Label, model_code = Value) %>%
    dplyr::mutate(
      make_code = .x,
      model_name = clean_name(model_name)
    ) %>%
    tibble::as_tibble()
  ) %>%
  dplyr::filter(stringr::str_detect(model_name, models))
}


# extrai tabela com os anos disponíveis de cada modelo
#
get_table_year <- function(reference_code, model_code, make_code) {

  content <- httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarAnoModelo",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTipoVeiculo = 1,
      codigoTabelaReferencia = reference_code,
      codigoModelo = model_code,
      codigoMarca = make_code
    )
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON()

  if (content[[2]][[1]] == "nadaencontrado") return(NULL)

  content %>%
    tidyr::separate(Label, c("ano", "combustivel")) %>%
    dplyr::mutate(
      ano = ifelse(ano == "32000", 0L, as.integer(ano))
    ) %>%
    dplyr::select(year = ano, year_code = Value) %>%
    tibble::as_tibble()
}


# consulta o ano do modelo disponivel para um determinado mes de referencia, make e modelo
#
get_year <- function(model, make = NULL, year_filter = NULL, reference_code) {

  #reference_code_max <- reference_code[which.max(reference_code)]

  model_code <- get_model(model, make, reference_code)

  if (nrow(model_code) == 0) stop("Model not found", call. = FALSE)

  table_year <- model_code %>%
    tidyr::crossing(., reference_code_range = range(reference_code)) %>%
    dplyr::mutate(
      year_code = purrr::pmap(
        list(reference_code_range, model_code, make_code),
        get_table_year
      )
    ) %>%
    dplyr::filter(!purrr::map_lgl(year_code, is.null)) %>%
    tidyr::unnest() %>%
    dplyr::distinct(model_code, make_code, year_code, year)

  if (is.null(year_filter)) {

    return(table_year)

  } else {

    table_year %>%
      dplyr::filter(year %in% year_filter) %>%
      return()

  }
}


# consulta o valor do modelo
#
get_price <- function(reference_code, make_code, model_code, year_code) {

  ano <- as.character(stringr::str_split(year_code, "-", simplify = TRUE)[1, 1])
  combustivel <- as.integer(stringr::str_split(year_code, "-", simplify = TRUE)[1, 2])

  content <- httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarValorComTodosParametros",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTabelaReferencia = reference_code,
      codigoMarca = make_code,
      codigoModelo = model_code,
      codigoTipoVeiculo = 1,
      anoModelo = ano,
      codigoTipoCombustivel = combustivel,
      tipoVeiculo = "carro",
      modeloCodigoExterno = "",
      tipoConsulta = "tradicional"
    )
  ) %>%
    httr::content() %>%
    tibble::as_tibble()

  if (content[[2]] == "nadaencontrado") return(NULL)

  content %>%
    dplyr::mutate(
      MesReferencia = lubridate::dmy(paste0("01 ", MesReferencia)),
      AnoModelo = ifelse(AnoModelo == "32000", 0L, as.integer(AnoModelo)),
      Valor = readr::parse_number(Valor, locale = readr::locale(decimal_mark = ","))
    ) %>%
    dplyr::select(
      fipe_code = CodigoFipe,
      date = MesReferencia,
      make = Marca,
      model = Modelo,
      year = AnoModelo,
      #gas = Combustivel,
      price = Valor
    )
}

check_date <- function(x) {

  if (!lubridate::is.Date(x)) {

    test1 <- tryCatch(lubridate::dmy(x), warning=function(w) w)

    if (!any((class(test1) == "warning") == TRUE)) {

      return(test1)

    } else {

      test2 <- tryCatch(lubridate::ymd(x), warning=function(w) w)

      if (lubridate::is.Date(test2)) {

        return(test2)

      } else {

        stop("All formats failed to parse to date. No formats found.")

      }
    }
  }

  x
}
