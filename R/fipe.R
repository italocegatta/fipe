#' Consulta o price do carro disponiveis na Tabela FIPE
#'
#' @param model vetor de caracteres. Nome de um ou mais carros que se deseja consultar.
#' @param make vetor de caracteres. Se NULL, consulta em todas o modelo em todas as marcas, do contrario apenas nas indicadas.
#' @param year vetor numerico. Indica um ou mais anos de fabricacao a serem consultados. price 0 indica carro 0 km.
#' @param date vetor de datas. Indica a data de referencia que o price carro foi consultado.
#' @param .progress a logical, for whether or not to print a progress bar.
#'
#' @return Um tibble com resultado da consulta.
#'
#' @examples
#' fipe_vehicle(model = "etios", make = "toyota", year = 0)
#'
#' @export
#'
fipe_vehicle <- function(model, make = NULL, year = NULL, date = Sys.Date(), .progress = FALSE) {

  reference_code <- get_reference(date)

  base_cod_ano <- get_year(model, make, year, reference_code)

  future::plan(future::multiprocess)

  base_cod_ano %>%
    tidyr::crossing(., reference_code) %>%
    dplyr::mutate(
      price = furrr::future_pmap(
        list(reference_code, make_code, model_code, year_code),
        get_price, .progress = .progress
      )
    ) %>%
    dplyr::filter(!purrr::map_lgl(price, is.null)) %>%
    dplyr::select(price) %>%
    tidyr::unnest() %>%
    dplyr::mutate(
      year = ifelse(year == 0L, "0 km", as.character(year)),
      year = suppressWarnings(forcats::fct_relevel(year, "0 km", after = Inf))
    ) %>%
    dplyr::select(
      model, make, year, date, price
    )
}
