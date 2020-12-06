# Data pull
# API Details ----
# API - https://www.eia.gov
# API call - http://api.eia.gov/series/?api_key=YOUR_API_KEY_HERE&series_id=SERIES_ID
# Parameters ----
`%>%` <- magrittr::`%>%`
api_key <- Sys.getenv("eia_key")
category_details <- tsAPI::eia_query(api_key = api_key,category_id = 480585)
series_details <- category_details$category$childseries
series_details$f
monthly <- series_details$series_id[which(series_details$f == "M")]
monthly


us_res_gas <- lapply(1:length(monthly), function(i){
  id <- monthly[i]
  series_name <- series_details$name[which(series_details$series_id == id)]
  state <- substr(series_name, 1, regexpr("Natural Gas", text = series_name) - 2)
  url <- paste("curl --location --request GET 'http://api.eia.gov/series/?api_key=",
               api_key,
               "&series_id=",
               id,
               "' | jq -r '.series[].data[] | [.[0], .[1]] | @tsv'",
               sep = "")

  df <- data.table::fread(cmd = url,
                          na.strings= NULL,
                          col.names = c("date", "y"))  %>%
    as.data.frame %>%
    dplyr::mutate(date = lubridate::ymd(paste(date, "01", sep = ""))) %>%
    dplyr::mutate(state = state) %>%
    dplyr::select(date, state, y)

}) %>%
  dplyr::bind_rows()

usethis::use_data(us_res_gas, overwrite = TRUE)
