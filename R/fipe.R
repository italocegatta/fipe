#' Access to the Fipe Database
#'
#' @param model a character vector. Vehicle model name.
#' @param make a character vector. If NULL, search all models in all makes,
#'   otherwise only those indicated.
#' @param year a numeric vector. Year of manufacture of the vehicle. If 0
#'   returns vehicles 0 km.
#' @param date a date vector. Reference date for the vehicle price.
#' @param progress a logical, if TRUE print a progress bar.
#' @param parallel a logical, if TRUE apply function in parallel.
#'
#' @return A data frame/tibble including model, make, year, date and price.
#'
#' @details The Fipe Database shows the average purchase price of vehicles in
#'   the Brazilian national market. The prices are effectively used in purchase
#'   negotiations according to region, vehicle’s conservation, color,
#'   accessories or any other factor that might influence the demand and supply
#'   for a specific vehicle. The year of the vehicle refers to the model year,
#'   and the vehicles are not considered for professional or special use. The
#'   values are expressed in R$ (reais) for each month/year of reference.
#'
#' @seealso Official Website \url{https://veiculos.fipe.org.br}.
#'
#' @examples
#' \donttest{
#' fipe_vehicle(
#'   model = "etios platinum", make = "toyota",
#'   date = "2019-08-01", year = c(0, 2019, 2018)
#' )
#'}
#'
#' @export
#'
fipe_vehicle <- function(model, make = NULL, year = NULL,
                         date = Sys.Date(), progress = FALSE,
                         parallel = FALSE) {

  reference_code <- get_reference(date)

  base_cod_ano <- get_year(model, make, year, reference_code)

  if (parallel) {
    future::plan(future::multiprocess)
  } else {
    future::plan(future::sequential)
  }

  base_cod_ano %>%
    tidyr::crossing(., reference_code) %>%
    dplyr::mutate(
      price = furrr::future_pmap(
        list(reference_code, make_code, model_code, year_code),
        get_price, .progress = progress
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
