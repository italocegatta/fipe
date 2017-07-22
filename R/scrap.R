library(tidyverse)
library(httr)
library(rvest)
library(jsonlite)





# Marcas ------------------------------------------------------------------

url_marcas <- "http://veiculos.fipe.org.br/api/veiculos/ConsultarMarcas"

lista_marcas <- POST(
  url_marcas,
  add_headers(Referer = "http://veiculos.fipe.org.br/"),
  body = list(
    codigoTabelaReferencia = 215,
    codigoTipoVeiculo = 1
  )
) %>% 
  content("text", encoding = "UTF-8") %>% 
  fromJSON() %>% 
  as_tibble()

marca_interesse <- lista_marcas %>% 
  filter(Label %in% c("Toyota", "Nissan"))


# Modelos -----------------------------------------------------------------

url_marcas <- "http://veiculos.fipe.org.br/api/veiculos/ConsultarModelos"

lista_modelos <- POST(
  url_marcas,
  add_headers(Referer = "http://veiculos.fipe.org.br/"),
  body = list(
    codigoTipoVeiculo = 1,
    codigoTabelaReferencia = 215,
    codigoMarca = 56
  )
) %>% 
  content("text", encoding = "UTF-8") %>% 
  fromJSON() %>% 
  '[['(1) %>% 
  rename(modelo = Label, cod_modelo = Value) %>% 
  as_tibble() 


# Ano --------------------------------------------------------------------

url_ano_modelo <- "http://veiculos.fipe.org.br/api/veiculos/ConsultarAnoModelo"

lista_ano_modelo <- POST(
  url_ano_modelo,
  add_headers(Referer = "http://veiculos.fipe.org.br/"),
  body = list(
    codigoTipoVeiculo = 1,
    codigoTabelaReferencia = 215,
    codigoModelo = 2,
    codigoMarca = 1
  )
) %>% 
  content("text", encoding = "UTF-8") %>% 
  fromJSON() %>% 
  separate(Label, c("ano", "combustivel")) %>% 
  mutate(ano = as.integer(ano)) %>% 
  rename(cod_ano = Value) %>% 
  as_tibble()



# Full --------------------------------------------------------------------


url <- "http://veiculos.fipe.org.br/api/veiculos/ConsultarValorComTodosParametros"

request <- POST(
  url,
  encode="form",
  user_agent("Chrome/59.0.3071.115"),
  add_headers(Referer = "http://veiculos.fipe.org.br/"),
  body = list(
    codigoTabelaReferencia = 211,
    codigoMarca = 2,
    codigoModelo = 4564,
    codigoTipoVeiculo = 1,
    anoModelo = 2015,
    codigoTipoCombustivel = 3,
    tipoVeiculo = "carro",
    modeloCodigoExterno = "",
    tipoConsulta = "tradicional"
  )
) %>% 
  content() %>% 
  as_data_frame() %>% 
  select(
    ref = MesReferencia,
    marca = Marca, 
    modelo = Modelo,
    ano = AnoModelo, 
    valor = Valor
  )


request
