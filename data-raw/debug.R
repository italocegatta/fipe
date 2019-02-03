library(magrittr)

data_referencia = c("2019-01-01", "2018-01-01", "2017-01-01")
data_referencia = Sys.Date()
marca = c("toYota", "ford")
marca = "toyota"
modelo = c("Etios", "Ka")
modelo = "etios"
#ano_filter = c(2018, 0)
ano = c(2018, 0)
ano = NULL
.progress = TRUE

fipe_carro(modelo = "etios", marca = "toyota")
fipe_carro(modelo = "etios", marca = "toyota", ano = c(2018))
fipe_carro(modelo = "etios", marca = "toyota", ano = c(2018, 0), data_referencia = "2018-05-01")
fipe_carro(modelo = "etios", marca = "toyota", ano = c(2018, 0), data_referencia = c("2018-05-01", "2018-06-01"))
fipe_carro(modelo = "etios", marca = "toyota", data_referencia = c("2018-05-01", "2018-06-01"))

fipe_carro(modelo = c("Etios", "Ka"), marca = c("toYota", "ford"))
fipe_carro(modelo = c("Etios", "Ka"), marca = c("toYota", "ford"), ano = c(2018))
fipe_carro(modelo = c("Etios", "Ka"), marca = c("toYota", "ford"), ano = c(2018, 0), data_referencia = "2018-05-01")
fipe_carro(modelo = c("Etios", "Ka"), marca = c("toYota", "ford"), ano = c(2018, 0), data_referencia = c("2018-05-01", "2018-06-01"))
fipe_carro(modelo = c("Etios", "Ka"), marca = c("toYota", "ford"), data_referencia = c("2018-05-01", "2018-06-01"))

fipe_carro(modelo = "KA 1.0", marca = "ford", ano = c(2018, 0), data_referencia = "2018-05-01")

fipe_carro(
  modelo = "zzz",
  marca = "bmw",
  ano = 0,
  data_referencia = seq.Date(as.Date("2009-01-01"), as.Date("2017-12-01"), by = "4 months")
) %>% View()

# bug não pega valor o km do x6 407cv

modelo = "zz"
marca = "bmw"
ano = 0
data_referencia = seq.Date(as.Date("2009-01-01"), as.Date("2017-12-01"), by = "4 months")
.progress = FALSE

cod_ref = 47; cod_modelo = 5189; cod_marca = 7
cod_ref = 217; cod_modelo = 5189; cod_marca = 7

for (i in 1:8) {
  cod_modelo %>%
    tidyr::crossing(., cod_ref_range = range(cod_ref)) %>%
    dplyr::slice(2) %>%
    dplyr::mutate(
      cod_ano = purrr::pmap(
        list(cod_ref_range, cod_modelo, cod_marca),
        pega_tab_ano
      )
    )
}
cod_modelo %>%
  tidyr::crossing(., cod_ref_range = range(cod_ref)) %>%
  dplyr::mutate(
    cod_ano = purrr::pmap(
      list(cod_ref_range, cod_modelo, cod_marca),
      pega_tab_ano
    )
  )
