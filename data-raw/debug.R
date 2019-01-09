library(magrittr)

data_referencia = c("2019-01-01", "2018-01-01", "2017-01-01")
marca = c("toYota", "ford")
modelo = c("Etios", "Ka")
ano_filter = c(2018, 0)
ano = c(2018, 0)
ano = NULL

fipe_carro(modelo = "etios", marca = "toyota")
fipe_carro(modelo = "etios", marca = "toyota", ano = c(2018, 0))
fipe_carro(modelo = "etios", marca = "toyota", ano = c(2018, 0), data_referencia = "2018-05-01")
fipe_carro(modelo = "etios", marca = "toyota", ano = c(2018, 0), data_referencia = c("2018-05-01", "2018-06-01"))
fipe_carro(modelo = "etios", marca = "toyota", data_referencia = c("2018-05-01", "2018-06-01"))

cod_ref = 202
cod_marca = 22
cod_modelo = 4514
cod_ano = "2013-1"

b <- bench::mark(
  iterations = 10,
  seq = fipe_carro(modelo = "etios", marca = "toyota", data_referencia = c("2018-05-01", "2018-06-01")),
  par = fipe_carro_p(modelo = "etios", marca = "toyota", data_referencia = c("2018-05-01", "2018-06-01"))
)

ggplot2::autoplot(b)
