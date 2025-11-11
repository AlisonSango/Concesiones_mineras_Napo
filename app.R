library(shiny) 
library(leaflet) 
library(sf)
library(terra)
library(dplyr)
library(shinythemes)
library(ggplot2)
library(plotly)

# --- CARGAR DE DATOS ---
minas <- st_read("data/mineria_napo.geojson", quiet = TRUE)
rios  <- st_read("data/rios_napo.shp", quiet = TRUE)
snap  <- st_read("data/snap_napo.shp", quiet = TRUE)
napo  <- st_read("data/napo.shp", quiet = TRUE)
dem   <- rast("data/srtm_napo_clip.tif")

# --- UNIFICAR CRS ---
minas <- st_transform(minas, 4326)
rios  <- st_transform(rios,  4326)
snap  <- st_transform(snap,  4326)
napo  <- st_transform(napo,  4326)
dem_wgs84 <- terra::project(dem, "EPSG:4326")

# dem_wgs84 proyectado a EPSG:4326
dem_wgs84_low <- terra::aggregate(dem_wgs84, fact = 3, fun = mean)  # duplica el tamaño de celda (≈ 4x menos píxeles)

# --- usar coordenadas geográficas (4326)
minas_utm <- st_transform(minas, 32718)  # zona UTM 18S (Napo)
snap_utm  <- st_transform(snap,  32718)
rios_utm  <- st_transform(rios,  32718)

#Calcular el area de la concesión en Km2
minas$area_km2 <- round(as.numeric(st_area(minas_utm)) / 1e6, 2)

# Calcular la distancia mínima en metros
dist_matrix <- st_distance(minas_utm, snap_utm)
min_dist_m  <- apply(dist_matrix, 1, min)

# Añadir como columna al objeto minas
minas$dist_snap_m <- as.numeric(min_dist_m)
minas$dist_snap_km <- round(minas$dist_snap_m / 1000, 2)

# Índice del río más cercano para cada concesión
idx_nearest_river <- st_nearest_feature(minas_utm, rios_utm)

# Distancia (en metros) por elemento a su río más cercano
minas$dist_rio_m  <- as.numeric(st_distance(minas_utm, rios_utm[idx_nearest_river, ], by_element = TRUE))
minas$dist_rio_km <- round(minas$dist_rio_m / 1000, 2)

# --- Altitud promedio por concesión ---
# Usar DEM en 4326 y convertir minas a SpatVector
elev_tbl <- terra::extract(dem_wgs84_low, terra::vect(minas), fun = mean, na.rm = TRUE)
minas$elev_prom_m <- round(elev_tbl[[2]], 0) # La segunda columna del resultado es el valor extraído

# Estadística sobre distancias
dist_stats <- minas %>%
  summarise(
    min_km = min(dist_snap_km, na.rm = TRUE),
    max_km = max(dist_snap_km, na.rm = TRUE),
    mean_km = mean(dist_snap_km, na.rm = TRUE),
    median_km = median(dist_snap_km, na.rm = TRUE),
    sd_km = sd(dist_snap_km, na.rm = TRUE)
  )
# print(dist_stats)


ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Concesiones mineras en Napo"),
  leafletOutput("map", height = "60vh"),
  fluidRow(
    column(4, plotlyOutput("hist_snap", height = "25vh")),
    column(4, plotlyOutput("hist_rio",  height = "25vh")),
    column(4, plotlyOutput("hist_elev", height = "25vh"))
  )
)

