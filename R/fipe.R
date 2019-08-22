#' Access to the Fipe Database
#'
#' @param model a character vector. Vehicle model name.
#' @param make a character vector. If NULL, search all models in all makes, otherwise only those indicated.
#' @param year a numeric vector. Year of manufacture of the vehicle. If 0 returns vehicles 0 km.
#' @param date a date vector. Reference date for the vehicle price.
#' @param progress a logical, if TRUE print a progress bar.
#' @param parallel a logical, if TRUE apply function in parallel.
#'
#' @return A data frame/tibble including model, make, year, date and price.
#'
#' @details The Fipe Database shows average prices of vehicles on the national
#'   market, functioning only as a parameter for negotiations and evaluations.
#'   The prices effectively used in negotiations vary according to region,
#'   vehicle's conservation, color, accessories or any other factor that might
#'   influence the conditions of demand and supply for a specific vehicle.
#'   The year of the vehicle refers to the year of the model and are not
#'   considered vehicles for professional or special use. The values are
#'   expressed in R$ (reais) of the month/year of reference.
#'
#' @examples
#' fipe_vehicle(model = "etios platinum", make = "toyota", date = Sys.Date(), year = c(0, 2019, 2018))
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
