## we read to COVID-19 data downloaded from https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-2020-03-17.xlsx:

data_COVID_basefile <- paste0("source_data/COVID-19-geographic-disbtribution-worldwide-", today)
weblink_COVID_baselfile <- paste0("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-", today)

## download file:
tryCatch(download.file(paste0(weblink_COVID_baselfile, ".xlsx"), destfile = paste0(data_COVID_basefile, ".xlsx")), 
         error = function(e) download.file(paste0(weblink_COVID_baselfile, ".xls"), destfile = paste0(data_COVID_basefile, ".xls")))

## read file:
data_COVID_raw <- tryCatch(readxl::read_xlsx(paste0(data_COVID_basefile, ".xlsx")),
                      error = function(e) readxl::read_xls(paste0(data_COVID_basefile, ".xls")))

stopifnot(is_tibble(data_COVID_raw))
rm(data_COVID_basefile)

data_COVID_raw %>%
  rename(Country = "Countries and territories") %>%
  mutate(iso2c = case_when(GeoId %in% unique(codelist$iso2c) ~ GeoId, ## we fix the country codes
                           GeoId == "UK" ~ "GB",
                           GeoId == "XK" ~ "XK",
                           GeoId == "EL" ~ "GR",
                           TRUE ~ NA_character_),
         date = lubridate::ymd(paste(Year, Month, Day, sep = "/")),
         latest = max(date),
         date_label = paste(lubridate::month(Month, label = TRUE, abbr = FALSE), Day, sep = " ")) %>%
  group_by(Country, DateRep) %>%
  slice_max(Cases) %>% ## we remove some duplicates
  ungroup() -> data_COVID

## we create the continents:
data_COVID %>%
  mutate(continent = if_else(iso2c == "XK", ## Kosovo is not present in the list
                             "Europe",
                             countrycode(iso2c, origin = "iso2c", destination = "continent"))) -> data_COVID

## checks:
print("data_COVID countries not in WB:")

data_COVID %>%
  anti_join(data_pop) %>%
  pull(Country) %>%
  unique() %>%
  print()

rm(data_COVID_raw)