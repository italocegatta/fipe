#' Data de referencia da tabela FIPE
#'
#' Consulta o mes de referencia dos precos disponibilizados
#'
#' @export
#'
fipe_referencia <-  function() {
  httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarTabelaDeReferencia",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/")
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  dplyr::mutate(data_ref = lubridate::dmy(paste0("01/", Mes))) %>%
  dplyr::select(data_ref, cod_ref = Codigo,) %>%
  dplyr::arrange(desc(data_ref)) %>%
  tibble::as_tibble()
}


#' Marcas disponiveis na tabela FIPE
#'
#' Consulta as marcas disponiveis para um determinado mes de referencia
#'
#' @export
#'
fipe_marca <- function(cod_ref = NULL) {
  if(is.null(cod_ref)) {
    x <- fipe_referencia()
    cod_ref <- x$cod_ref[1]
  }

  httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarMarcas",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTabelaReferencia = cod_ref,
      codigoTipoVeiculo = 1
    )
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  dplyr::rename(marca = Label, cod_marca = Value) %>%
  dplyr::mutate(cod_marca = as.integer(cod_marca)) %>%
  dplyr::arrange(marca) %>%
  tibble::as_tibble()
}


#' Modelos disponiveis na tabela FIPE
#'
#' Consulta os modelos disponiveis para um determinado mes de referencia e marca
#'
#' @export
#'
fipe_modelo <- function(cod_ref = NULL, cod_marca) {
  if(is.null(cod_ref)) {
    x <- fipe_referencia()
    cod_ref <- x$cod_ref[1]
  }

  httr::POST(
    "http://veiculos.fipe.org.br/api/veiculos/ConsultarModelos",
    httr::add_headers(Referer = "http://veiculos.fipe.org.br/"),
    body = list(
      codigoTipoVeiculo = 1,
      codigoTabelaReferencia = cod_ref,
      codigoMarca = cod_marca
    )
  ) %>%
  httr::content("text", encoding = "UTF-8") %>%
  jsonlite::fromJSON() %>%
  '[['(1) %>%
  tibble::rownames_to_column() %>%
  dplyr::select(modelo = Label, cod_modelo = Value) %>%
  dplyr::arrange(modelo) %>%
  tibble::as_tibble()
}


#' Anos dos modelos disponiveis na tabela FIPE
#'
#' Consulta o ano do modelo disponiveis para um determinado mes de referencia,
#' marca e modelo
#'
#' @export
#'
fipe_ano <- function(cod_ref = NULL, cod_marca, cod_modelo) {
  if(is.null(cod_ref)) {
    x <- fipe_referencia()
    cod_ref <- x$cod_ref[1]
  }

  httr::POST(
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
  jsonlite::fromJSON() %>%
  tidyr::separate(Label, c("ano", "combustivel")) %>%
  dplyr::mutate(
    ano = ifelse(ano == "32000", "0 km", as.character(ano))
  ) %>%
  dplyr::select(ano, cod_ano = Value) %>%
  tibble::as_tibble()
}

#' Consulta o valor do carro na tabela FIPE
#'
#' Consulta o valor do carro a partir dos parametros necessarios para a
#' caracterizacao completa do modelo
#'
#' @export
#'
fipe <- function(cod_ref = NULL, cod_marca, cod_modelo, cod_ano) {
  if(is.null(cod_ref)) {
    x <- fipe_referencia()
    cod_ref <- x$cod_ref[1]
  }

  ano <- as.character(stringr::str_split(cod_ano, "-", simplify = TRUE)[1, 1])
  combustivel <- as.integer(stringr::str_split(cod_ano, "-", simplify = TRUE)[1, 2])

  httr::POST(
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
  tibble::as_tibble() %>%
  dplyr::mutate(
    MesReferencia = lubridate::dmy(paste0("01 ", MesReferencia)),
    AnoModelo = ifelse(AnoModelo == 32000, "0 km", as.character(AnoModelo)),
    Valor = readr::parse_number(Valor, locale = readr::locale(decimal_mark = ","))
  ) %>%
  dplyr::select(
    cod_fipe = CodigoFipe,
    ref = MesReferencia,
    marca = Marca,
    modelo = Modelo,
    ano = AnoModelo,
    combustivel = Combustivel,
    valor = Valor
  )
}
