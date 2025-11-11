# 🗺️ Aplicación Shiny: Minería y Áreas Protegidas en Napo (Ecuador)

Esta aplicación combina **R (Shiny, Leaflet, Plotly, sf, terra)** y **QGIS** para analizar la relación espacial entre las **concesiones mineras** y las **áreas protegidas, ríos y altitud del terreno** en la provincia de **Napo (Ecuador)**.  

Permite visualizar y explorar interactivamente datos geoespaciales obtenidos de fuentes oficiales ecuatorianas e internacionales, con el fin de apoyar procesos de análisis ambiental y planificación territorial.

---
![Grabación 2025-11-11 001409](https://github.com/user-attachments/assets/0b3501c5-f240-4ee4-b4b0-e7bbbfec25a7)

## 🌍 Contenidos del proyecto


```
Mineria_Napo_MVP/
│
├── app.R                        # Aplicación principal Shiny
├── README.md                    # Este archivo
└── data/                        # Carpeta con datos espaciales
    ├── mineria_napo.geojson     # Concesiones mineras en Napo
    ├── snap_napo.shp            # Áreas protegidas (SNAP)
    ├── rios_napo.shp            # Red hídrica principal
    ├── napo.shp                 # Límite provincial
    └── srtm_napo_clip.tif       # Modelo de elevación (DEM)
```

---

## ⚙️ Requisitos

- **R** ≥ 4.2  
- **RStudio** o una terminal R interactiva  
- Los siguientes paquetes (instálalos con `install.packages()`):

```r
install.packages(c("shiny", "leaflet", "sf", "terra", "dplyr", "shinythemes", "ggplot2", "plotly"))
```

---

## ▶️ Ejecución de la aplicación

1. Abre RStudio.  
2. Establece el directorio de trabajo en la carpeta del proyecto:
   ```r
   setwd("C:/ruta/a/Mineria_Napo_MVP")
   ```
3. Ejecuta la aplicación:
   ```r
   shiny::runApp(".")
   ```

Esto abrirá la aplicación en tu navegador local (`http://127.0.0.1:xxxx`).

---

## 🧭 Funcionalidades

### 🗺️ Mapa interactivo (Leaflet)
La aplicación permite visualizar las principales capas geográficas relacionadas con la actividad minera y la conservación ambiental en Napo:
- **Concesiones mineras** (color naranja)
- **Áreas protegidas** del SNAP (verde)
- **Ríos principales** (azul)
- **Elevación** del terreno (raster `terrain.colors`)

El panel lateral permite **activar o desactivar capas**.  
Al hacer clic sobre una concesión se muestran:
- Nombre de la concesión  
- Régimen y tipo de minería  
- Producto y área (km²)  
- Distancia a la zona protegida y al río más cercano  
- Altitud media (m)

---

### 📊 Gráficos interactivos (Plotly)

Debajo del mapa se incluyen tres histogramas que resumen variables clave:

1. **Distancia a áreas protegidas (km)**  
2. **Distancia al río más cercano (km)**  
3. **Altitud media de las concesiones (m)**  

Cada gráfico es interactivo: al pasar el cursor se visualiza el **conteo de concesiones** y el **rango correspondiente**.  
Los intervalos se calculan automáticamente con la regla de **Freedman–Diaconis**, garantizando una distribución estadísticamente representativa.

---

## 🛰️ Fuentes de datos

| Capa | Fuente | Descripción |
|------|---------|-------------|
| `mineria_napo.geojson` | **Agencia de Regulación y Control Minero (ARCOM)** | Concesiones mineras inscritas, en trámite o otorgadas |
| `snap_napo.shp` | **Ministerio del Ambiente, Agua y Transición Ecológica (MAATE)** | Sistema Nacional de Áreas Protegidas del Ecuador |
| `rios_napo.shp` | **HydroRIVERS (WWF / HydroSHEDS)** | Red hídrica principal de Sudamérica |
| `napo.shp` | **Instituto Geográfico Militar (IGM)** | División político-administrativa del Ecuador |
| `srtm_napo_clip.tif` | **NASA SRTM (Shuttle Radar Topography Mission)** – obtenido desde [USGS EarthExplorer](https://earthexplorer.usgs.gov/) | Modelo digital de elevación (30 m de resolución) |

---

## 📈 Resultados

La aplicación permite:
- Identificar concesiones mineras cercanas a zonas protegidas.  
- Analizar la distribución altitudinal de las concesiones.  
- Evaluar la relación entre la ubicación minera y la red hídrica.  
- Visualizar y explorar patrones espaciales relevantes para la gestión ambiental en la Amazonía ecuatoriana.

---

## 👤 Autor

**Alison Sango**   
Proyecto de análisis espacial con R y QGIS.  
