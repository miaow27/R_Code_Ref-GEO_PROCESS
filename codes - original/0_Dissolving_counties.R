rm(list = ls())
setwd("~/Desktop/NYH-DOH/Products/14. Transportation/")

require(sf)
require(leaflet)
require(tidyverse)

# nys shape file 
nys_shape <- st_read(
  dsn = "3. R map production/data/cugir-007865/",
  layer = "cty036"
)

leaflet(nys_shape) %>% addPolygons() # checking


# get the nyc part only 
nyc_shape <- nys_shape %>% filter(NAME %in% c("Bronx", "Queens", "Kings", "New York", "Richmond")) %>% 
  distinct(NAME, COUNTY, geometry)

leaflet(nyc_shape) %>% addPolygons() # checking 


# dissolve nyc 
nyc_shape_dissolved <- st_union(nyc_shape) %>% 
  st_sf() %>% 
  cbind(NAME = "New York City", COUNTY = "061")

leaflet(nyc_shape_dissolved) %>% addPolygons() # checking


# get the sufflok part only 
li_shape <- nys_shape %>% filter(NAME == "Suffolk") %>% 
  distinct(NAME, COUNTY, geometry)

leaflet(li_shape) %>% addPolygons() # checking 


# dissolve suffolk (3 rows originally)
li_shape_dissolved <- st_union(li_shape) %>% 
  st_sf() %>% 
  cbind(NAME = "Suffolk", COUNTY = "103")

leaflet(li_shape_dissolved) %>% addPolygons() # checking
  

# get the sufflok part only (2 rows originally)
wc_shape <- nys_shape %>% filter(NAME == "Westchester") %>% 
  distinct(NAME, COUNTY, geometry)

leaflet(wc_shape) %>% addPolygons() # checking 


# dissolve suffolk
wc_shape_dissolved <- st_union(wc_shape) %>% 
  st_sf() %>% 
  cbind(NAME = "Westchester", COUNTY = "119")

leaflet(wc_shape_dissolved) %>% addPolygons() # checking


# get the rest of state part 
ros_shape <- nys_shape %>% 
  filter(!NAME %in% c("Bronx", "Queens", "Kings", "New York", "Richmond", "Suffolk", "Westchester")) %>% 
  distinct(NAME, COUNTY, geometry)
leaflet(ros_shape) %>% addPolygons() # checking 


# union with ros 
nys_dissolved <- rbind(st_sf(ros_shape), 
                       st_sf(nyc_shape_dissolved),
                       st_sf(li_shape_dissolved),
                       st_sf(wc_shape_dissolved))
leaflet(nys_dissolved) %>% addPolygons() # checking


# attach dissolbed nys map with mbr_county_cd
county_fips_cw <- read.csv("3. R map production/data/NYS_Medicaid_County_Code_Crosswalk.csv") %>% 
  select(MBR_COUNTY_CD, FIPS_COUNTY_CODE) %>% 
  transmute(
    mbr_county_cd = MBR_COUNTY_CD,
    fips_county_cd = str_pad(FIPS_COUNTY_CODE, 3, pad = "0"))
  

# merge with fips_cw to get mbr_county_cd
nys_dissolved_county_cd <- nys_dissolved %>% 
  mutate(COUNTY = as.character(COUNTY)) %>% 
  left_join(county_fips_cw, by = c("COUNTY" = "fips_county_cd"))

# cln space 
rm(nys_shape,
   nyc_shape,
   nyc_shape_dissolved,
   ros_shape,
   nys_dissolved,
   county_fips_cw, 
   li_shape,
   li_shape_dissolved,
   wc_shape,
   wc_shape_dissolved)

# write out result
# st_write(nys_dissolved_county_cd,
#          dsn = "3. R eda & exercise/data/geo_process_R/nys_dissolved_county_cd.shp", 
#          layer = "nys_dissolved_county_cd")



