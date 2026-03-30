# Indices de vulnérabilité agricole — Vaud (Suisse)

Calcul d'indices de vulnérabilité composites pour les parcelles agricoles,
combinant les dimensions topographique, pédologique et climatique.

## Structure du projet
```
├── data/
│   ├── raw/                          # Données sources non versionnées
│   └── processed/                    # Données intermédiaires non versionnées
├── outputs/
│   ├── Cartes d'indices
│   └── Statistiques régionales, culturales, par exploitation
├── scripts/
│   ├── topo_process.ipynb            # Calcul de l'indice topographique
│   ├── sol_process.ipynb             # Calcul de l'indice pédologique
│   ├── climat_process.ipynb          # Calcul de l'indice climatique
│   ├── meta_process.ipynb            # Agrégation → indices de vulnérabilité composites
│   ├── stats_agri.ipynb              # Statistiques descriptives et ANOVA par région et culture
│   └── tiff_to_png_for_shiny.ipynb   # Conversion GeoTIFF → PNG pour l'application Shiny
├── app/
│   ├── rasters            		   # Rasters de reference avec valeurs exactes
│   ├── www            			   # PNG à afficher dynamiquement dans l'app
│   └── app.R            			   # Application de visualisation interactive (R / Shiny)    
└── PDMe_GonzalezMikael.pdf    		   # Justifications scientifiques, calculs et sources
```

## Pipeline
```
topo_process ──┐
sol_process  ──┼──► meta_process ──► stats_agri
climat_process ┘
                         │
                         └──► tiff_to_png_for_shiny ──► app.R
```

Les trois notebooks amont calculent chacun un indice thématique à l'échelle
de la parcelle. `meta_process` les joint et les combine en indices composites
(pondération égale, pondération GWL2, etc.). `stats_agri` effectue des
statistiques descriptives et des tests ANOVA sur les indices résultants,
par région agricole et par catégorie de culture.

`tiff_to_png_for_shiny` convertit les rasters GeoTIFF produits en PNG allégés
pour leur intégration dans `app.R`, une application Shiny permettant la
visualisation interactive des indices.

## Documentation scientifique

Le fichier `rapport_methodologique.pdf` fourni dans ce dépôt détaille
l'ensemble des choix méthodologiques, les formules de calcul et les sources
de données mobilisées.

## Données

Les données d'entrée ne sont pas versionnées (fichiers GeoPackage locaux).
Le détail est expliqué dans le rapport méthodologique.

## Dépendances

Python :
```
numpy, geopandas, rasterio, scipy, rioxarray, xarray, json, osgeo (gdal), pathlib, matplotlib
```

R :
```
shiny, bslib, jsonlite, terra
```

## Résultats

Fichiers raster d'indices de propension à la sécheresse selon les paramètres
mis en entrée. Statistiques sur ces indices en lien avec des groupes d'intérêt :
régions agricoles, catégories de culture, exploitations.