library(shiny)
library(bslib)
library(jsonlite)
library(terra)

# ============================================================
# DOSSIERS
# ============================================================

img_dir <- "www"
raster_dir <- "rasters"

# ============================================================
# DICTIONNAIRE COUCHES
# ============================================================

layer_dict <- list(
  "Indice composite +2°C" = list(
    png = "indice_eq_gwl2_norm_geo_layers.png",
    json = "indice_eq_gwl2_norm_geo_layers.json"
  ),
  
  "Indice de vulnérabilité du sol" = list(
    png = "Sol_index_normalized_geo_layers.png",
    json = "Sol_index_normalized_geo_layers.json"
  ),
  
  "Indice de modulation topographique" = list(
    png = "Topo_index_50m_clip_norm_geo_layers.png",
    json = "Topo_index_50m_clip_norm_geo_layers.json"
  ),
  
  "Indice d'exposition climatique" = list(
    png = "I_climat_gwl2_ensemble_clip_norm_geo_layers.png",
    json = "I_climat_gwl2_ensemble_clip_norm_geo_layers.json"
  ),
  
  "Indice d'érosion quantitative (map.geo.admin)" = list(
    png = "erosion-quantitativ_2056_clip_geo_layers.png",
    json = "erosion-quantitativ_2056_clip_geo_layers.json"
  )
)

# ============================================================
# RASTERS SOURCES
# ============================================================

raster_files <- c(
  "Indice composite +2°C" = "indice_eq_gwl2_norm.tif",
  "Indice de vulnérabilité du sol" = "Sol_index_normalized.tif",
  "Indice de modulation topographique" = "Topo_index_50m_clip_norm.tif",
  "Indice d'exposition climatique" = "I_climat_gwl2_ensemble_clip_norm.tif",
  "Indice d'érosion quantitative (map.geo.admin)" = "erosion-quantitativ_2056_clip.tif"
)

# ============================================================
# LEGENDE INDICES
# ============================================================

legend_colors <- c(
  "rgb(204,0,0)",
  "rgb(255,165,0)",
  "rgb(255,255,102)",
  "rgb(102,194,102)",
  "rgb(0,100,0)",
  "white"
)

legend_labels <- c(
  "0.8 – 1",
  "0.6 – 0.8",
  "0.4 – 0.6",
  "0.2 – 0.4",
  "0.01 – 0.2",
  "NoData"
)

# ============================================================
# LEGENDE EROSION
# ============================================================

erosion_legend_colors <- c(
  "rgb(0,100,0)",
  "rgb(102,194,102)",
  "rgb(171,221,164)",
  "rgb(255,255,153)",
  "rgb(255,220,120)",
  "rgb(253,174,97)",
  "rgb(244,109,67)",
  "rgb(215,25,28)",
  "rgb(139,0,0)"
)

erosion_legend_labels <- c(
  "0 – 10 t/(ha·an)",
  "10 – 20 t/(ha·an)",
  "20 – 30 t/(ha·an)",
  "30 – 40 t/(ha·an)",
  "40 – 50 t/(ha·an)",
  "50 – 70 t/(ha·an)",
  "70 – 100 t/(ha·an)",
  "100 – 200 t/(ha·an)",
  "> 200 t/(ha·an)"
)

# ============================================================
# MAPPING EROSION
# ============================================================

map_erosion_class <- function(value){
  
  if(is.na(value)) return("NoData")
  
  vmin <- 1
  vmax <- 9
  
  normalized <- (value - vmin) / (vmax - vmin)
  normalized <- max(0, min(1, normalized))
  
  idx <- floor(normalized * (length(erosion_legend_labels) - 1)) + 1
  idx <- max(1, min(idx, length(erosion_legend_labels)))
  
  erosion_legend_labels[idx]
}

# ============================================================
# UI
# ============================================================

