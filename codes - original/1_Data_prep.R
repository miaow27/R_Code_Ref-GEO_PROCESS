
# 0. Data Prep ------------------------------------------------------------

dt1 <- read.csv("1. raw extract (data & code)/Extract 2019 07 31/denominator_SUB.txt", sep = "\t") %>% 
  transmute(SUD_pop = count, 
            mbr_county_cd)

dt2 <- read.csv("1. raw extract (data & code)/Extract 2019 07 31/methadone_2018_summary.txt", sep = "\t") %>% 
  select(-year) %>% 
  mutate(county_name = county_name %>% 
           map_chr(~str_replace(.x, "( COUNTY DSS)|(Office of Mental Health)|(DDS)|(Revenue Support Field Operations)", "") %>% tolower))

# dt2$county_name %<>% 
#   str_replace(., " COUNTY DSS", "") %>% 
#   str_replace(., "Office of Mental Health", "") %>% 
#   str_replace(., "DDS", "") %>% 
#   str_replace(., "Revenue Support Field Operations", "")

dt3 <- read.csv("1. raw extract (data & code)/Extract 2019 07 31/miles_per_mbr_2018_summary.txt", sep = "\t") %>% 
  select(-YEAR, -county_name)

# join all info (58)
dt <- dt1 %>% 
  left_join(dt2, by = "mbr_county_cd") %>% 
  left_join(dt3, by = "mbr_county_cd") %>% 
  filter(county_name != "")

opioid_add <- read.csv("3. R map production/data/Methadone_Facilities_Geocoded.txt", sep = "\t")

rm(dt1, dt2, dt3)