make_hist_auto <- function(x, title, xlab, unit = "", color = "#333333", digits = 2) {
  x <- x[is.finite(x)]
  h <- hist(x, breaks = "FD", plot = FALSE)  # bins automáticos (Freedman–Diaconis)
  
  mids   <- h$mids
  counts <- h$counts
  lefts  <- h$breaks[-length(h$breaks)]
  rights <- h$breaks[-1]
  
  fmt <- function(v) format(round(v, digits), nsmall = digits, trim = TRUE)
  txt <- sprintf("Concesiones: %d<br>Rango: %s – %s %s",
                 counts, fmt(lefts), fmt(rights), unit)
  
  plotly::plot_ly(
    x = mids, y = counts, type = "bar",
    hovertext   = txt,                     # << usar hovertext
    hoverinfo   = "text",                  # << mostrar solo el hovertext
    hovertemplate = "%{hovertext}<extra></extra>",  # << tooltip limpio
    textposition = "none",                 # << NUNCA dibujar texto en barras
    marker = list(color = color, line = list(color = "white", width = 1))
  ) %>%
    plotly::layout(
      title = list(text = title, font = list(size = 13)),
      xaxis = list(title = list(text = xlab, font = list(size = 11)), zeroline = FALSE),
      yaxis = list(title = list(text = "Número de concesiones", font = list(size = 11)), zeroline = FALSE),
      bargap = 0.05
    )
}


server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() %>%
      addRasterImage(
        dem_wgs84_low,
        colors = terrain.colors(10),
        opacity = 0.7,
        group = "Elevación",
        maxBytes = 50 * 1024 * 1024
      ) %>%
      addPolygons(data = napo, color = "black", weight = 1, fill = FALSE) %>%
      addPolygons(
        data = snap, 
        color = "black", 
        group = "Áreas protegidas", 
        fillColor = "#1a9850", 
        fillOpacity = 0.4, 
        weight = 1,
        popup = ~sprintf(
          "<b>%s</b><br>
          %s<br>",
          ifelse(!is.na(Categoría), Categoría, "Sin categoría"),
          ifelse(!is.na(Nombre), Nombre, "Sin nombre")
        )
        ) %>%
      addPolygons(
        data = minas,
        color = "black",
        fillColor = "#E67E22",
        fillOpacity = 1,
        weight = 1,
        group = "Concesiones mineras",
        popup = ~paste0(
          "<b>Concesión:</b> ", ifelse(!is.na(com), com, "No registrado"), "<br>",
          "<b>Régimen:</b> ", ifelse(!is.na(rgm), rgm, "No registrado"), "<br>",
          "<b>Tipo de minería:</b> ", ifelse(!is.na(tipo_miner), tipo_miner, "No registrado"), "<br>",
          "<b>Producto:</b> ", ifelse(!is.na(tmm), tmm, "No registrado"), "<br>",
          "<b>Área (km²):</b> ", area_km2, "<br>",
          "<b>Distancia a SNAP más cercana (km):</b> ", dist_snap_km, "<br>",
          "<b>Distancia al río más cercano (km):</b> ", dist_rio_km, "<br>",
          "<b>Altitud media (m):</b> ",  ifelse(is.na(elev_prom_m), "NA", elev_prom_m), "<br>"
        )
      )%>%
      addPolylines(data = rios,  group = "Ríos", color = "#2980B9", weight = 1.3) %>%
      addLayersControl(
        overlayGroups = c("Elevación", "Áreas protegidas", "Ríos", "Concesiones mineras"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })
  # --- Histograma: Distancia al SNAP más cercano (km) ---
  output$hist_snap <- renderPlotly({
    make_hist_auto(
      x     = minas$dist_snap_km,
      title = "Distancia a áreas protegidas (km)",
      xlab  = "Distancia (km)",
      unit  = "km",
      color = "#1a9850",
      digits = 2
    )
  })
  
  
  # --- Histograma: Distancia al río más cercano (km) ---
  output$hist_rio <- renderPlotly({
    make_hist_auto(
      x     = minas$dist_rio_km,
      title = "Distancia al río más cercano (km)",
      xlab  = "Distancia (km)",
      unit  = "km",
      color = "#3498DB",
      digits = 2
    )
  })
  
  # --- Histograma: Altitud media (m) ---
  output$hist_elev <- renderPlotly({
    make_hist_auto(
      x     = minas$elev_prom_m,
      title = "Altitud media de concesiones (m)",
      xlab  = "Altitud (m)",
      unit  = "m",
      color = "#E67E22",
      digits = 0
    )
  })
}

app <- shinyApp(ui, server)
runApp(app)