ui <- page_fluid(
  
  titlePanel("Visualisation des cartes d'indices de sécheresse"),
  
  sidebarLayout(
    
    sidebarPanel(
      
      selectInput(
        "img_select",
        "Choisir une carte :",
        choices = names(layer_dict)
      ),
      
      h4("Coordonnées"),
      verbatimTextOutput("coords"),
      
      h4("Valeurs indices"),
      tableOutput("values"),
      
      hr(),
      
      tags$div(
        style="font-size:0.85em;color:#555;line-height:1.4;",
        tags$strong("À propos des indices"),
        tags$br(),tags$br(),
        "Indices issus d'une modélisation environnementale combinant pédologie, topographie et climat.",
        tags$br(),tags$br(),
        "Projet de Master EPFL – FiBL",
        tags$br(),tags$br(),
        "Auteur : Mikael Gonzalez"
      )
      
    ),
    
    mainPanel(
      
      fluidRow(
        
        column(
          9,
          
          tags$div(
            id="map_container",
            style="
            width:100%;
            height:900px;
            overflow:hidden;
            border:1px solid #ccc;
            position:relative;
            cursor:grab;
            ",
            
            tags$div(
              id="map_inner",
              style="transform-origin: top left;",
              
              imageOutput("image", click="image_click"),
              
            
            )
          )
          
        ),
        
        column(
          3,
          h4("Légende"),
          uiOutput("legend")
        )
        
      )
      
    )
    
  ),
  
  tags$script(HTML("
let scale = 1;
let posX = 0;
let posY = 0;
let dragging = false;
let startX,startY;

const container = document.getElementById('map_container');
const inner = document.getElementById('map_inner');

function update(){
  inner.style.transform = `translate(${posX}px,${posY}px) scale(${scale})`;
}

container.addEventListener('wheel',function(e){

  e.preventDefault();

  const rect = container.getBoundingClientRect();

  const mouseX = e.clientX - rect.left;
  const mouseY = e.clientY - rect.top;

  const oldScale = scale;

  if(e.deltaY < 0){
    scale *= 1.1;
  }else{
    scale /= 1.1;
  }

  scale = Math.max(1,Math.min(scale,20));

  const scaleFactor = scale / oldScale;

  posX = mouseX - (mouseX - posX) * scaleFactor;
  posY = mouseY - (mouseY - posY) * scaleFactor;

  update();

},{passive:false});


container.addEventListener('mousedown',function(e){

  dragging = true;
  startX = e.clientX - posX;
  startY = e.clientY - posY;

});

document.addEventListener('mousemove',function(e){

  if(!dragging) return;

  posX = e.clientX - startX;
  posY = e.clientY - startY;

  update();

});

document.addEventListener('mouseup',function(){

  dragging = false;

});


container.addEventListener('dblclick',function(){

  scale = 1;
  posX = 0;
  posY = 0;

  update();

});


"))
)

# ============================================================
# SERVER
# ============================================================

server <- function(input, output, session){
  
  clicked_coords <- reactiveVal(NULL)
  clicked_values <- reactiveVal(NULL)
  
  raster_meta <- reactive({
    req(input$img_select)
    fromJSON(file.path(img_dir, layer_dict[[input$img_select]]$json))
  })
  
  output$image <- renderImage({
    
    req(input$img_select)
    
    list(
      src = file.path(img_dir, layer_dict[[input$img_select]]$png),
      contentType = "image/png",
      width = "100%"
    )
    
  }, deleteFile = FALSE)
  
  observeEvent(input$image_click,{
    
    meta <- raster_meta()
    
    px <- input$image_click$x
    py <- input$image_click$y
    
    xmin <- meta$bounds$xmin
    xmax <- meta$bounds$xmax
    ymin <- meta$bounds$ymin
    ymax <- meta$bounds$ymax
    
    width <- meta$width
    height <- meta$height
    
    x_coord <- xmin + (px/width)*(xmax-xmin)
    y_coord <- ymax - (py/height)*(ymax-ymin)
    
    coords <- data.frame(x=x_coord,y=y_coord)
    
    clicked_coords(coords)
    
    values <- sapply(names(raster_files), function(name){
      
      r <- rast(file.path(raster_dir, raster_files[name]))
      val <- terra::extract(r, coords)[1,2]
      
      if(name == "Indice d'érosion quantitative (map.geo.admin)"){
        return(map_erosion_class(val))
      }
      
      if(is.na(val)) return("NoData")
      
      round(val,3)
    })
    
    clicked_values(values)
    
  })
  
  output$coords <- renderPrint({
    
    req(clicked_coords())
    
    c <- clicked_coords()
    
    cat(
      paste0(
        "X LV95 : ",round(c$x,1),
        "\nY LV95 : ",round(c$y,1)
      )
    )
    
  })
  
  output$values <- renderTable({
    
    req(clicked_values())
    
    data.frame(
      Indice = names(clicked_values()),
      Valeur = unname(clicked_values()),
      stringsAsFactors = FALSE
    )
    
  })
  
  output$legend <- renderUI({
    
    # Valeurs par défaut
    explanation <- NULL
    
    if(input$img_select == "Indice d'érosion quantitative (map.geo.admin)"){
      
      cols <- erosion_legend_colors
      labs <- erosion_legend_labels
      title <- "Érosion (t/(ha·an))"
      
    } else {
      
      cols <- legend_colors
      labs <- legend_labels
      title <- "Indices de sécheresse (0 – 1)"
      
      explanation <- tags$div(
        style = "font-size:0.85em; color:#555; margin-bottom:12px; line-height:1.3;",
        "Plus la valeur est proche de 1, plus les conditions environnementales favorisent la sécheresse."
      )
    }
    
    tagList(
      
      tags$div(tags$strong(title)),
      
      explanation,
      
      lapply(seq_along(cols), function(i){
        
        tags$div(
          style="display:flex;align-items:center;margin-bottom:6px;",
          
          tags$div(
            style=paste0(
              "width:20px;height:20px;",
              "background-color:",cols[i],
              ";border:1px solid #333;margin-right:8px;"
            )
          ),
          
          tags$span(labs[i])
        )
        
      })
      
    )
  })
  
}

shinyApp(ui,server)