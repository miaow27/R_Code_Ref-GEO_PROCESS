
# Geo-prep
source("3. R map production/code/0_Dissolving_counties.R")

# Data-prep
source("3. R map production/code/1_Data_prep.R")


# SELECT *
#   FROM (
#     SELECT BILL_PROV_ID,
#     CLAIMS.LOC_OF_SRV,
#     BILL_PROV_TYPE_CD,
#     COS_CD, 
#     PROV_ADDR_STR,
#     COUNT(BILL_PROV_ID) AS N,
#     year(SRV_DT) AS YEAR,
#     GEO_CD_LAT,
#     GEO_CD_LONG
#     FROM medicaid.CLAIM_TRANS AS CLAIMS
#     LEFT JOIN medicaid.PROV_LOC_ADDR AS LOC
#     ON BILL_PROV_ID = PROV_ID AND CLAIMS.LOC_OF_SRV = LOC.LOC_OF_SRV
#     WHERE year(SRV_DT) between 2016 and 2018
#     AND PROC_CD_1 IN ('W0144', 'W0145', 'S0109', 'HZ81ZZZ', '80358', 'H0020', 'W0143', 'HZ91ZZZ', 'J1230', 'W0098')
#     GROUP BY 1, 2, 3, 4, PROV_ADDR_STR, YEAR, GEO_CD_LAT, GEO_CD_LONG
#   ) AS X
# WHERE N > 10
# ORDER BY N



setwd("~/Desktop/NYH-DOH/Products/14. Transportation")

dt <- read.csv("1. raw extract (data & code)/Extract 2019 07 09/data/TRANSPORTATION_LOC_OF_SERVICE.txt",
               sep = "\t")

dt %>% filter(YEAR == 2018) %>% distinct(BILL_PROV_ID) %>% nrow()
dt %>% filter(YEAR == 2018) %>% filter(!is.na(GEO_CD_LAT)) %>% distinct(GEO_CD_LAT, GEO_CD_LONG) %>% nrow()
# some missing, not that bad 
# lets draw on the map to see the locations

# get the non-blank spot (2016 - 2018)
emperical_clinic <- dt %>% 
  filter(!is.na(GEO_CD_LAT)) %>% 
  distinct(GEO_CD_LAT, GEO_CD_LONG) %>% 
  mutate(seq = 1:n())

# merge with opiod offical locations (give some distance)
complete_list <- emperical_clinic %>% 
  fuzzyjoin::geo_full_join(opioid_add, 
                                by = c("GEO_CD_LAT" = "latitude", 
                                       "GEO_CD_LONG" = "longitude"),
                               max_dist = 0.1) %>% 
  mutate(
    source = case_when(
      !is.na(seq) & is.na(PROVIDER_NAME) ~ "claims (only)",
      is.na(seq) & !is.na(PROVIDER_NAME) ~ "oasas (only)",
      !is.na(seq) & !is.na(PROVIDER_NAME) ~ "both available",
      TRUE ~ "should not happen"),
    icon_col = case_when(
      source == "claims (only)" ~ "blue",
      source == "oasas (only)" ~ "orange",
      source == "both available" ~ "green",
      TRUE ~ "grey"
    ),
    new_lat = if_else(source == "oasas (only)", latitude, GEO_CD_LAT),
    new_lng = if_else(source == "oasas (only)", longitude, GEO_CD_LONG)
  ) %>% 
  # deduplicate
  distinct(seq, source, icon_col, new_lat, new_lng, PROVIDER_NAME, PROGRAM_NAME)


icons <- awesomeIcons(
  library = 'ion',
  markerColor = complete_list$icon_col
)

# label
labels <- sprintf(
  "<strong>%s</strong>",
  nys_dissolved_county_cd$NAME
) %>% lapply(htmltools::HTML)

library(leaflet)
m2 <- leaflet() %>% 
  addProviderTiles(providers$Hydda.RoadsAndLabels) %>% 
  # label clinic
  addAwesomeMarkers(
    data = complete_list,
    lat = ~(new_lat),
    lng = ~(new_lng),
    icon = icons,
    label = ~source,
    popup = ~sprintf(
      "<strong>Provider: </strong> %s<br/><strong>Program: </strong> %s<br/>",
      complete_list$PROVIDER_NAME,
      complete_list$PROGRAM_NAME
    )
  ) %>%
  # add state boundry
  addPolygons(
    data = nys_dissolved_county_cd,
    fillColor = "grey", 
    weight = 2, 
    opacity = 1, 
    color = "white", 
    dashArray = "3",
    fillOpacity = 0.7,
    # highlight interation
    highlight = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE),
    label = labels
  )
   

setwd("4. emperical clinic location/")
mapview::mapshot(m2, url = "emperical_methadone_clinic_loc.html")

# summary
complete_list %>% count(source)

# source             n
# both available    84
# claims (only)     51
# oasas (only)      31

