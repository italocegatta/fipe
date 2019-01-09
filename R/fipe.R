#' Consulta o valor do carro disponiveis na Tabela FIPE
#'
#' @param modelo vetor de caracteres. Nome de um ou mais carros que se deseja consultar.
#' @param marca vetor de caracteres. Se NULL, consulta em todas o modelo em todas as marcas, do contrario apenas nas indicadas.
#' @param ano vetor numerico. Indica um ou mais anos de fabricacao a serem consultados. Valor 0 indica carro 0 km.
#' @param data_referencia vetor de datas. Indica a data de referencia que o valor carro foi consultado.
#'
#' @return Um tibble com resultado da consulta.
#'
#' @examples
#' fipe_carro("etios", "toyota", c(2018, 0), c("2019-01-01", "2018-01-01", "2017-01-01"))
#'
#' @export
#'
fipe_carro_p <- function(modelo, marca = NULL, ano = NULL, data_referencia = Sys.Date()) {

  cod_ref <- pega_referencia(data_referencia)

  cod_ano <- pega_ano(modelo, marca, ano, cod_ref)

  future::plan(future::multiprocess)

  cod_ano %>%
    dplyr::select(cod_modelo, cod_marca, cod_ano) %>%
    tidyr::crossing(., cod_ref) %>%
    dplyr::mutate(
      valor = furrr::future_pmap(
        list(cod_ref, cod_marca, cod_modelo, cod_ano),
        pega_valor
      )
    ) %>%
    dplyr::select(valor) %>%
    tidyr::unnest() %>%
    dplyr::mutate(
      ano = ifelse(ano == 0L, "0 km", as.character(ano)),
      ano = suppressWarnings(forcats::fct_relevel(ano, "0 km"))
    ) %>%
    dplyr::select(
      modelo, marca, ano, data_referencia, valor
    )
}
