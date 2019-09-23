setwd("~/Desktop/NYH-DOH/Products/14. Transportation/")

# Geo-prep
source("3. R map production/code/0_Dissolving_counties.R")

# Data-prep
source("3. R map production/code/1_Data_prep.R")


# plot new york state polygon  --------------------------------------------

leaflet(nys_dissolved_county_cd) %>% 
  addProviderTiles(providers$Hydda.RoadsAndLabels) %>% 
  addPolygons()


# merge with data  --------------------------------------------------------

dt_poly <- dt %>% 
  left_join(nys_dissolved_county_cd, by = "mbr_county_cd") %>% 
  st_sf() # turn back to st_sf


# plot methadone cost per mbr  --------------------------------------------

# color 
hist(dt_poly$total_cost_methadone/dt_poly$n_mbr_methadone)
quantile(dt_poly$total_cost_methadone/dt_poly$n_mbr_methadone, seq(0.2, 1, 0.2), na.rm = TRUE) %>% round()

pal <- colorBin("Blues", 
                domain = dt_poly$total_cost_methadone/dt_poly$n_mbr_methadone, 
                bins = c(0, 80, 150, 300, 500, 1050))

# title 
title <- htmltools::HTML("<big><strong>Methadone Treatment Cost per Member in 2018</strong></big>")

# caption 
caption <- htmltools::HTML("<small><strong>Notes:</strong/><br/><small>(1). Member county is the county of fiscal responsibility.<br/>(2). Methadone Treatment is identified through proc code in (W0144, W0145, S0109, HZ81ZZZ, 80358, H0020, W0143, HZ91ZZZ, J1230, W0098) or rate code in (1671, 2973).</small></small>")


# label
labels <- sprintf(
  "<strong>%s</strong><br/>$%g per member<br/>%g members<br/>$%g total cost",
  dt_poly$NAME, 
  round(dt_poly$total_cost_methadone/dt_poly$n_mbr_methadone),
  dt_poly$n_mbr_methadone,
  round(dt_poly$total_cost_methadone)
) %>% lapply(htmltools::HTML)

# plot on leaflet
m1 <- leaflet() %>% 
  addProviderTiles(providers$Hydda.RoadsAndLabels) %>% 
  addPolygons(
    data = dt_poly,
    fillColor = ~pal(total_cost_methadone/n_mbr_methadone), 
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
    # labels
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "15px",
      direction = "auto")
  ) %>% 
  # add legend 
  addLegend(data = dt_poly,
            title = "Methadone Treatment Cost per member",
            pal = pal,
            values = ~(total_cost_methadone/n_mbr_methadone), 
            opacity = 0.7, 
            labFormat = labelFormat(prefix = "$"),
            position = "bottomright") %>% 
  # add back the opoid treatment 
  addMarkers(data = opioid_add,
             ~longitude, 
             ~latitude, 
             popup = ~sprintf(
               "<strong>Provider: </strong> %s<br/><strong>Program: </strong> %s",
               opioid_add$PROVIDER_NAME, 
               opioid_add$PROGRAM_NAME
             )) %>% 
  # add Title 
  addControl(html = title, position = "topright") %>% 
  # add caption 
  addControl(html = caption, position = "bottomleft") %>% 
  # remove leaflet ink 
  htmlwidgets::onRender("var map = L.map('map', { attributionControl:false });")

setwd("3. R map production/result/")
mapview::mapshot(m1, url = "methadone_cost_map_v1.html")



