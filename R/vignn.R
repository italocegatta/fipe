library(magrittr)
library(tidyverse)
library(stringr)

p1 <- fipe_referencia() %>%
  filter(data_ref >= "2017-01-01") %>%
  mutate(marca = map(cod_ref, fipe_marca)) %>%
  unnest()

p2 <- p1 %>%
  filter(marca == "Toyota") %>%
  mutate(modelo = map2(cod_ref, cod_marca, fipe_modelo)) %>%
  unnest()

p3 <- p2 %>%
  filter(str_detect(modelo, "(ETIOS X)")) %>%
  filter(!str_detect(modelo, "Sedan"))

p4 <- p3 %>%
  mutate(ano = pmap(list(cod_ref, cod_marca, cod_modelo), fipe_ano)) %>%
  unnest()

consulta <- p4 %>%
  mutate(consulta = pmap(list(cod_ref, cod_marca, cod_modelo, cod_ano), fipe)) %>%
  select(consulta) %>%
  unnest()

consulta %>%
  ggplot(aes(ref, valor, fill = factor(ano), color =  factor(ano), group = ano)) +
    geom_line() +
    geom_point(shape = 21, size = 4, color = "gray80") +
    facet_wrap(~modelo) +
    labs(
      x = "Mês de refêrencia",
      y = "Valor",
      fill = "Ano",
      color = "Ano"
    ) +
    scale_y_continuous(labels = scales::dollar_format(prefix = "R$ ", big.mark = ".")) +
    scale_x_date(date_labels = "%m/%y") +
    scale_fill_brewer(palette = "Spectral") +
    scale_color_brewer(palette = "Spectral") +
    theme_bw(22) +
    theme(legend.position = "top") +
    ggsave("teste.png", width = 26, height = 12)
