
# Pacotes -----------------------------------------------------------------


library(httr)
library(jsonlite)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)
library(readr)
library(ggplot2)


# Funcoes -----------------------------------------------------------------

base <- "https://fipe-parallelum.rhcloud.com/api/v1/carros/marcas"

fipe_marcas <-  function(){
  GET(base) %>% 
    content("text", encoding = "UTF-8") %>% 
    fromJSON() %>% 
    as_tibble()
}

fipe_modelos <- function(cod_marca) {
  GET(paste(base, cod_marca, "modelos", sep = "/")) %>% 
    content("text", encoding = "UTF-8") %>% 
    fromJSON() %>% 
    '[['(1) %>% 
    as_tibble() 
}

fipe_anos <- function(cod_marca, cod_carro) {
  GET(paste(base, cod_marca, "modelos", cod_carro, "anos", sep = "/")) %>% 
    content("text", encoding = "UTF-8") %>% 
    fromJSON() %>% 
    as_tibble() 
}

fipe <- function(cod_marca, cod_carro, cod_ano) {
  GET(paste(base, cod_marca, "modelos", cod_carro, "anos", cod_ano, sep = "/")) %>% 
    content("text", encoding = "UTF-8") %>% 
    fromJSON() %>% 
    as_tibble() 
}


# Marcas ------------------------------------------------------------------

toyota <- fipe_marcas() %>% 
  filter(nome == "Toyota") %>% 
  rename(marca = nome, cod_marca = codigo)


# Modelos -----------------------------------------------------------------

etios <- toyota %>% 
  mutate(
    modelos = map(cod_marca, fipe_modelos)
  ) %>% 
  unnest() %>% 
  filter(str_detect(nome, "ETIOS")) %>% 
  rename(modelo = nome, cod_modelo = codigo) %>% 
  filter(str_detect(modelo, "ETIOS"))


# Anos --------------------------------------------------------------------

anos <- etios %>% 
  mutate(anos = map2(cod_marca, cod_modelo, fipe_anos)) %>% 
  unnest(anos) %>% 
  rename(ano = nome, cod_ano = codigo)


# Resumo ------------------------------------------------------------------

resumo <- anos %>% 
  mutate(anos = pmap(list(cod_marca, cod_modelo, cod_ano), fipe)) %>% 
  select(anos) %>% 
  unnest() %>% 
  select(Marca, Modelo, Ano = AnoModelo, Valor) %>% 
  mutate(
    Ano = as.numeric(Ano),
    Valor = as.numeric(str_extract(Valor, "[:digit:]+.[:digit:]+")) * 1000
  )


# Gráfico -----------------------------------------------------------------

resumo %>% 
  ggplot(aes(Valor, Modelo, fill = factor(Ano))) +
  geom_point(size = 5, shape = 21, colour = "black") +
  scale_fill_brewer(palette = "Spectral") +
  scale_x_continuous(breaks = seq(20000, 80000, 2000), labels = scales::dollar) +
  theme_bw()

