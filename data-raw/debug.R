library(magrittr)

# date = c("2019-01-01", "2018-01-01", "2017-01-01")
date = Sys.Date()
# make = c("toYota", "ford")
make = "toyota"
# model = c("Etios", "Ka")
model = "etios"
# year_filter = c(2018, 0)
# year = c(2018, 0)
year = NULL
.progress = TRUE

fipe_vehicle(model = "etios", make = "toyota")
fipe_vehicle(model = "etios", make = "toyota", year = c(2018))
fipe_vehicle(model = "etios", make = "toyota", year = c(2018, 0), date = "2018-05-01")
fipe_vehicle(model = "etios", make = "toyota", year = c(2018, 0), date = c("2018-05-01", "2018-06-01"))
fipe_vehicle(model = "etios", make = "toyota", date = c("2018-05-01", "2018-06-01"))

fipe_vehicle(model = c("Etios", "Ka"), make = c("toYota", "ford"))
fipe_vehicle(model = c("Etios", "Ka"), make = c("toYota", "ford"), year = c(2018))
fipe_vehicle(model = c("Etios", "Ka"), make = c("toYota", "ford"), year = c(2018, 0), date = "2018-05-01")
fipe_vehicle(model = c("Etios", "Ka"), make = c("toYota", "ford"), year = c(2018, 0), date = c("2018-05-01", "2018-06-01"))
fipe_vehicle(model = c("Etios", "Ka"), make = c("toYota", "ford"), date = c("2018-05-01", "2018-06-01"), .progress = T)

fipe_vehicle(model = "KA 1.0", make = "ford", year = c(2018, 0), date = "2018-05-01")


