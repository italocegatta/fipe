## ------------------------------------------------------------------------
library(tidyverse)
library(stringr)
library(forcats)
library(fipe)

## ------------------------------------------------------------------------
consulta <- fipe_modelo(cod_ref = 215, cod_marca = 23) %>% 
  filter(str_detect(modelo, "ONIX")) %>%
  mutate(tem = map(cod_modelo, ~fipe_ano(215, 23, .x))) %>% 
  unnest() %>% 
  mutate(temp = pmap(list(215, 23, cod_modelo, cod_ano), fipe)) %>% 
  select(temp) %>% 
  unnest() %>% 
  mutate(ano = fct_relevel(ano, "0 km", after = Inf))

consulta

## ------------------------------------------------------------------------
ggplot(consulta, aes(valor, modelo, color = ano)) +
  geom_point(size = 3) +
  scale_color_viridis_d(direction = -1) +    
  theme_bw()

