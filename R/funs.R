# consulta o mes de referencia dos precos disponibilizados e retorna o codigo correspondente
#
pega_referencia <-  function(data) {

  data_mes <- lubridate::floor_date(confere_data(data), "month")

  httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarTabelaDeReferencia",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/")
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  dplyr::mutate(data_ref = lubridate::dmy(paste0("01/", Mes))) %>%
  dplyr::select(data_ref, cod_ref = Codigo) %>%
  dplyr::filter(data_ref %in% data_mes) %>%
  dplyr::pull(cod_ref)
}


# retira caracteres especiais e simflifica a grafica para facilitar o match dos nomes
#
limpa_nome <- function(x) {
  x %>%
    stringr::str_to_lower() %>%
     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT')
}


# consulta as marcas disponiveis para um determinado mes de referencia e retorna o codigo correspondente
#
pega_marca <- function(marca = NULL, cod_ref) {

  tab_marca <- httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarMarcas",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTabelaReferencia = cod_ref,
      codigoTipoVeiculo = 1
    )
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  dplyr::rename(nome_marca = Label, cod_marca = Value) %>%
  dplyr::mutate(cod_marca = as.integer(cod_marca))

  if (is.null(marca)) {

    tab_marca %>%
      dplyr::pull(cod_marca) %>%
      return()
  } else {

    tab_marca %>%
      dplyr::filter(limpa_nome(nome_marca) %in% limpa_nome(marca)) %>%
      dplyr::pull(cod_marca) %>%
      return()
  }
}


# consulta os modelos disponiveis para um determinado mes de referencia e marca e retorna o codigo correspondente
#
pega_modelo <- function(modelo, marca = NULL, cod_ref) {

  cod_ref_max <- cod_ref[which.max(cod_ref)]

  cod_marca <- pega_marca(marca, cod_ref_max)

  modelos <- paste0(stringr::str_to_lower(modelo), collapse = "|")

  purrr::map_dfr(
    cod_marca,
    ~httr::POST(
      "http://veiculos.fipe.org.br/api/veiculos/ConsultarModelos",
      httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
      body = list(
        codigoTipoVeiculo = 1,
        codigoTabelaReferencia = cod_ref_max,
        codigoMarca = .x
      )
    ) %>%
    httr::content("text", encoding = "UTF-8") %>%
    jsonlite::fromJSON() %>%
    '[['(1) %>%
    tibble::rownames_to_column() %>%
    dplyr::select(nome_modelo = Label, cod_modelo = Value) %>%
    dplyr::mutate(
      cod_marca = .x,
      nome_modelo = limpa_nome(nome_modelo)
    ) %>%
    tibble::as_tibble()
  ) %>%
  dplyr::filter(stringr::str_detect(nome_modelo, modelos))
}


# extrai tabela com os anos disponíveis de cada modelo
#
pega_tab_ano <- function(cod_ref, cod_modelo, cod_marca) {

  content <- httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarAnoModelo",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTipoVeiculo = 1,
      codigoTabelaReferencia = cod_ref,
      codigoModelo = cod_modelo,
      codigoMarca = cod_marca
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
    dplyr::select(ano, cod_ano = Value) %>%
    tibble::as_tibble()
}


# consulta o ano do modelo disponivel para um determinado mes de referencia, marca e modelo
#
pega_ano <- function(modelo, marca = NULL, ano_filter = NULL, cod_ref) {

  #cod_ref_max <- cod_ref[which.max(cod_ref)]

  cod_modelo <- pega_modelo(modelo, marca, cod_ref)

  if (nrow(cod_modelo) == 0) stop("Modelo nao encontrado", call. = FALSE)

  tab_ano <- cod_modelo %>%
    tidyr::crossing(., cod_ref_range = range(cod_ref)) %>%
    dplyr::mutate(
      cod_ano = purrr::pmap(
        list(cod_ref_range, cod_modelo, cod_marca),
        pega_tab_ano
      )
    ) %>%
    dplyr::filter(!purrr::map_lgl(cod_ano, is.null)) %>%
    tidyr::unnest() %>%
    dplyr::distinct(cod_modelo, cod_marca, cod_ano, ano)

  if (is.null(ano_filter)) {

    return(tab_ano)

  } else {

    tab_ano %>%
      dplyr::filter(ano %in% ano_filter) %>%
      return()

  }
}


# consulta o valor do modelo
#
pega_valor <- function(cod_ref, cod_marca, cod_modelo, cod_ano) {

  ano <- as.character(stringr::str_split(cod_ano, "-", simplify = TRUE)[1, 1])
  combustivel <- as.integer(stringr::str_split(cod_ano, "-", simplify = TRUE)[1, 2])

  content <- httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarValorComTodosParametros",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTabelaReferencia = cod_ref,
      codigoMarca = cod_marca,
      codigoModelo = cod_modelo,
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
      cod_fipe = CodigoFipe,
      data_referencia = MesReferencia,
      marca = Marca,
      modelo = Modelo,
      ano = AnoModelo,
      combustivel = Combustivel,
      valor = Valor
    )
}

confere_data <- function(x) {

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
