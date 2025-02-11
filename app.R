# app.R

# --------------------
# Notes Auto ESO v1.0.
# --------------------
# 
# Aplicació Shiny robusta per a la graficació automatitzada de notes d'alumnes.
# 
# Versió de R: 4.4.2
# 
# Pujada en la web: https://notesautoeso.shinyapps.io/notes_auto_eso/
# 
# Codi en: https://github.com/josepACTG/Notes_ESO_auto
# 
# + info: jllobe12@xtec.cat
# 
# Obert a:
#   - col·laboració
#   - propostes de millora
#   - comentari d'errors




# -->CAMBIAR EN SHINY DEPLYMENT<--
# options(repos = c(CRAN = "https://cran.rstudio.com/"))


#__Sobre el Deployment:__
# Aquest és la pujada de l'arxiu en la web de Shinyapps.io
# !!Alerta!! Algunes funcions es canvien abans de fer el deploy del programa. 
# Aquestes són les indicades amb el comentari: # -->CAMBIAR EN SHINY DEPLYMENT<--
# Bàsicament són alguns comandaments bàsics de deployment, aixi com les funcions dels 
# enllaços web que en R studio funcionarien incorrectament.


#_Cóm pujar arxius a Shiny.io?
# Això es fa a partir del botó "Publish" de l'app de Shiny. En últim térme, 
# per a pujar un programa i convertir-lo en format web, es fa servir (adaptat) el comandament:
#
# library(rsconnect)
# rsconnect::deployApp('D:/Escritorio/Notes_Auto_ESO')





#____Funcions internes______#
cargar_paquete <- function(nombre_paquete) {
  
  # Busca primer si el paquet està cridat a una llibreria. Sino, el crida, i si no està instal·lat, l'instala.
  # 
  # cargar_paquete("plotly") #<- exemple
  
  
  # Verificar si el paquete ya está cargado
  if (paste0("package:", nombre_paquete) %in% search()) {
    message("El paquete '", nombre_paquete, "' ya está cargado.")
  } else {
    # Intentar cargar el paquete
    if (require(nombre_paquete, character.only = TRUE, quietly = TRUE)) {
      message("El paquete '", nombre_paquete, "' se ha cargado correctamente.")
    } else {
      # Si el paquete no está instalado, instalarlo y luego cargarlo
      message("El paquete '", nombre_paquete, "' no está instalado. Instalándolo...")
      install.packages(nombre_paquete, dependencies = TRUE)
      if (require(nombre_paquete, character.only = TRUE, quietly = TRUE)) {
        message("El paquete '", nombre_paquete, "' se ha instalado y cargado correctamente.")
      } else {
        stop("No se pudo instalar o cargar el paquete '", nombre_paquete, "'.")
      }
    }
  }
}

guardar_dataframe_excel <- function(df) {
  
  # Cargar los paquetes
  
  
  # Comprovar que es un dataframe
  if (!is.data.frame(df)){
    df <- as.data.frame(df)
  }
  
  # Abrir un cuadro de diálogo para que el usuario especifique el nombre y la ubicación del archivo
  archivo <- tcltk::tclvalue(tcltk::tkgetSaveFile(
    title = "Guardar archivo Excel",
    filetypes = "{{Archivos Excel} {.xlsx}} {{Todos los archivos} *}"
  ))
  
  # Verificar si el usuario canceló el cuadro de diálogo
  if (archivo == "") {
    message("Guardado cancelado por el usuario.")
    return(invisible())
  }
  
  # Asegurarse de que la extensión del archivo sea .xlsx
  if (!endsWith(archivo, ".xlsx")) {
    archivo <- paste0(archivo, ".xlsx")
  }
  
  # Guardar el dataframe en el archivo especificado
  write_xlsx(df, archivo)
  message("Archivo guardado exitosamente en: ", archivo)
  
  
  

  
}

transpoar_tabula_notes <- function(taula_primera) {
  # Transposa la taula de notes, de format:
  #
  # AnglÃ¨s Castella Catala CiÃ¨ncies de la terra Tecnologia
  # AE     10        6      6                    4          6
  # AN      2        6      4                    6          4
  # AS      6        5      4                    7          2
  # NA      1        2      5                    2          7
  #
  # Per:
  # AnglÃ¨s Castella Catala Ciencies de la terra Tecnologia
  # NA      1        2      5                    2          7
  # AS      6        5      4                    7          2
  # AN      2        6      4                    6          4
  # AE     10        6      6                    4          6
  #
  # Aquesta funciÃ³ serveix per a que els colors coincideixin amb el grafic.
  
  #Donar la volta a la taula

  taula_final <- matrix(, nrow = nrow(taula_primera), ncol = ncol(taula_primera))

  taula_final[4,] <- taula_primera[1,]
  taula_final[3,] <- taula_primera[2,]
  taula_final[2,] <- taula_primera[3,]
  taula_final[1,] <- taula_primera[4,]
  
  colnames(taula_final) <- colnames(taula_primera)
  rownames(taula_final) <- rev(rownames(taula_primera))

  
  return(taula_final)
}

ordenar_taula_notes <- function(taula_notes_a_ordenar, nota_ordenar, ordre_descendent) {
  # ordena una taula de notes segons s'indiqui la nota ("NA", "AS", "AN", "AE") i si es vol ordenar de forma ascendent o descendent.
  #Fer que la taula s'ordeni segons la nota indicada, en forma ascendent o descendent.
  # Ordena una taula de notes (taula_notes_a_ordenar) com per exemple:
  #
  # barap_notes_tot Anglès Biologia Castellà Català Matemàtiques Optativa 1 Optativa 2 Religió Tecnologia Valors
  #          AE      3        4        4      3            5          7          9       3          7      4
  #          AN      4        4        4      5            5          6          7       7          8      8
  #          AS      7        6        6      5            4          4          3       3          2      1
  #          NA      4        6        1      6            7          2          2       4          2      8
  # Segons la nota indicada (nota_ordenar), i l'ordre descendent o ascendent (ordre_descendent)
  #
  # 
  #
  # Variables:
  #
  # nota_ordenar : Nota a ordenar de la taula: "NA", "AS", "AN", "AE".
  # ordre_descendent : Si l'ordre serà ascendent o descendent:T/F
  # taula_notes_a_ordenar : Taula de dades
  #
  #   nota_ordenar <- "NA", "AS", "AN", "AE".
  #   ordre_descendent <- T/F
  
  # Mirem a quina posició (fila) està la nota (NA, AS, etc...)
  pos_nota <- which(rownames(taula_notes_a_ordenar) == nota_ordenar)
  
  # ORDENAR (sort), segons la fila seleccionada
  # Ordenar la primera fila en orden ascendente y reorganizar las columnas
  orden <- order(taula_notes_a_ordenar[pos_nota, ], decreasing = ordre_descendent)  # Generar el índice de ordenación basado en la     primera fila
  taula_notes_a_ordenar <- taula_notes_a_ordenar[, orden]     # Reordenar las columnas de la matriz
  # -> ANTIC: taula_notes_a_ordenar[pos_nota, ] <- sort(taula_notes_a_ordenar[pos_nota, ], decreasing = ordre_descendent)
  

  
  
  taula_notes_ordenada <- taula_notes_a_ordenar
  
  return(taula_notes_ordenada)
  
}

sumar_excloent_nota <- function(taula_valors, nota_tipus){
  # 
  # Retorna el total de notes d'una taula, excloent una nota nota determinada.
  #
  # nota_tipus <- "NA"
  
  # Mirem a quina posició (fila) està la nota (NA, AS, etc...)
  pos_nota <- which(rownames(taula_valors) == nota_tipus)
  
  # Eliminem aquesta fila
  taula_valors_restada <- taula_valors[-pos_nota,]
  
  return(taula_valors_restada)    
  
}

determina_color_nota <- function(tipus_nota){
  if (tipus_nota == "NA"){
    tipus_color <- "#f9011c"
  }
  if (tipus_nota == "AS"){
    tipus_color <- "#ffd82f"
  }
  if (tipus_nota == "AN"){
    tipus_color <- "#b0d50c"
  }
  if (tipus_nota == "AE"){
    tipus_color <- "#00c03f"
  }
  
  
  
  return(tipus_color)
}

obtenir_assignatures <- function(dades_alumnes_func, alumne){
  
  # A partir del df principal dades_alumnes_func, i del nom de l'alumne,
  # obtenim un llistat dels noms de les assignatures dels diferents tipus de notes. 
  # Aquesta funció serveix principalment per a graficar.
  # exemple:
  # notes_krillin <- obtenir_assignatures(dades_alumnes_func, "Krillin")
  # notes_krillin$nota_NA
  # 
  
  # Obtenim la fila de l'alumne en qüestió
  df_alumne_notes <- dades_alumnes_func[rownames(dades_alumnes_func)==alumne,]
  
  
  #Treiem les columnes on hi ha NA del dataframe
  dades_alumnes_func <- dades_alumnes_func[,!is.na(df_alumne_notes)]  
  
  #Ara tenim el df sense les assignatures amb NA.
  
  # #Treiem NA de la llista de valors.
  df_alumne_notes <- df_alumne_notes[,!is.na(df_alumne_notes)]
  # 
  
  
  
  #Ara farem llista de cada nota.
  
  resultats <- list()
  
  # Crear una lista con 4 listas vacías
  llista_tot <- list(c(), c(), c(), c())
  
  tipus_notes <- c("NA", "AS", "AN", "AE")
  
  nota_NA <- c()
  nota_AS <- c()
  nota_AN <- c()
  nota_AE <- c()
  
  
  for (n_assignatura in 1:ncol(df_alumne_notes)){
    
    assignatura <- colnames((df_alumne_notes)[n_assignatura])  
    nota <- as.character(df_alumne_notes[n_assignatura])
    
    
    if (is.na(nota)) {
      # Manejar el caso de NA
    } else if (nota == "NA")  {
      nota_NA <- append(nota_NA, assignatura)
    } else if (nota == "AS"){
      nota_AS <- append(nota_AS, assignatura)
    } else if (nota == "AN"){
      nota_AN <- append(nota_AN, assignatura)
    } else if (nota == "AE"){
      nota_AE <- append(nota_AE, assignatura)
    } else {
      warning("Error en lectura de les dades")
    }
    
    
  }
  
  # Juntem les notes...
  notes_totals <- c(nota_NA, nota_AS, nota_AN, nota_AE)
  
  
  return(list(notes_totals = notes_totals, nota_NA = nota_NA, nota_AS = nota_AS, nota_AN = nota_AN, nota_AE = nota_AE))
  
}

obtenir_alumnes <- function(dades_alumnes_func, assignatura){
  
  # A partir del df principal dades_alumnes_func, i del nom de l'alumne,
  # obtenim un llistat dels noms de les assignatures dels diferents tipus de notes. 
  # Aquesta funció serveix principalment per a graficar.
  # exemple:
  # notes_krillin <- obtenir_assignatures(dades_alumnes_func, "Krillin")
  # notes_krillin$nota_NA
  


  # Obtenim la fila de les notes de l'assignatura
  df_alumne_notes <- dades_alumnes_func[,colnames(dades_alumnes_func)==assignatura]
  
  #Treiem les files on hi ha NA del dataframe
  dades_alumnes_func <- dades_alumnes_func[!is.na(df_alumne_notes),]
  
  #Treiem NA's si hi ha
  df_alumne_notes <-df_alumne_notes[!is.na(df_alumne_notes)]
  
  #Ara farem llista de cada nota.
  resultats <- list()
  
  # Crear una lista con 4 listas vacías
  llista_tot <- list(c(), c(), c(), c())
  
  tipus_notes <- c("NA", "AS", "AN", "AE")
  
  nota_NA <- c()
  nota_AS <- c()
  nota_AN <- c()
  nota_AE <- c()
  
  # Per a cada nota (cada alumne)  
  for (n_alumne in 1:length(df_alumne_notes)){
    
    alumne <- rownames(dades_alumnes_func)[n_alumne]
    

    nota <- as.character(df_alumne_notes[n_alumne])

    
    if (is.na(nota)) {
      # Manejar el caso de NA
    } else if (nota == "NA")  {
      nota_NA <- append(nota_NA, alumne)
    } else if (nota == "AS"){
      nota_AS <- append(nota_AS, alumne)
    } else if (nota == "AN"){
      nota_AN <- append(nota_AN, alumne)
    } else if (nota == "AE"){
      nota_AE <- append(nota_AE, alumne)
    } else {
      warning("Error en lectura de les dades")
    }
    
  }
  
  # Juntem les notes...
  notes_totals <- c(nota_NA, nota_AS, nota_AN, nota_AE)
  
  
  return(list(notes_totals = notes_totals, nota_NA = nota_NA, nota_AS = nota_AS, nota_AN = nota_AN, nota_AE = nota_AE))
  
}

ordenar_tabla <- function(datos, orden_deseado) {
  # Convertir los nombres de las columnas en un factor con el orden deseado
  nombres_ordenados <- factor(names(datos), levels = orden_deseado)
  
  # Reordenar la tabla según el factor
  datos_ordenados <- datos[order(nombres_ordenados)]
  
  # Devolver la tabla ordenada
  return(datos_ordenados)
  
  
  # # Ejemplo de uso
  # datos <- c(AS = 10, NA = 7, AE = 6, AN = 6)
  # orden_deseado <- c("NA", "AS", "AN", "AE")
  # 
  # # Llamar a la función
  # tabla_ordenada <- ordenar_tabla(datos, orden_deseado)
  # 
  # # Mostrar el resultado

}

resumir_notes <- function(dades_alumnes){
  #Resumeix les dades de dades_alumnes de manera que es retorna una taula de frequencies.
  
  #Creem la matriu vuida:
  taula_resum_notes <- matrix(nrow = nrow(dades_alumnes), ncol = 4 )
  colnames(taula_resum_notes) <- c("NA", "AS", "AN", "AE")
  rownames(taula_resum_notes) <- rownames(dades_alumnes)
  
  for(n_ass in 1: nrow(dades_alumnes)) {
    
    alumne <- rownames(dades_alumnes)[n_ass] # Alumne
    taula_notes <- table(dades_alumnes[n_ass,]) # Notes (valors) # AAA Falla array. Ha de ser en taula, la taula no es fa bé.
    taula_notes <- taula_notes[c("NA", "AS", "AN", "AE")] # Ordenada
    
    taula_notes <- table(factor(as.character(dades_alumnes[n_ass,]), levels = c("NA", "AS", "AN", "AE")))
    
    taula_resum_notes[n_ass, ] <- taula_notes
  }
  
  
  return(taula_resum_notes)
}

convertir_a_numerico <- function(df) {
  # Crear un vector con las conversiones de las calificaciones
  conversiones <- c("AE" = 9, "AN" = 7.5, "AS" = 5.5, "NA" = 3)
  
  # Aplicar la conversión a todo el dataframe
  df_convertido <- df
  # df_convertido[] <- lapply(df, function(x) conversiones[x])
  df_convertido[] <- lapply(df, function(x) ifelse(is.na(x), NA, conversiones[x]))
  
  return(df_convertido)
}

convertir_notas <- function(df) {
  # Definir las conversiones
  conversiones <- c("AE" = 9, "AN" = 7.5, "AS" = 5.5, "NA" = 3)
  
  # Función para convertir un valor numérico
  convertir_valor <- function(valor) {
    if (valor >= conversiones["AE"]) {
      return("AE")
    } else if (valor >= conversiones["AN"]) {
      return("AN")
    } else if (valor >= conversiones["AS"]) {
      return("AS")
    } else if (valor >= 0) {
      return("NA")
    } else {
      return(NA) # Para valores fuera del rango esperado
    }
  }
  
  # Aplicar la conversión a cada columna del dataframe (excepto nombres de los alumnos)
  df_convertido <- df
  # df_convertido[] <- lapply(df_convertido, function(columna) sapply(columna, convertir_valor))
  df_convertido[] <- lapply(df_convertido, function(columna) sapply(columna, function(x) ifelse(is.na(x), NA, convertir_valor(x))))
  
  return(df_convertido)
}

detectar_valors_erronis <- function(dades_alumnes_posar){
  #Donada un dataframe amb valors de caràcters (no numèrics) retorna un missatge sobre si 
  # alguna de les dades no coindiceix amb SQ, NA, AN, AE. Retorna els noms de les files (alumnes)
  # on no es produeix aquesta coincidència.
  
  noms_alumnes_error <- c()
  
  df_cerca_valors_erronis <- (!is.na(dades_alumnes_posar) & 
                                dades_alumnes_posar != "NA" & 
                                dades_alumnes_posar != "AS" &
                                dades_alumnes_posar != "AN" &
                                dades_alumnes_posar != "AE")
  

  
  #Mirem errors per fila
  true_por_fila <- rowSums(df_cerca_valors_erronis == TRUE, na.rm = TRUE)
  
  # Identifiquem els noms dels alumnes amb errors
  noms_alumnes_error <- rownames(dades_alumnes_posar)[true_por_fila > 0]

  #_Mirem si hi ha error en les dades:
  if (sum(true_por_fila[true_por_fila>0]) > 0){

    shinyalert(
      title = "¡Error!",
      text = paste("Hi ha algun error en les dades dels següents alumnes: ", paste(noms_alumnes_error, collapse = "\n")) ,
      type = "error"
    )
    
    stop("Error Carregar dades: Valors no són NA, AS, AN, AE, o QR. Dades incorrectes") 
    
    
  } else {
    print("Dades correctes")
  }
  
  return(noms_alumnes_error)
  
}

detectar_assign_vuides <- function(dades_alumnes_excel){
  #Mirem si hi ha columnes d'assignatures vuides, i les treiem:
  
  cols_vacias <- names(dades_alumnes_excel)[colSums(!is.na(dades_alumnes_excel)) == 0]
  
  #_Mirem si hi ha error en les dades:
  if (length(cols_vacias) >= 1 ){
   
    shinyalert(
      title = "Ep!",
      text = paste("S'ha esborrat les assignatures següents amb motiu que no tenen notes: ", paste(cols_vacias, collapse = "\n")),
      type = "warning"
    )
    
    
    print("Hi ha assignatures vuides")
    
  }
  
  return(cols_vacias)
}

detectar_valors_SQ <- function(dades_alumnes){
  # Alerta si hi ha SQ, doncs aquests es borraràn.

  total_sq <- sum(apply(dades_alumnes, 2, function(x) sum(grepl("SQ", x))))

  if (total_sq >= 1){
    shinyalert(
      title = "Ep!",
      text = "S'han esborrat les notes sense qualificar ('SQ') i no seràn analitzades.",
      type = "warning"
    )

  }

}

numeric_df_comprovar <- function(dades_alumnes){
  
  # # Mirem si hi ha valors numèrics
  es_numerico <- function(x_var) {
    num_valor <- suppressWarnings(as.numeric(convert_to_numeric(x_var)))
    !is.na(suppressWarnings(as.numeric(convert_to_numeric(x_var)))) & grepl("^-?\\d+(\\.\\d+)?$", x_var)
  }

  
  llista_valors <- unlist(dades_alumnes)
  valores_numericos <- sapply(unlist(dades_alumnes), es_numerico)
  
  #Si tots els valors són numèrics:
  if (sum(valores_numericos) ==   length(llista_valors) ){
    return(TRUE)
  }
      else{
        return(FALSE)
      }
    
}

barrejat_df_comprovar <- function(dades_alumnes) {
  
  # Función para verificar si un valor parece numérico pero está en tipo carácter
  es_numerico <- function(x) {
    if (is.na(x)) return(FALSE)
    num_valor <- suppressWarnings(as.numeric(x))
    !is.na(num_valor) & grepl("^-?\\d+(\\.\\d+)?$", x)
  }
  
  es_caracter <- function(x) {
    if (is.na(x)) return(FALSE)
    !es_numerico(x) & is.character(x)
  }
  
  # Convertir el dataframe a un vector y eliminar NAs
  valores <- na.omit(unlist(dades_alumnes))
  
  # Verificar si todos los valores son numéricos
  todos_numericos <- all(sapply(valores, es_numerico))
  
  # Verificar si todos los valores son caracteres
  todos_caracteres <- all(sapply(valores, es_caracter))
  
  # Determinar el resultado basado en las verificaciones
  if (todos_numericos) {
    return("tot_numeric")
  } else if (todos_caracteres) {
    return("tot_caracters")
  } else {
    return("tot_barrejat")
  }
}

mostrar_fecha_hora <- function() {
  # Obtener la fecha y hora actual
  # fecha_hora <- Sys.time()
  fecha_hora <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  # Convertir a formato de texto
  mensaje <- paste("  Data i hora actual: ", fecha_hora, "  ")
  
  # Crear el marco decorativo
  decoracion <- strrep("*", nchar(mensaje))
  
  # Imprimir en la consola con un diseño enmarcado
  cat("\n",
      strrep("*", nchar(mensaje)), "\n",
      strrep("*", nchar(mensaje)), "\n",
      strrep(" ", nchar(mensaje)/2 - 5), "💻 EXECUCIÓ DEL PROGRAMA 💻", "\n",
      strrep("*", nchar(mensaje)), "\n",
      decoracion, "\n",
      mensaje, "\n",
      decoracion, "\n",
      strrep("*", nchar(mensaje)), "\n",
      strrep("*", nchar(mensaje)), "\n",
      "\n")
}

convert_to_numeric <- function(x) {
  x <- gsub(",", ".", x)  # Reemplaza coma por punto
  as.numeric(x)           # Convierte a número
}

guardar_pdf <- function(output_file, input, output, session, dades_reactives) {
  
  tk_messageBox(
    type = "ok",         # Tipo de cuadro: "ok", "yesno", etc.
    message = "Botó encara no disponible.",  # Mensaje del cuadro
    icon = "warning",    # Ícono del cuadro: "info", "warning", "error"
    title = "Advertencia" # Título del cuadro
  )
  
  # cargar_paquete("gridExtra")
  # cargar_paquete("rmarkdown")
  # 
  # pdf(output_file, width = 8.5, height = 11)
  # tryCatch({
  #   # Gràfic global
  # }
  
}

validar_notes <- function(dades) {
  notes_permeses <- c("NA", "AS", "AN", "AE")
  cols_incorrectes <- !sapply(dades, function(x) all(x %in% notes_permeses | is.na(x)))
  if(any(cols_incorrectes)) {
    noms_cols <- names(cols_incorrectes)[cols_incorrectes]
    stop(paste("Valors no permesos a les columnes:", paste(noms_cols, collapse = ", ")))
  }
}



# -->CAMBIAR EN SHINY DEPLYMENT<--

#____Carga/Instal·lació de paquets______#
cargar_paquete("beepr")
cargar_paquete("gt")
cargar_paquete("ggplot2")
cargar_paquete("readxl")

#Shiny especific
cargar_paquete("shiny")
cargar_paquete("shinycssloaders")
cargar_paquete("DT")
cargar_paquete("fmsb")

cargar_paquete("tcltk") # Sols per a box

# cargar_paquete("shinydashboard")
# cargar_paquete("ggimage")
# cargar_paquete("emojifont")

cargar_paquete("ggtext")
cargar_paquete("waffle")

cargar_paquete("reshape2")

cargar_paquete("igraph")

cargar_paquete("ggdendro")

cargar_paquete("ggbeeswarm")
cargar_paquete("beeswarm")

cargar_paquete("plotly")
cargar_paquete("fmsb")

cargar_paquete("dplyr")

cargar_paquete("janitor")
cargar_paquete("shinyalert")

cargar_paquete("tidyr")
cargar_paquete("tibble")

cargar_paquete("writexl") # library(writexl)
cargar_paquete("tcltk") # library(tcltk)


# ↓ PER ↑
# 
# 
# library("beepr")
# library("gt")
# library("ggplot2")
# library("readxl")
# 
# #Shiny especific
# library("shiny")
# library("shinycssloaders")
# library("DT")
# library("fmsb")
# 
# library("tcltk") # Sols per a box
# 
# # library("shinydashboard")
# # library("ggimage")
# # library("emojifont")
# 
# library("ggtext")
# library("waffle")
# 
# library("reshape2")
# 
# library("igraph")
# 
# library("ggdendro")
# 
# 
# library("ggbeeswarm")
# library("beeswarm")
# 
# library("plotly")
# library("fmsb")
# 
# library("dplyr")
# 
# library("janitor")
# library("shinyalert")
# 
# library("tidyr")
# library("tibble")
# 
# library("writexl") # library(writexl)
# library("tcltk") # library(tcltk)




# ________Iniciació del programa_________ #
beep(2) # Pitido d'inici

mostrar_fecha_hora() # Llamar a la función





# Funcions personalitzades amb validació integrada ----------------------------





# Interfície d'usuari ---------------------------------------------------------
# Título que indica que esta sección del código pertenece a la interfaz de usuario (UI) de la aplicación.

ui <- fluidPage(  # Define el diseño principal de la aplicación usando un diseño fluido (responsive).
  
  # Afegeix una capçalera, on hi haurà, entre altrs, el logo del programa, títol, i el logo del Departament d'Educació de Catalunya
  tags$head(
    tags$style(HTML("
      .logo {
        float: left;
        margin-right: 10px;
        margin-top: 5px;
      }
    "))
  ),
  
  # Pestanya de la web
  tags$head(
    tags$title("Notes Auto ESO"),
    tags$link(rel = "icon", type = "image/png", href = "Icon.png") 
  ),
  
  
  # Pie de página
  tags$footer(
    div(
      style = "position: fixed; bottom: 0; width: 100%; background-color: #f8f9fa;
             text-align: center; padding: 10px; font-size: 14px; border-top: 1px solid #ccc;",
      HTML("Aquest és un programa en versió <i>beta</i>. Si teniu alguna proposta de millora, veieu algun 
          <a href='https://github.com/josepACTG/Notes_ESO_auto/issues' target='_blank'>error</a>, 
          o us interessaria col·laborar, escriviu a: 📧 jllobe12@xtec.cat")
    )
  ),
  
  
  titlePanel(
    # #Nota: Les imatges a Shiny han d'estar en una carpeta anomenada www.
    div(
      style = "display: flex; justify-content: space-between; align-items: center;",
      
      
      # -->CAMBIAR EN SHINY DEPLYMENT<--
      # Imagen izquierda con acción al hacer clic
      actionLink("click_izquierda",
                 img(src = "Icon.png", height = 50, style = "border: 2px solid black; border-radius: 5px;")
      ),
      actionLink("click_izquierda",
                 img(src = "github_icon.png", height = 30, style = "border: 2px solid black; border-radius: 5px;")
      ),
      
      # ↓ PER ↑
      
      # actionLink(
      #   "click_izquierda",
      #   tagList(
      #     img(src = "Icon.png", height = 50,
      #         style = "border: 2px solid black; border-radius: 5px; cursor: pointer;"),
      #     tags$script(HTML("$('#click_izquierda').on('click', function() {
      #                   window.open('https://github.com/josepACTG/Notes_ESO_auto', '_blank');
      #                 });"))
      #   )
      # ),
      # actionLink(
      #   "click_izquierda",
      #   tagList(
      #     img(src = "github_icon.png", height = 30,
      #         style = "border: 2px solid black; border-radius: 5px;cursor: pointer;"),
      #     tags$script(HTML("$('#click_izquierda').on('click', function() {
      #                   window.open('https://github.com/josepACTG/Notes_ESO_auto', '_blank');
      #                 });"))
      #   )
      # ),


      
      
      
      span("Notes Auto ESO: Anàlisis automatitzat de notes", style = "flex-grow: 1; text-align: center;"), #📊 
      img(src = "departament_educacio.jpg", height = 50) # Cambia "icono_derecha.png" por el nombre de tu icono
    )
    
    
    
  ),  # Título principal que aparece en la parte superior de la aplicación.
  
  sidebarLayout(  # Crea un diseño con un panel lateral y un panel principal.
    
    sidebarPanel(  # Panel lateral donde se encuentran los controles de entrada y botones.
      
      fileInput("fitxer", "Pujar fitxer Excel", accept = ".xlsx"),
      # Campo para cargar un archivo Excel (extensión .xlsx).
      # hr(),  # Línea horizontal para separar secciones.
      # Añadir la casilla de verificación
      checkboxInput("mostrar_comentaris", "En l'arxiu a pujar hi ha comentaris (última columna)", value = FALSE),              
      helpText("Format requerit:", br(), 
               "- 1ª columna: Noms alumnes", br(),
               "- 1ª fila: Assignatures + comentaris*", br(),
               "- Tipu de notes: ", br(),
               HTML("&nbsp;&nbsp;&nbsp;&nbsp;· NA, AS, AN, AE, SQ"), br(), #"      · NA, AS, AN, AE, SQ",br(),
               HTML("&nbsp;&nbsp;&nbsp;&nbsp; · numèriques") ),  #"      · numèriques" ),

      
      

      conditionalPanel(
        condition = "!output.dades_carregades",  # Mostrar solo si los datos NO están cargados
        
        
        # -->CAMBIAR EN SHINY DEPLYMENT<--
        fluidRow(
          actionButton("abrir_web_1",  HTML("Exemple<br>dades 1"), icon = icon("download")),
          actionButton("abrir_web_2",  HTML("Exemple<br>dades 2"), icon = icon("download"))
        ),
        #Exemple text amb link:
        # fluidRow(
        #   tags$a(href = "https://github.com/josepACTG/Notes_ESO_auto/raw/refs/heads/main/Notes_exemple/Notes_alumnes_1.xlsx", "Exemple dades 1", target = "_blank")
        # ),
        
        # ↓ PER ↑
        
        # fluidRow(
        #   actionButton(
        #     "ir_a_google", 
        #     label = tagList("Exemple dades 1"), 
        #     onclick = "window.open('https://github.com/josepACTG/Notes_ESO_auto/raw/refs/heads/main/Notes_exemple/Notes_alumnes_1.xlsx', '_blank')"
        #   ),
        #   actionButton(
        #     "ir_a_google", 
        #     label = tagList("Exemple dades 2"), 
        #     onclick = "window.open('https://github.com/josepACTG/Notes_ESO_auto/raw/refs/heads/main/Notes_exemple/Notes_alumnes_2.xlsx', '_blank')"
        #   ) )
        
        
      ),
      hr(),

      # Una vegada s'han carregat les dades:
      conditionalPanel(  # Panel que muestra controles solo bajo ciertas condiciones.
        condition = "output.dades_carregades",
        # Se muestra solo si los datos se han cargado correctamente.
        
        #Mostra el botó de descarregar PDF        
        # downloadButton("descarregar_pdf", "Descarregar PDF"),
        downloadButton("descargar_graficos", HTML("Descarregar gràfics<br>(en desenvolupament)"), class = "btn-success"),
        hr(),
        # Botón para descargar un archivo PDF.
        
        
      ),
      
      # # Botó intern de proves    
      # actionButton("boton", "Presionar"),

    ),
    
    mainPanel(  # Panel principal donde se muestran los resultados y gráficos.
      tabsetPanel(  # Contenedor con pestañas para organizar los resultados.
        id = "tabsetPanel",  
        # Identificador único para referenciar el panel de pestañas en otras partes del código.
        
        
        
        tabPanel("📊 Global Alumnes",
                 
                 tags$div(style = "text-align: center;", h3("General alumnes")),
                 plotlyOutput("grafic_assignatures_ordenat_plotty", height = "600px"),
                 
                 plotlyOutput("grafic_densitats_1", height = "400px"),
                 
                 #tags$div(style = "text-align: center;", h3("Distribucións")),
                 # withSpinner(plotOutput("grafic_densitats_2", height = "400px")),
                 # plotlyOutput("grafic_densitats_3", height = "400px"),  # Gràfic densitat totes les notes (de mom no cal)
                 
                 
                 # withSpinner(plotOutput("grafic_assignatures_ordenat", height = "400px")), # grafic de barres fixe

                 
                 hr(style = "border: none; height: 25px; margin: 0; padding: 0;"),  # hr sin línea visible
                 

                 tags$div(style = "text-align: center;", h3("Agrupat per tipus de notes")),
                 # Contenedor para la barra de selección y las flechas
                 fluidRow(
                   # Flecha izquierda
                   column(1, align = "center", 
                          actionButton("flecha_izquierda", icon("arrow-left"))),
                   
                   # Barra de selección centrada
                   column(10, align = "center",
                          selectInput("grupo_graficos", "Selecciona un grupo de gráficos:",
                                      choices = c("Suspensos" = "suspensos",
                                                  "AN y AE" = "an_ae",
                                                  "AE" = "ae"))),
                   
                   # Flecha derecha
                   column(1, align = "center",
                          actionButton("flecha_derecha", icon("arrow-right")))
                 ),
                 
                 
                 # Contenedor para el grupo de gráficos de Suspensos
                 conditionalPanel(
                   condition = "input.grupo_graficos == 'suspensos'",
                   plotlyOutput("grafico_barras_interactivo_suspensos"),
                   withSpinner(plotOutput("grafico_circular_suspensos", height = "500px")),
                   withSpinner(plotOutput("grafico_waffle_suspensos", height = "400px")),
                   withSpinner(plotOutput("grafico_waffle_media_suspensos", height = "200px")),
                   gt_output("tabla_suspensos_GT")
                   

                 ),
                 
                 # Contenedor para el grupo de gráficos de AN y AE
                 conditionalPanel(
                   condition = "input.grupo_graficos == 'an_ae'",
                   plotlyOutput("grafico_barras_interactivo_en_ae"),                   
                   withSpinner(plotOutput("grafico_circular_an_ae", height = "500px")),
                   withSpinner(plotOutput("grafico_waffle_ae_an", height = "400px")),
                   withSpinner(plotOutput("grafico_waffle_media_ae_an", height = "200px")),
                   gt_output("tabla_an_ae_GT")
                 ),
                 
                 # Contenedor para el grupo de gráficos de AE
                 conditionalPanel(
                   condition = "input.grupo_graficos == 'ae'",
                   plotlyOutput("grafico_barras_interactivo_excelents"),                   
                   withSpinner(plotOutput("grafico_circular_ae", height = "500px")),
                   withSpinner(plotOutput("grafico_waffle_ae", height = "400px")),
                   withSpinner(plotOutput("grafico_waffle_media_ae", height = "200px")),
                   gt_output("tabla_ae_GT")
                 ),

                #Gràfic de notes waffle (individual alumne)
                 # withSpinner(plotOutput("grafico_waffle_notas", height = "400px")),
                 # withSpinner(plotOutput("grafico_waffle_media_notas", height = "200px")),
                 
                 #Gràfic de densitat ridge:
                 # withSpinner(plotOutput("grafic_dens_ridge", height = "400px"))
                 # plotlyOutput("grafic_dens_ridge", height = "400px")
                 
        ),


        tabPanel("🎓 Per Alumne",
                 # Pestaña que analiza datos por alumno.
                 
                 # Controles específicos para la pestaña "Per Alumne".
                 conditionalPanel(
                   condition = "input.tabsetPanel == '🎓 Per Alumne'",
                   # Se activa solo si la pestaña seleccionada es "Per Alumne".
                   fluidRow(
                     column(2, actionButton("prev_alumne", "<", class = "btn-primary")),
                     # Botón para navegar al alumno anterior.
                     column(8, selectInput("alumne", "Alumne:", choices = NULL)),
                     # Menú desplegable para seleccionar un alumno. Las opciones se cargan dinámicamente.
                     column(2, actionButton("next_alumne", ">", class = "btn-primary"))
                     # Botón para navegar al siguiente alumno.
                   )
                 ),
                 
                 
                # Títol amb nom de l'alumne.
                tags$div(style = "text-align: center;", h3(textOutput("titulo_alumne"))),
                 withSpinner(
                   fluidRow(
                     column(6, plotOutput("graf_alumne_bar")),  # Gràfic de barres per alumne
                     column(6, plotOutput("graf_alumne_pie"))   # Gràfic circular per alumne
                   )
                 ),
                 # Nova fila per al nou gràfic
                 fluidRow(
                   column(12, withSpinner(plotOutput("graf_alumne_resum", height = "600px")))  # Nou gràfic
                 ),
                 gt_output("taula_alumne"),  # Taula de notes per alumne                 
                 withSpinner(plotOutput("graf_radar_alumne", height = "300px")),
                
                conditionalPanel(
                  condition = "input.mostrar_comentaris",
                  tags$div(style = "text-align: center;", h4("Comentaris")),
                  tags$div(style = "text-align: center;", h4(textOutput("comentari_alumne"))),


                  # Comentari tipo targeta
                  tags$style(HTML("
                      .card {
                        border: 1px solid #ddd;
                        border-radius: 8px;
                        padding: 20px;
                        box-shadow: 3px 3px 8px rgba(0,0,0,0.1);
                        width: 100%; 
                        max-width: 100%;  
                      }
                      .card img {
                        width: 100px;  
                        height: 100px;
                        border-radius: 50%;
                        margin-bottom: 20px; 
                      }
                    ")),
                div(class = "card",
                    img(src = "https://www.w3schools.com/w3images/avatar2.png"),
                    textOutput("comentari_alumne") )
                )
                
        ),
        
        
        tabPanel("📚 Per Assignatura",
                 # Pestaña que analitza dades per assignatura.
                 
                 # Controles específicos para la pestaña "Per Assignatura".
                 conditionalPanel(
                   condition = "input.tabsetPanel == '📚 Per Assignatura'",
                   # Se activa solo si la pestaña seleccionada es "Per Assignatura".
                   fluidRow(
                     column(2, actionButton("prev_assignatura", "<", class = "btn-primary")),
                     # Botón para navegar a la asignatura anterior.
                     column(8, selectInput("assignatura", "Assignatura", choices = NULL)),
                     # Menú desplegable para seleccionar una asignatura. Las opciones se cargan dinámicamente.
                     column(2, actionButton("next_assignatura", ">", class = "btn-primary"))
                     # Botón para navegar a la siguiente asignatura.
                   )
                 ),
                 
                 # Títol amb nom de l'assignatura. ÇÇÇ
                 tags$div(style = "text-align: center;", h3(textOutput("titol_assignatura"))),                 
                 withSpinner(
                   fluidRow(
                     column(6, plotOutput("graf_assignatura_bar")),
                     # Gràfic de barres per assignatura.
                     column(6, plotOutput("graf_assignatura_pie"))
                     # Gràfic circular per assignatura.                     
                   )
                 ),
                 # Nova fila per al nou gràfic
                 fluidRow(                   
                   column(12, plotOutput("graf_assig_resum"))
                   # Gràfic de bombolles per assignatura.
                 ),
                 
                 # Afegir taula per assignatura
                 gt_output("taula_assignatura")
                 # Taula amb les notes dels alumnes per assignatura.
                 
        ),
        
        
       
        
        
        tabPanel("🌍  Global Assignatures",
                 withSpinner(plotOutput("graf_global_1", height = "400px")),                
                 withSpinner(plotOutput("graf_global_2", height = "400px")),                
                 withSpinner(plotOutput("graf_global_3", height = "400px")),                
                 withSpinner(plotOutput("graf_global_4", height = "400px")),                                 
        ),        
        
        
      )
    )
  )
)





# Server ----------------------------------------------------------------------
server <- function(input, output, session) {
  
  #Probes
  observeEvent(input$boton, {
    
  })
  
  
  
  # -->CAMBIAR EN SHINY DEPLYMENT<--
  # Observar el clic en el actionLink
  observeEvent(input$click_izquierda, {
    # URL que quieres abrir
    url <- "https://github.com/josepACTG/Notes_ESO_auto"  # Cambia esto por la URL que desees
    browseURL(url)  # Abre la URL en el navegador
  })

  
  # #Quan es clica a l'imatge de l'esquerra, apareix panell advertint:
  # observeEvent(input$click_izquierda, {
  #   showNotification("Has hecho clic en la imagen de la izquierda 📌", type = "message")
  #   #Posar que entri a una web?
  # })

  
  
  
  # -->CAMBIAR EN SHINY DEPLYMENT<--
  # Observar el clic en el botón para descargar archivo
  observeEvent(input$abrir_web_1, {
    # URL que quieres abrir
    url <- "https://github.com/josepACTG/Notes_ESO_auto/raw/refs/heads/main/Notes_exemple/Notes_alumnes_1.xlsx"  # Cambia esto por la URL que desees
    browseURL(url)  # Abre la URL en el navegador
  })

  # Observar el clic en el botón para descargar archivo
  observeEvent(input$abrir_web_2, {
    # URL que quieres abrir
    url <- "https://github.com/josepACTG/Notes_ESO_auto/raw/refs/heads/main/Notes_exemple/Notes_alumnes_2.xlsx"  # Cambia esto por la URL que desees
    browseURL(url)  # Abre la URL en el navegador
  })

  
  

  # Valors reactius amb validació ---------------------------------------------
  dades_reactives <- reactiveValues()


  # Comprova si les dades estan carregades
  output$dades_carregades <- reactive({
    !is.null(dades_reactives$net)
  })
  outputOptions(output, "dades_carregades", suspendWhenHidden = FALSE)




  # Observa l'esdeveniment de pujada de fitxer
  observeEvent(input$fitxer, {


     tryCatch({


       # Validació inicial del fitxer
      if(is.null(input$fitxer) || tools::file_ext(input$fitxer$name) != "xlsx") {

        # Donem missatge d'alerta:
        shinyalert(
          title = "Ep!",
          text = "El fitxer ha de ser en format Excel (.xlsx)",
          type = "Error"
        )
        
        stop("El fitxer ha de ser en format Excel (.xlsx)")
      }



      # ___Lectura, filtre, i validació de dades___
      dades_alumnes_excel <- suppressMessages(read_excel(input$fitxer$datapath))

      # dades_alumnes_excel <- read_excel("D:\\Escritorio\\Notes_Auto_ESO\\Notes_exemple\\Notes_alumnes_2.xlsx") # <- Ordinador casa
      # dades_alumnes_excel <- read_excel("C:\\Users\\jubet\\Desktop\\Notes_Auto_ESO\\Notes alumnes_numeric_3.xlsx") # <- Ordinador petit
      
      
      if(ncol(dades_alumnes_excel) < 2) stop("El fitxer necessita com a mínim 2 columnes")
      #if(any(duplicated(dades_alumnes_excel[[1]]))) stop("Noms d'alumnes duplicats")


      #Mirem si hi ha assignatures vuides, i informem abans que es borrin:
      detectar_assign_vuides(dades_alumnes_excel)

      # Eliminar filas y columnas vacías
      dades_alumnes_excel <- dades_alumnes_excel %>% remove_empty(which = c("rows", "cols"))


      # _Eliminar numeros en primera columna o fila (de vegades hi ha)_
      # Verificar si la primera fila contiene solo números
      primera_fila_numerica <- all(grepl("^[0-9.]+$", na.omit(dades_alumnes_excel[1, ])))

      if (primera_fila_numerica) {
        dades_alumnes_excel <- dades_alumnes_excel[-1, ]  # Eliminar la primera fila
        }

      # Verificar si la primera columna contiene solo números
      primera_columna_numerica <- all(grepl("^[0-9.]+$", na.omit(dades_alumnes_excel[[1]])))

      if (primera_columna_numerica) {
        dades_alumnes_excel <- dades_alumnes_excel[,-1 ]  # Eliminar la primera fila
      }


      #_Treiem files i columnes vuides_
      dades_alumnes_excel <- dades_alumnes_excel %>%
        remove_empty(which = c("rows", "cols"))



      # Convertir les dades a dataframe i assignar noms d'alumnes com a rownames
      dades_alumnes <- as.data.frame(dades_alumnes_excel)
      rownames(dades_alumnes) <- dades_alumnes[[1]]
      dades_alumnes[[1]] <- NULL

      
      #Assignem "SQ" (sense qualificació) a valors de sense dades ('NA')
      detectar_valors_SQ(dades_alumnes)
      
      dades_alumnes[dades_alumnes == "SQ"] = NA
      
      
  
      
      
      
      #Comentaris
      # Si hi ha comentaris (última columna), els guarda en variable i es borra del principal.
      if (input$mostrar_comentaris){
        
        print("HI HA COMENTARIS")

        
        # Guardem la última columna (comentaris)
        dades_reactives$comentaris <- dades_alumnes[,ncol(dades_alumnes), drop = FALSE]        #drop = FALSE és per a no perdre els noms de les files.
        # dades_alumnes_comentaris  <- dades_alumnes[,ncol(dades_alumnes), drop = FALSE]

        # Eliminem l'últmia columna (comentaris)
        dades_alumnes <- dades_alumnes[, -ncol(dades_alumnes)]  # Eliminar la columna de comentarios
        
      }
      
      
      
      
      # _Posem en majúscula totes les notes_
      dades_alumnes <- dades_alumnes %>%
        mutate_all(toupper)


      
      
      #Fins aqui tenim el df dades_alumnes sencer.
      #A partir d'ara treurem comentaris, i comprovarem que les notes siguin correctes.
      



      
      
      # __Assignació de dades (numèric i assoliment)__

      #Analitzem cada valor del df i mirem si les dades en total son numèriques, caràcters, o bé barrejades (el que vol dir que és error)
      # Llavors assignem a les variables reactives principals (dades_reactives$net i dades_reactives$net_numeric <-> dades_alumnes i dades_alumnes_numeric)
      
      #funció per a determinar tipologia del df:
      tipus_dades <- barrejat_df_comprovar(dades_alumnes)
      

      # Determinació i assignació segons tipus de dades:
      if (tipus_dades == "tot_barrejat"){
        #Si les dades són barrejades entr caràcters i numèrics (error)
        print("Tipu de dades: barrejades. S'han de modificar")
        
        #Missatge d'error:
        shinyalert(
          title = "¡Error!",
          text = "Dades numèriques i alfabètiques barrejades. Sisplau, comprova les dades ",
          type = "error"
        )

        stop("Error Carregar dades 1: Dades incorrectes")
        
        
      } else if (tipus_dades == "tot_numeric"){
        # si totes les dades són numèriques (o potencialment numèriques)
        print("Tipu de dades: numèriques")
        
        # numeric_df_comprovar(dades_alumnes)

        #Si completament totes les dade són numèriques:
        
        #Mirem si les columnes continuen sent assignades com a caràcter, canviem a numèric:
        if (all(sapply(dades_alumnes, is.character))) {
          dades_alumnes[] <- lapply(dades_alumnes, as.numeric)
        }

        
        # __Assignació de dades__
        dades_reactives$net <- convertir_notas(dades_alumnes) #Convertim a assoliment
        dades_reactives$net_numeric <- dades_alumnes # numèric es la que ja tenim
        
        dades_alumnes_numeric <- dades_alumnes #les que ja tenim
        dades_alumnes <- convertir_notas(dades_alumnes) #convertim a assoliment
        
        
        
      } else if ( tipus_dades == "tot_caracters" ){
        print("Tipu de dades: caràcters")
        # Si les dades són en assoliments (NA, AS, AN, AE) [caràcters]

        # _Anàlisi prèvi comprovatiu_
        detectar_valors_erronis(dades_alumnes) #<- comprovem si hi ha un valor que no sigui NA, AS, AN, AE.

        # __Assignació de dades__
        dades_reactives$net <- dades_alumnes #Les que ja tenim (assolimnet)
        dades_reactives$net_numeric <- convertir_a_numerico(dades_alumnes) #Convertim a numeric

        dades_alumnes <- dades_alumnes #les que ja tenim
        dades_alumnes_numeric <- convertir_a_numerico(dades_alumnes) #convertim a numèric

      }
      
      
      else {
        # Dades barrejades numèric i assoliment: Donem missatge d'error
        print("Error inesperat")

        shinyalert(
          title = "¡Error!",
          text = "Error inesperat. Sisplau, revisa la uniformitat de les dades.",
          type = "error"
        )

        stop("Error Carregar dades 1: Dades incorrectes")
      }






      # ____Modificació permanent de dades___

      # _  dades_reactives$notes_numeric_compendi  _ #

      # alumne nota  assignatura colores
      # 1   Goku  7.5       Català #b0d50c
      # 2   Goku  9.0     Castellà #00c03f
      # 3   Goku  7.5       Anglès #b0d50c
      # 4   Goku  7.5   Tecnologia #b0d50c
      # 5   Goku  9.0     Biologia #00c03f
      # 6   Goku  7.5 Matemàtiques #b0d50c

      notes_numeric_compendi <- data.frame(alumne = character(), nota = numeric(), assignatura = character(), colores = character())

      # Per a cada alumne (fila)
      for (n_alumne in 1:nrow(dades_alumnes_numeric)){
        # Per cada assignatura (columna)
        for (n_assign in 1:ncol(dades_alumnes_numeric)){
          nota_t <- dades_alumnes_numeric[n_alumne, n_assign] #Nota
          assignatura_t <- colnames(dades_alumnes_numeric)[n_assign]
          alumne_t <- rownames(dades_alumnes_numeric)[n_alumne]
          color_t <- ifelse(nota_t <= 4, "#f9011c",    # Rojo para notas bajas
                            ifelse(nota_t <= 6, "#ffd82f",    # Amarillo para medias bajas
                                   ifelse(nota_t <= 8, "#b0d50c",    # Verde claro para medias medias
                                          "#00c03f")))

          notes_numeric_compendi <- rbind(notes_numeric_compendi,
                                          data.frame(alumne = alumne_t,
                                                     nota = nota_t,
                                                     assignatura = assignatura_t,
                                                     colores = color_t))
        }
      }


      # #Treiem les files que tenen NA.
      # notes_numeric_compendi <- notes_numeric_compendi[!is.na(notes_numeric_compendi$nota),]

      dades_reactives$net_compendi <- notes_numeric_compendi






      # _  dades_reactives$notes_numeric_mean_compendi  _

      # alumne nota colores
      # Goku       Goku 8.10 #00c03f
      # Gohan     Gohan 8.25 #00c03f
      # Vegeta   Vegeta 4.50 #ffd82f
      # Piccolo Piccolo 5.00 #ffd82f
      # Krillin Krillin 4.25 #ffd82f
      # Yamcha   Yamcha 5.05 #ffd82f


      #Obtenim llista de dades de les notes en numèric.

      notes_numeric_mean_compendi <- data.frame(alumne = character(), nota = numeric(), assignatura = character(), colores = character())



      notes_numeric_means <- rowMeans(dades_alumnes_numeric, na.rm = TRUE) # Si hi ha NA s'obvien

      # Per a cada alumne (fila)
      for (n_alumne in 1:length(notes_numeric_means)){
        # Per cada assignatura (columna)
        nota_t <- notes_numeric_means[n_alumne] #Nota
        alumne_t <- names(notes_numeric_means)[n_alumne]
        color_t <- ifelse(nota_t <= 4, "#f9011c",    # Rojo para notas bajas
                          ifelse(nota_t <= 6, "#ffd82f",    # Amarillo para medias bajas
                                 ifelse(nota_t <= 8, "#b0d50c",    # Verde claro para medias medias
                                        "#00c03f")))

        notes_numeric_mean_compendi <- rbind(notes_numeric_mean_compendi,
                                             data.frame(alumne = alumne_t,
                                                        nota = nota_t,
                                                        colores = color_t))
      }

      dades_reactives$net_compendi_means <- notes_numeric_mean_compendi






      # Validació de notes
      # validar_notes(dades_alumnes)


      # Actualització reactiva dels selectInputs
      updateSelectInput(session, "assignatura", choices = colnames(dades_alumnes))
      updateSelectInput(session, "alumne", choices = rownames(dades_alumnes))

      # Emmagatzemar dades
      dades_reactives$brut <- dades_alumnes_excel




    },
    error = function(e) {
      # Mostra una notificació d'error si hi ha algun problema
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
      dades_reactives$net <- NULL
    }
    )


  })




    
  
  
  
  # Navegació entre assignatures ----------------------------------------------
  observeEvent(input$prev_assignatura, {
    current <- which(colnames(dades_reactives$net) == input$assignatura)
    if (current > 1) {
      updateSelectInput(session, "assignatura", selected = colnames(dades_reactives$net)[current - 1])
    }
  })
  
  observeEvent(input$next_assignatura, {
    current <- which(colnames(dades_reactives$net) == input$assignatura)
    if (current < ncol(dades_reactives$net)) {
      updateSelectInput(session, "assignatura", selected = colnames(dades_reactives$net)[current + 1])
    }
  })
  
  

  # Navegació entre alumnes ---------------------------------------------------
  observeEvent(input$prev_alumne, {
    current <- which(rownames(dades_reactives$net) == input$alumne)
    if (current > 1) {
      updateSelectInput(session, "alumne", selected = rownames(dades_reactives$net)[current - 1])
    }
  })

  observeEvent(input$next_alumne, {
    current <- which(rownames(dades_reactives$net) == input$alumne)
    if (current < nrow(dades_reactives$net)) {
      updateSelectInput(session, "alumne", selected = rownames(dades_reactives$net)[current + 1])
    }
  })


  
  
  
  
  
  #Navegació entre opcins grafics Global Assignatures
  
  # Lógica para la flecha izquierda
  observeEvent(input$flecha_izquierda, {
    opciones <- c("suspensos", "an_ae", "ae")
    indice_actual <- which(opciones == input$grupo_graficos)
    nuevo_indice <- ifelse(indice_actual == 1, length(opciones), indice_actual - 1)
    updateSelectInput(session, "grupo_graficos", selected = opciones[nuevo_indice])
  })
  
  # Lógica para la flecha derecha
  observeEvent(input$flecha_derecha, {
    opciones <- c("suspensos", "an_ae", "ae")
    indice_actual <- which(opciones == input$grupo_graficos)
    nuevo_indice <- ifelse(indice_actual == length(opciones), 1, indice_actual + 1)
    updateSelectInput(session, "grupo_graficos", selected = opciones[nuevo_indice])
  })
  
  # 
  # Lógica para descargar el archivo de ejemplo
  



  
  
  
  
  
  # Visualització per assignatura --------------------------------------------
  observe({
    req(input$assignatura)
    tryCatch({
      
      # Títol de l'assignatura
      output$titol_assignatura <- renderText({
        req(input$assignatura)  # Asegúrate de que se haya seleccionado un alumno
        paste("Anàlisi de l'assignatura:", input$assignatura)  # Muestra el nombre del alumno seleccionado
      }) 
      
      # Gràfic de barres per assignatura
      output$graf_assignatura_bar <- renderPlot({
        taula <- table(dades_reactives$net[[input$assignatura]])
        # taula <- table(dades_alumnes[[1]]) # Probes
        
        # Gràfic de barres amb els colors
        barres <- barplot(
          taula[c("NA", "AS", "AN", "AE")],
          col = c("#f9011c", "#ffd82f", "#b0d50c", "#00c03f"),
          main = paste("Distribució -", input$assignatura),
          ylab = "Nombre d'alumnes",
          ylim = c(0, max(taula) + 1),
          xaxt = "n"  # Amagar les etiquetes de l'eix X per afegir-les manualment
        )
        
        # Afegir les etiquetes de l'eix X (les notes)
        axis(1, at = barres, labels = c("NA", "AS", "AN", "AE"))
        
        # Afegir els valors absoluts a sobre de cada barra
        text(
          x = barres,
          y = taula[c("NA", "AS", "AN", "AE")] + 0.7,  # Posar els valors una mica més amunt
          labels = taula[c("NA", "AS", "AN", "AE")],
          col = "black",
          cex = 1,
          font = 2
        )
      })
      
      
      # Gràfic circular (pie) per assignatura
      output$graf_assignatura_pie <- renderPlot({
        taula <- table(dades_reactives$net[[input$assignatura]])
        
        # Filtrar els valors no nuls (per evitar mostrar "0%")
        valors_valids <- taula[c("NA", "AS", "AN", "AE")]
        
        # Definir els colors associats a les categories (NA, AS, AN, AE)
        colors <- c("NA" = "#f9011c",  # Vermell
                    "AS" = "#ffd82f",  # Groc
                    "AN" = "#b0d50c",  # Verd clar
                    "AE" = "#00c03f")  # Verd fosc
        
        # Crear el gràfic circular
        pie(
          valors_valids,
          col = colors,  # Assignar els colors correctes
          main = paste("Proporcions -", input$assignatura)
        )
        
        # Calcular els percentatges per cada categoria
        percentatges <- round(prop.table(valors_valids) * 100)
        
        # Calcular les coordenades per posar els textos de percentatge
        angulos <- cumsum(valors_valids) - valors_valids / 2  # Angles centrals
        angulos_rad <- angulos * (2 * pi) / sum(valors_valids)  # Convertir a radians
        radio <- 0.6  # Radi per col·locar els textos
        x <- radio * cos(angulos_rad)
        y <- radio * sin(angulos_rad)
        
        # Afegir els percentatges a les seccions del gràfic
        text(x, y, labels = paste0(percentatges, "%"), col = "black", cex = 1)
      })
      
      
      
      
      
      # Gràfic de bombolles per assignatura amb les notes dels alumnes
      output$graf_assig_resum <- renderPlot({
        req(input$assignatura)  # Assegura que s'ha seleccionat una assignatura
        
        # Obtenir les notes dels alumnes per a l'assignatura seleccionada
        notes_assignatura <- dades_reactives$net[, input$assignatura]
        
        # Crear la taula de freqüències de les notes per a l'assignatura
        taula_conjunt_trans <- table(factor(unlist(notes_assignatura), levels = c("NA", "AS", "AN", "AE")))
        
        # Ordenar la taula segons l'ordre desitjat
        notes_assignatura_ordenades <- ordenar_tabla(taula_conjunt_trans, c("NA", "AS", "AN", "AE"))
        
        # Preparar les dades per al gràfic
        linia_valors_x <- c()
        linia_valors_y <- c()
        linia_valors_col <- c()
        noms_alumnes <- c()  # Llistat dels noms dels alumnes per a cada bombolla
        
        for (val_taula in 1:length(notes_assignatura_ordenades)) {
          valor <- as.numeric(notes_assignatura_ordenades[val_taula])  # Obtenir el valor (número d'alumnes amb aquesta nota)
          tipus_nota <- names(notes_assignatura_ordenades)[val_taula]  # Tipus de nota (NA, AS, AN, AE)
          
          # Validar que el valor no sigui 0 i afegir coordenades i colors per a cada bombolla
          if (valor != 0) {
            linia_valors_x <- c(linia_valors_x, rep(val_taula, valor))
            linia_valors_y <- c(linia_valors_y, 1:valor)
            linia_valors_col <- c(linia_valors_col, rep(determina_color_nota(tipus_nota), valor))
            
            # Obtenir els alumnes associats a cada nota i afegir-los als noms
            alumnes_assignatura <- obtenir_alumnes(dades_reactives$net, input$assignatura)
            alumnes_nom <- alumnes_assignatura$notes_totals  # Llistat dels noms dels alumnes per la assignatura
            
            # Afegir els noms dels alumnes a la llista
            noms_alumnes <- c(noms_alumnes, alumnes_nom[(length(noms_alumnes) + 1):(length(noms_alumnes) + valor)])
          }
        }
        
        # Generar el gràfic de símbols (bombolles)
        symbols(linia_valors_x, linia_valors_y, circles = rep(0.1, length(linia_valors_y)), inches = FALSE,
                main = paste("Resum notes de la assignatura", input$assignatura), 
                bg = linia_valors_col, xlim = c(0.5, 4.5), ylim = c(0, max(linia_valors_y) + 1),
                xaxt = "n", xlab = "", ylab = "Nº alumnes")
        
        # Afegir l'eix X amb les etiquetes de les notes
        axis(1, at = c(1, 2, 3, 4), labels = c("NA", "AS", "AN", "AE"))
        
        # Afegir els noms dels alumnes (text)
        text(linia_valors_x + 0.1, linia_valors_y, labels = noms_alumnes, pos = 4, col = "white", cex = 0.9, offset = 0.5)
        text(linia_valors_x + 0.1, linia_valors_y, labels = noms_alumnes, pos = 4, col = "black", cex = 0.8, offset = 0.5)
      })
      
      
      
      # Taula de notes per assignatura amb percentatge i ordenació personalitzada
      output$taula_assignatura <- render_gt({
        # Crear la taula de freqüències de les notes de l'assignatura seleccionada
        taula <- as.data.frame(table(factor(unlist(dades_reactives$net[[input$assignatura]]), 
                                            levels = c("AE", "AN", "AS", "NA"))))
        
        # Calcular percentatges
        taula$Percentatge <- paste0(round(prop.table(taula$Freq) * 100), "%")
        
        # Renombrar les columnes per una millor presentació
        colnames(taula) <- c("Assoliment", "Freqüència", "Percentatge")
        
        
        # Crear la taula amb gt
        gt(taula) %>% 
          tab_header(title = paste("Detall per assoliment: ", input$assignatura)) %>%  # Títol de la taula
          data_color(
            columns = "Assoliment",
            colors = scales::col_factor(
              palette = c("#00c03f", "#b0d50c", "#ffd82f", "#f9011c"),  # Colors per a les notes: AE = verd fosc, AN = verd clar, AS = groc, NA = vermell
              domain = c("AE", "AN", "AS", "NA")
            )
          ) 
        
      })
      
      
      
      # Gràfic de barres per assignatura amb l'ordre personalitzat
      output$graf_assignatura_bar <- renderPlot({
        taula <- table(factor(dades_reactives$net[[input$assignatura]], levels = c("AE", "AN", "AS", "NA")))
        barres <- barplot(
          taula,
          col = c("#00c03f", "#b0d50c", "#ffd82f", "#f9011c"),
          main = paste("Distribució -", input$assignatura),
          ylab = "Nombre d'alumnes",
          ylim = c(0, max(taula) + 1)
        )
        # Afegir els valors absoluts al gràfic de barres
        text(
          x = barres,
          y = taula + 0.7,
          labels = taula,
          col = "black",
          cex = 1,
          font = 2
        )
      })
      
      
      
      # Gràfic circular (pie) per assignatura amb l'ordre personalitzat
      output$graf_assignatura_pie <- renderPlot({
        taula <- table(factor(dades_reactives$net[[input$assignatura]], levels = c("AE", "AN", "AS", "NA")))
        
        # Filtrar valors no nuls per evitar mostrar "0%"
        valors_valids <- taula[taula > 0]
        
        # Definir els colors associats a les categories (NA, AS, AN, AE)
        colors <- c("AE" = "#00c03f",  # Verd fosc
                    "AN" = "#b0d50c",  # Verd clar
                    "AS" = "#ffd82f",  # Groc
                    "NA" = "#f9011c")  # Vermell
        
        # Assignar els colors correctes a les categories no nules
        colors_valids <- colors[names(valors_valids)]
        
        # Crear el gràfic circular només amb els valors vàlids
        pie(
          valors_valids,
          col = colors_valids,  # Assignar els colors correctes
          main = paste("Proporcions -", input$assignatura)
        )
        
        # Calcular els percentatges i les coordenades dels textos
        angulos <- cumsum(valors_valids) - valors_valids / 2  # Angles centrals de cada secció
        angulos_rad <- angulos * (2 * pi) / sum(valors_valids)  # Convertir a radians
        radio <- 0.6  # Radi per col·locar els textos
        x <- radio * cos(angulos_rad)
        y <- radio * sin(angulos_rad)
        
        # Textos amb percentatges
        noms_pie <- paste0(round(prop.table(valors_valids) * 100), "%")
        
        # Afegir el text amb percentatges
        text(x, y, noms_pie, col = "black", cex = 1)
      })
      
      
      
      
      
    }, error = function(e) {
      showNotification("Error en processar assignatura", type = "warning")
    })
  })
  
  
  
  
  
  
  
  
  
  
  
  
  # Visualització per alumne -------------------------------------------------
  observe({
    req(input$alumne)
    tryCatch({
      # Obtenim les notes de l'alumne seleccionat
      notes_alumne <- reactive({
        dades_reactives$net[input$alumne, ]
      })
      
      
      output$titulo_alumne <- renderText({
        req(input$alumne)  # Asegúrate de que se haya seleccionado un alumno
        paste("Anàlisi de l'alumne:", input$alumne)  # Muestra el nombre del alumno seleccionado
      })
      
      
      
      # Gràfic de barres per alumne (amb freqüències absolutes)
      output$graf_alumne_bar <- renderPlot({
        taula <- table(factor(unlist(notes_alumne()), levels = c("NA", "AS", "AN", "AE")))
        barres <- barplot(
          taula,
          col = c("#f9011c", "#ffd82f", "#b0d50c", "#00c03f"),
          main = paste("Notes de", input$alumne),
          ylab = "Nombre d'alumnes",
          ylim = c(0, max(taula) + 1)
        )
        # Afegir els valors absoluts al gràfic de barres
        text(
          x = barres,
          y = taula + 0.7,
          labels = taula,
          col = "black",
          cex = 1,
          font = 2
        )
      })
      
      
      
      # Gràfic circular (pie) per alumne amb percentatges i sense mostrar valors del 0%
      output$graf_alumne_pie <- renderPlot({
        taula <- table(factor(unlist(notes_alumne()), levels = c("NA", "AS", "AN", "AE")))
        
        # Filtrar valors no nuls per evitar mostrar "0%"
        valors_valids <- taula[taula > 0]
        
        # Definir els colors associats a les categories (NA, AS, AN, AE)
        colors <- c("NA" = "#f9011c",  # Vermell
                    "AS" = "#ffd82f",  # Groc
                    "AN" = "#b0d50c",  # Verd clar
                    "AE" = "#00c03f")  # Verd fosc
        
        # Assignar els colors correctes a les categories no nules
        colors_valids <- colors[names(valors_valids)]
        
        # Crear el gràfic circular només amb els valors vàlids
        pie(
          valors_valids,
          col = colors_valids,  # Assignar els colors correctes
          main = paste("Proporcions de", input$alumne)
        )
        
        # Calcular els percentatges i les coordenades dels textos
        angulos <- cumsum(valors_valids) - valors_valids / 2  # Angles centrals de cada secció
        angulos_rad <- angulos * (2 * pi) / sum(valors_valids)  # Convertir a radians
        radio <- 0.6  # Radi per col·locar els textos
        x <- radio * cos(angulos_rad)
        y <- radio * sin(angulos_rad)
        
        # Textos amb percentatges
        noms_pie <- paste0(round(prop.table(valors_valids) * 100), "%")
        
        # Calcular una mida de text relativa en funció de les proporcions
        # Per exemple, la mida del text serà més petita quan el valor sigui petit
        text_size <- 1 / max(1, sum(valors_valids) / 100)  # Ajustar la mida depenent del total de valors
        
        # Afegir el text amb percentatges
        text(x, y, noms_pie, col = "black", cex = text_size)
      })
      
      
      
      
      # Taula de notes per alumne amb percentatge
      output$taula_alumne <- render_gt({
        # Crear la taula de freqüències
        taula <- as.data.frame(table(factor(unlist(notes_alumne()), levels = c("AE", "AN", "AS", "NA"))))
        
        # Calcular percentatges
        taula$Percentatge <- paste0(round(prop.table(taula$Freq) * 100), "%")
        
        # Renombrar les columnes
        colnames(taula) <- c("Assoliment", "Freqüència", "Percentatge")
        
        # Crear la taula amb gt
        gt(taula) %>% 
          tab_header(title = "Detall per assoliment: ") %>%
          data_color(
            columns = "Assoliment",
            colors = scales::col_factor(
              palette = c("#00c03f", "#b0d50c", "#ffd82f", "#f9011c"),
              domain = NULL
            )
          )
      })
      
      

      
      # Gràfic de bombolles mostra nom d'assignatures
      output$graf_alumne_resum <- renderPlot({
        req(input$alumne)  # Assegura que s'ha seleccionat un alumne
        
        # Obtenir les notes de l'alumne seleccionat
        notes_alumne <- dades_reactives$net[input$alumne, ]
        
        # Crear la taula de freqüències
        taula_conjunt_trans <- table(factor(unlist(notes_alumne), levels = c("NA", "AS", "AN", "AE")))
        
        # Ordenar la taula segons l'ordre desitjat
        notes_alumnes <- ordenar_tabla(taula_conjunt_trans, c("NA", "AS", "AN", "AE"))
        
        # Preparar les dades per al gràfic
        linia_valors_x <- c()
        linia_valors_y <- c()
        linia_valors_col <- c()
        
        for (val_taula in 1:length(notes_alumnes)) {
          valor <- as.numeric(notes_alumnes[val_taula])
          tipus_nota <- names(notes_alumnes)[val_taula]
          
          if (valor != 0) {
            linia_valors_x <- c(linia_valors_x, rep(val_taula, valor))
            linia_valors_y <- c(linia_valors_y, 1:valor)
            linia_valors_col <- c(linia_valors_col, rep(determina_color_nota(tipus_nota), valor))
          }
        }
        
        # Generar el gràfic de símbols
        symbols(linia_valors_x, linia_valors_y, circles = rep(0.1, length(linia_valors_y)), inches = FALSE,
                main = paste("Resum notes ", input$alumne), bg = linia_valors_col, xlim = c(0.5, 4.5), ylim = c(0, max(linia_valors_y) + 1),
                xaxt = "n", xlab = "", ylab = "Nº")
        
        # Afegir l'eix X amb les etiquetes de les notes
        axis(1, at = c(1, 2, 3, 4), labels = c("NA", "AS", "AN", "AE"))
        
        # Afegir el nom de les assignatures
        assignatures_alumne <- obtenir_assignatures(dades_reactives$net, input$alumne)
        assig_tot <- assignatures_alumne$notes_totals
        
        # Calcular una mida de text relativa
        # Per exemple, utilitzar la longitud de les assignatures per determinar la grandària del text
        text_size <- 1 / max(1, length(assig_tot) / 10)  # Ajustar la grandària depenent del nombre d'assignatures
        
        # Afegir el text de les assignatures al gràfic
        text(linia_valors_x + 0.1, linia_valors_y, labels = assig_tot, pos = 4, col = "white", cex = text_size * 1.2, offset = 0.5)
        text(linia_valors_x + 0.1, linia_valors_y, labels = assig_tot, pos = 4, col = "black", cex = text_size, offset = 0.5)
      })
      
      

      output$graf_radar_alumne <- renderPlot({

        req(input$alumne)  # Asegura que se ha seleccionado un alumno
        req(dades_reactives$net_numeric)
        
        
        # Función para generar un gradiente de colores        
        my_gradient <- function(n) {
          colors <- colorRampPalette(c("blue", "red"))(n)
          return(colors)
        }
        

        
        dades_alumnes_numeric <- dades_reactives$net_numeric
        
        # Obtener las notas del alumno seleccionado
        data_alumne <- dades_alumnes_numeric[input$alumne, , drop = FALSE]
        
        # Crear el gráfico de radar
        radarchart(rbind(rep(10, ncol(data_alumne)), rep(0, ncol(data_alumne)), data_alumne),
                   pcol = my_gradient(1), 
                   pfcol = scales::alpha(my_gradient(1), 0.5), 
                   plwd = 2, 
                   cglcol = "grey", 
                   cglty = 1, 
                   axislabcol = "grey", 
                   caxislabels = seq(0, 10, 2.5), 
                   title = paste("Notes de", as.character(input$alumne))
        )
      })
      
      
      
      # Mostrar el comentario del alumno seleccionado
      output$comentari_alumne <- renderText({
        req(input$alumne)  # Asegura que se haya seleccionado un alumno
        if (input$mostrar_comentaris) {
 
          alumne_seleccionat <- input$alumne
          comentari <- dades_reactives$comentaris[rownames(dades_reactives$comentaris) == alumne_seleccionat,]
          
          if (!is.na(comentari)){
            comentari <- as.character(comentari)  # Convertir a texto si es necesario
          comentari <- paste(comentari,"\n\n\n\n\n", sep = "")
          }
          else {
            comentari <- "--no hi ha comentaris de l'alumne--"
          }
          return(comentari)
        } else {
          return(NULL)
        } 
        })      
      
      
      
      
      
      
    }, error = function(e) {
      showNotification("Error en processar dades de l'alumne", type = "warning")
    })
  })
  
  
  
  
  
  
  
  
  
  
  
  # Visualització de Global alumnes -------------------------------------------
  
  
  
  
  
  # Gràfic distribucións 1:
  output$grafic_densitats_1 <- renderPlotly({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    tryCatch({
      
      # Obtenim dades:
      notes_numeric_mean_compendi <- dades_reactives$net_compendi_means 
      
      
      # Gráfico
      p <- suppressWarnings(
        ggplot(notes_numeric_mean_compendi, aes(x = "", y = nota)) +
        geom_violin(fill = "lightblue", alpha = 0.5) +
        # geom_jitter(aes(color = colores, text = alumne), width = 0.2, size = 2) +
        geom_jitter(aes(color = colores, text = paste("Alumne: ", alumne, "<br>Nota: ", round(nota, 2) )), width = 0.2, size = 2) +
        scale_color_manual( values = c("#f9011c" = "#f9011c", "#ffd82f" = "#ffd82f", "#b0d50c" = "#b0d50c", "#00c03f" = "#00c03f" )) + 
        guides(color = "none") +
        #scale_color_manual(values = c("A" = "red", "B" = "blue", "C" = "green")) +
        theme_minimal() )
      
      # Hacerlo interactivo
      ggplotly(p, tooltip = "text")
      
      
      
      
      
    }, error = function(e) {
      showNotification("Error en generar el gráfico de distribucin.", type = "warning")
    })
  })  
  
  
  
  
  # Gráfico circular de suspensos
  output$grafico_circular_suspensos <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas suspendidas por alumno
      contar_suspensos <- function(dades_alumnes) {
        # Contar cuántas veces aparece "NA" en cada fila (alumno)
        suspensos <- apply(dades_alumnes, 1, function(x) sum(x == "NA", na.rm = TRUE))
        return(suspensos)
      }
      
      # Calcular el número de suspensos por alumno
      suspensos_por_alumno <- contar_suspensos(dades_reactives$net)
      
      
      # Crear una tabla de frecuencias de suspensos
      tabla_suspensos <- table(suspensos_por_alumno)
      
      # Convertir la tabla a un dataframe para facilitar el manejo
      df_suspensos <- as.data.frame(tabla_suspensos)
      colnames(df_suspensos) <- c("Suspensos", "Frecuencia")
      
      # Calcular el porcentaje de alumnos para cada número de suspensos
      df_suspensos$Porcentaje <- round(df_suspensos$Frecuencia / sum(df_suspensos$Frecuencia) * 100, 2)
      
      # Crear una paleta de colores que vaya de blanco a rojo
      colores <- colorRampPalette(c("white", "red"))(nrow(df_suspensos))
      
      # Crear el gráfico circular
      pie(df_suspensos$Frecuencia,
          labels = paste(df_suspensos$Suspensos, " NA\n", df_suspensos$Frecuencia, " alumnes (", df_suspensos$Porcentaje, "%)", sep = ""),
          col = colores,
          # main = "Distribución de alumnos por número de asignaturas suspendidas",
          cex = 1)
      
    }, error = function(e) {
      showNotification("Error en generar el gráfico circular de suspensos", type = "warning")
    })
  })
  
  
  
  # Gráfico de waffle personalizado con nombres de alumnos y número de suspensos
  output$grafico_waffle_suspensos <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas suspendidas por alumno
      contar_suspensos <- function(dades_alumnes) {
        # Contar cuántas veces aparece "NA" en cada fila (alumno)
        suspensos <- apply(dades_alumnes, 1, function(x) sum(x == "NA", na.rm = TRUE))
        return(suspensos)
      }
      
      # Calcular el número de suspensos por alumno
      suspensos_por_alumno <- contar_suspensos(dades_reactives$net)
      
      # Crear un dataframe con los nombres de los alumnos y sus suspensos
      datos_waffle <- data.frame(
        Alumno = rownames(dades_reactives$net),
        Suspensos = suspensos_por_alumno
      )
      
      # Ordenar el dataframe de menos a más suspensos
      datos_waffle <- datos_waffle[order(datos_waffle$Suspensos), ]
      
      # Añadir el número de suspensos al nombre del alumno
      datos_waffle$Etiqueta <- paste(datos_waffle$Alumno, "(", datos_waffle$Suspensos, ")", sep = "")
      
      # Definir una paleta de colores que varíe de blanco a rojo
      colores <- colorRampPalette(c("#FFFFFF", "#FF0000"))(max(datos_waffle$Suspensos) + 1)
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = Suspensos)) +
        geom_tile(color = "white", size = 0.5) +  # Crear cuadrados
        facet_wrap(~ reorder(Etiqueta, Suspensos), ncol = 5) +  # Ordenar y organizar los cuadrados por alumno
        scale_fill_gradient(low = "#FFFFFF", high = "#FF0000") +  # Paleta de colores
        geom_text(aes(label = Etiqueta), color = "black", size = 5) +  # Añadir nombres de alumnos y suspensos
        theme_void() +  # Eliminar ejes y fondo
        theme(
          strip.text = element_blank(),  # Ocultar títulos de facetas
          legend.position = "bottom"  # Posición de la leyenda
        ) +
        labs(
          title = "Distribución de suspensos por alumno",
          fill = "Número de suspensos"
        )
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de suspensos", type = "warning")
    })
  })
  
  
  
  # Gráfico de waffle para la media de suspensos de toda la clase (más pequeño y con valor debajo)
  output$grafico_waffle_media_suspensos <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas suspendidas por alumno
      contar_suspensos <- function(dades_alumnes) {
        # Contar cuántas veces aparece "NA" en cada fila (alumno)
        suspensos <- apply(dades_alumnes, 1, function(x) sum(x == "NA", na.rm = TRUE))
        return(suspensos)
      }
      
      # Calcular el número de suspensos por alumno
      suspensos_por_alumno <- contar_suspensos(dades_reactives$net)
      
      # Calcular la media de suspensos de toda la clase
      media_suspensos <- mean(suspensos_por_alumno)
      
      # Crear un dataframe con la media de suspensos
      datos_waffle <- data.frame(
        Etiqueta = paste("Mitja de suspèsos"),
        Valor = 1  # Un único cuadrado
      )
      
      # Definir una paleta de colores que varíe de blanco a rojo
      colores <- colorRampPalette(c("#FFFFFF", "#FF0000"))(100)  # 100 tonos de gradiente
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = media_suspensos)) +
        geom_tile(color = "white", size = 2, width = 0.5, height = 0.5) +  # Cuadrado más pequeño
        scale_fill_gradient(low = "#FFFFFF", high = "#FF0000", limits = c(0, max(ncol(dades_reactives$net)))) +  # Paleta de colores
        annotate("text", x = 1, y = 1.2, label = "Mitja de suspèsos", color = "black", size = 4, fontface = "bold") +  # Título
        annotate("text", x = 1, y = 0.8, label = round(media_suspensos, 2), color = "black", size = 5, fontface = "bold") +  # Valor
        theme_void() +  # Eliminar ejes y fondo
        theme(
          legend.position = "none",  # Ocultar la leyenda
          plot.margin = margin(10, 10, 10, 10)  # Ajustar márgenes
        ) +
        coord_fixed(ratio = 1)  # Mantener la proporción del cuadrado
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de la media de suspensos", type = "warning")
    })
  })
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  # 
  # # Visualització de Global Alumnes -------------------------------------------


  # Gráfico de barras interactivo de frecuencias de suspensos
  output$grafico_barras_interactivo_suspensos <- renderPlotly({
    req(dades_reactives$net)  # Asegura que los datos estén cargados

    tryCatch({
      # Función para contar el número de asignaturas suspendidas por alumno
      contar_suspensos <- function(dades_alumnes) {
        # Contar cuántas veces aparece "NA" en cada fila (alumno)
        suspensos <- apply(dades_alumnes, 1, function(x) sum(x == "NA", na.rm = TRUE))
        return(suspensos)
      }

      # Calcular el número de suspensos por alumno
      suspensos_por_alumno <- contar_suspensos(dades_reactives$net)

      # Crear un dataframe con los nombres de los alumnos y sus suspensos
      datos_alumnos <- data.frame(
        Alumno = rownames(dades_reactives$net),
        Suspensos = suspensos_por_alumno
      )

      # Crear una tabla de frecuencias de suspensos
      tabla_suspensos <- table(suspensos_por_alumno)

      # Convertir la tabla a un dataframe para facilitar el manejo
      df_suspensos <- as.data.frame(tabla_suspensos)
      colnames(df_suspensos) <- c("Suspensos", "Frecuencia")

      # Obtener los nombres de los alumnos para cada frecuencia de suspensos
      nombres_por_suspensos <- split(datos_alumnos$Alumno, datos_alumnos$Suspensos)
      df_suspensos$Nombres <- sapply(df_suspensos$Suspensos, function(x) {
        paste(nombres_por_suspensos[[as.character(x)]], collapse = "<br>")  # Usar <br> para saltos de línea en HTML
      })
      


      # Crear una paleta de colores que vaya de blanco a rojo
      colores <- colorRampPalette(c("white", "red"))(nrow(df_suspensos))

      # Crear un gráfico de barras interactivo con plotly
      p <- plot_ly(df_suspensos, x = ~Suspensos, y = ~Frecuencia, type = 'bar',
                   marker = list(color = colores, line = list(color = "black", width = 1.5)),  # Bordes negros
                   text = ~Nombres,  # Mostrar nombres de alumnos en el tooltip
                   hoverinfo = 'text',  # Mostrar solo el texto en el tooltip
                   hoverlabel = list(bgcolor = "white", font = list(size = 12))) %>%
        layout(title = "Distribución de alumnos por número de asignaturas suspendidas",
               xaxis = list(title = "Número de suspensos"),
               yaxis = list(title = "Frecuencia de alumnos"))


      p

    }, error = function(e) {
      showNotification("Error en generar el gráfico de barras interactivo de suspensos", type = "warning")
    })
  })

  output$tabla_suspensos_GT <- render_gt({
    
    req(dades_reactives$net)
    
    tryCatch({
    
    # Función para contar el número de asignaturas suspendidas por alumno
    contar_suspensos <- function(dades_alumnes) {
      # Contar cuántas veces aparece "NA" en cada fila (alumno)
      suspensos <- apply(dades_alumnes, 1, function(x) sum(x == "NA", na.rm = TRUE))
      return(suspensos)
    }
    
    # Calcular el número de suspensos por alumno
    suspensos_por_alumno <- contar_suspensos(dades_reactives$net)
    
    # Crear un dataframe con los nombres de los alumnos y sus suspensos
    datos_alumnos <- data.frame(
      Alumno = rownames(dades_reactives$net),
      Suspensos = suspensos_por_alumno
    )
    
    # Crear una tabla de frecuencias de suspensos
    tabla_suspensos <- table(suspensos_por_alumno)
    
    # Convertir la tabla a un dataframe para facilitar el manejo
    df_suspensos <- as.data.frame(tabla_suspensos)
    colnames(df_suspensos) <- c("Suspensos", "Frecuencia")
    
    # Obtener los nombres de los alumnos para cada frecuencia de suspensos
    nombres_por_suspensos <- split(datos_alumnos$Alumno, datos_alumnos$Suspensos)
    df_suspensos$Nombres <- sapply(df_suspensos$Suspensos, function(x) {
      paste(nombres_por_suspensos[[as.character(x)]], collapse = "<br>")  # Usar <br> para saltos de línea en HTML
    })
    
    df_suspensos$Suspensos <- as.numeric(as.character(df_suspensos$Suspensos))
    
    df_suspensos %>%
      gt() %>%
      tab_header(
        title = "Resumen de Suspensos"
      ) %>%
      cols_label(
        Suspensos = "Número de Suspensos",
        Frecuencia = "Cantidad de Estudiantes",
        Nombres = "Nombres de los Estudiantes"
      ) %>%
      fmt_markdown(columns = c(Nombres)) %>%  # Interpretar HTML en la columna Nombres
      # fmt_markdown(columns = vars(Nombres)) %>%
      data_color(
        columns = c(Suspensos), #vars(Suspensos),  # Aplicar gradiente a ambas columnas numéricas
        colors = scales::col_numeric(
          palette = c("white", "red"),  # De blanco a rojo
          domain = c(0, max(ncol(dades_reactives$net)))  # Los valores de la columna varían de 0 al num de asignaturas.
        )
      ) %>%
      tab_options(
        table.width = "60%",  # Ajustar el ancho de la tabla
        table.font.size = "14px"  # Ajustar el tamaño de la fuente
      )
      # tab_options(
      #   table.width = "100%"
      # )
  
  }, error = function(e) {
    showNotification("Error en generar el gráfico de barras interactivo de suspensos", type = "warning")
  })
    
  
    })
  


  
  
  
  
  
  
  
  # Gráfico circular de notas AN y AE
  output$grafico_circular_an_ae <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas con notas AN y AE por alumno
      contar_an_ae <- function(dades_alumnes) {
        # Contar cuántas veces aparece "AN" o "AE" en cada fila (alumno)
        an_ae <- apply(dades_alumnes, 1, function(x) sum(x %in% c("AN", "AE")))
        return(an_ae)
      }
      
      # Calcular el número de notas AN y AE por alumno
      an_ae_por_alumno <- contar_an_ae(dades_reactives$net)
      
      # Crear una tabla de frecuencias de notas AN y AE
      tabla_an_ae <- table(an_ae_por_alumno)
      
      # Convertir la tabla a un dataframe para facilitar el manejo
      df_an_ae <- as.data.frame(tabla_an_ae)
      colnames(df_an_ae) <- c("AN_AE", "Frecuencia")
      
      # Calcular el porcentaje de alumnos para cada número de notas AN y AE
      df_an_ae$Porcentaje <- round(df_an_ae$Frecuencia / sum(df_an_ae$Frecuencia) * 100, 2)
      
      # Crear una paleta de colores que vaya de blanco a verde
      colores <- colorRampPalette(c("white", "green"))(nrow(df_an_ae))
      
      
      # Crear el gráfico circular
      pie(df_an_ae$Frecuencia,
          labels = paste(df_an_ae$AN_AE, " AN+AE\n", df_an_ae$Frecuencia, " alumnes (", df_an_ae$Porcentaje, "%)", sep = ""),
          col = colores,
          # main = "Distribución de alumnos por número de notas AN y AE",
          cex = 1)
    }, error = function(e) {
      showNotification("Error en generar el gráfico circular de notas AN y AE", type = "warning")
    })
  })
  
  
  
  
  output$tabla_an_ae_GT <- render_gt({
    
    req(dades_reactives$net)
    
    tryCatch({
    
    # Contar las ocurrencias de "AN" y "AE" por alumno
    an_ae_por_alumno <- apply(dades_reactives$net, 1, function(x) sum(x %in% c("AN", "AE"), na.rm = TRUE))
    
    # Crear un dataframe con los nombres de los alumnos y sus ocurrencias de "AN" y "AE"
    datos_alumnos_an_ae <- data.frame(
      Alumno = rownames(dades_reactives$net),
      AN_AE = an_ae_por_alumno
    )
    
    # Crear una tabla de frecuencias de ocurrencias de "AN" y "AE"
    tabla_an_ae <- table(an_ae_por_alumno)
    
    # Convertir la tabla a un dataframe para facilitar el manejo
    df_an_ae <- as.data.frame(tabla_an_ae)
    colnames(df_an_ae) <- c("AN_AE", "Frecuencia")
    df_an_ae$AN_AE <- suppressWarnings(as.numeric(as.character(df_an_ae$AN_AE)))
    
    # Obtener los nombres de los alumnos para cada frecuencia de "AN" y "AE"
    nombres_por_an_ae <- split(datos_alumnos_an_ae$Alumno, datos_alumnos_an_ae$AN_AE)
    df_an_ae$Nombres <- sapply(df_an_ae$AN_AE, function(x) {
      paste(nombres_por_an_ae[[as.character(x)]], collapse = "<br>")  # Usar <br> para saltos de línea en HTML
    })
    
    

    
    # Mostrar el dataframe resultante
    df_an_ae %>%
      gt() %>%
      tab_header(
        title = "Resumen de AN y AE"
      ) %>%
      cols_label(
        AN_AE = "Número de AN + AE",
        Frecuencia = "Cantidad de Estudiantes",
        Nombres = "Nombres de los Estudiantes"
      ) %>%
      data_color(
        # columns = vars(AN_AE),  # Aplicar gradiente a la columna AN_AE
        columns = c(AN_AE),
        colors = scales::col_numeric(
          palette = c("white", "#00c03f"),  # De blanco a azul
          domain = c(0, max(df_an_ae$AN_AE))  # Los valores de la columna varían de 0 al máximo de AN_AE
        )
      ) %>%
      fmt_markdown(columns = c(Nombres)) %>%  # Renderizar HTML en la columna Nombres
      # fmt_markdown(columns = vars(Nombres)) %>%  # Renderizar HTML en la columna Nombres      
      tab_options(
        table.width = "60%",  # Ajustar el ancho de la tabla
        table.font.size = "14px"  # Ajustar el tamaño de la fuente
      )
    # tab_options(
    #     table.width = "100%"
    #   )
    
    
    }, error = function(e) {
      showNotification("Error en generar el gráfico circular de notas AN y AE", type = "warning")
   
       })
  
    })
  
  
  
  
  
  
  # Gráfico de waffle para AE y AN
  output$grafico_waffle_ae_an <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas con notas AE y AN por alumno
      contar_ae_an <- function(dades_alumnes) {
        # Contar cuántas veces aparecen "AE" y "AN" en cada fila (alumno)
        ae_an <- apply(dades_alumnes, 1, function(x) sum(x %in% c("AE", "AN")))
        return(ae_an)
      }
      
      # Calcular el número de notas AE y AN por alumno
      ae_an_por_alumno <- contar_ae_an(dades_reactives$net)
      
      # Crear un dataframe con los nombres de los alumnos y sus notas AE y AN
      datos_waffle <- data.frame(
        Alumno = rownames(dades_reactives$net),
        AE_AN = ae_an_por_alumno
      )
      
      # Ordenar el dataframe de menor a mayor número de AE y AN
      datos_waffle <- datos_waffle[order(datos_waffle$AE_AN), ]
      
      # Añadir el número de AE y AN al nombre del alumno
      datos_waffle$Etiqueta <- paste(datos_waffle$Alumno, "(", datos_waffle$AE_AN, ")", sep = "")
      
      # Definir una paleta de colores que varíe de blanco a verde
      colores <- colorRampPalette(c("#FFFFFF", "#00C03F"))(max(datos_waffle$AE_AN) + 1)
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = AE_AN)) +
        geom_tile(color = "white", size = 0.5) +  # Crear cuadrados
        facet_wrap(~ reorder(Etiqueta, AE_AN), ncol = 5) +  # Ordenar y organizar los cuadrados por alumno
        scale_fill_gradient(low = "#FFFFFF", high = "#00C03F") +  # Paleta de colores
        geom_text(aes(label = Etiqueta), color = "black", size = 5) +  # Añadir nombres de alumnos y notas AE y AN
        theme_void() +  # Eliminar ejes y fondo
        theme(
          strip.text = element_blank(),  # Ocultar títulos de facetas
          legend.position = "bottom"  # Posición de la leyenda
        ) +
        labs(
          title = "Distribución de notas AE y AN por alumno",
          fill = "Número de AE y AN"
        )
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de AE y AN", type = "warning")
    })
  })
  
  
  
  # Gráfico de waffle para la media de AE
  output$grafico_waffle_media_ae <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas con nota AE por alumno
      contar_ae <- function(dades_alumnes) {
        # Contar cuántas veces aparece "AE" en cada fila (alumno)
        ae <- apply(dades_alumnes, 1, function(x) sum(x == "AE", na.rm = TRUE))
        return(ae)
      }
      
      # Calcular el número de notas AE por alumno
      ae_por_alumno <- contar_ae(dades_reactives$net)
      
      # Calcular la media de AE de toda la clase
      media_ae <- mean(ae_por_alumno)
      
      # Crear un dataframe con la media de AE
      datos_waffle <- data.frame(
        Etiqueta = paste("Mitja de AE"),
        Valor = 1  # Un único cuadrado
      )
      
      # Definir una paleta de colores que varíe de blanco a verde
      colores <- colorRampPalette(c("#FFFFFF", "#00C03F"))(100)  # 100 tonos de gradiente
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = media_ae)) +
        geom_tile(color = "white", size = 2, width = 0.5, height = 0.5) +  # Cuadrado más pequeño
        scale_fill_gradient(low = "#FFFFFF", high = "#00C03F", limits = c(0, max(ncol(dades_reactives$net)))) +  # Paleta de colores
        annotate("text", x = 1, y = 1.2, label = "Mitja de AE", color = "black", size = 4, fontface = "bold") +  # Título
        annotate("text", x = 1, y = 0.8, label = round(media_ae, 2), color = "black", size = 5, fontface = "bold") +  # Valor
        theme_void() +  # Eliminar ejes y fondo
        theme(
          legend.position = "none",  # Ocultar la leyenda
          plot.margin = margin(10, 10, 10, 10)  # Ajustar márgenes
        ) +
        coord_fixed(ratio = 1)  # Mantener la proporción del cuadrado
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de la media de AE", type = "warning")
    })
  })  
  
  
  
  # Gráfico de barras interactivo de frecuencias de excelents
  output$grafico_barras_interactivo_excelents <- renderPlotly({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas suspendidas por alumno
      contar_excelents <- function(dades_alumnes) {
        # Contar cuántas veces aparece "NA" en cada fila (alumno)
        excelents <- apply(dades_alumnes, 1, function(x) sum(x == "AE", na.rm = TRUE))
        return(excelents)
      }
      
      # Calcular el número de excelents por alumno
      excelents_por_alumno <- contar_excelents(dades_reactives$net)
      
      # Crear un dataframe con los nombres de los alumnos y sus excelents
      datos_alumnos <- data.frame(
        Alumno = rownames(dades_reactives$net),
        excelents = excelents_por_alumno
      )
      
      # Crear una tabla de frecuencias de excelents
      tabla_excelents <- table(excelents_por_alumno)
      
      # Convertir la tabla a un dataframe para facilitar el manejo
      df_excelents <- as.data.frame(tabla_excelents)
      colnames(df_excelents) <- c("excelents", "Frecuencia")
      
      # Obtener los nombres de los alumnos para cada frecuencia de excelents
      nombres_por_excelents <- split(datos_alumnos$Alumno, datos_alumnos$excelents)
      df_excelents$Nombres <- sapply(df_excelents$excelents, function(x) {
        paste(nombres_por_excelents[[as.character(x)]], collapse = "<br>")  # Usar <br> para saltos de línea en HTML
      })
      
      
      
      # Crear una paleta de colores que vaya de blanco a rojo
      colores <- colorRampPalette(c("white", "#00C03F"))(nrow(df_excelents))
      
      # Crear un gráfico de barras interactivo con plotly
      p <- plot_ly(df_excelents, x = ~excelents, y = ~Frecuencia, type = 'bar',
                   marker = list(color = colores, line = list(color = "black", width = 1.5)),  # Bordes negros
                   text = ~Nombres,  # Mostrar nombres de alumnos en el tooltip
                   hoverinfo = 'text',  # Mostrar solo el texto en el tooltip
                   hoverlabel = list(bgcolor = "white", font = list(size = 12))) %>%
        layout(title = "Distribución de alumnos por número de asignaturas suspendidas",
               xaxis = list(title = "Número de excelents"),
               yaxis = list(title = "Frecuencia de alumnos"))
      # %>%
      # add_annotations(text = ~Frecuencia,  # Mostrar la frecuencia encima de las barras
      #                 x = ~excelents, y = ~Frecuencia,
      #                 yshift = 10,  # Desplazar el texto hacia arriba
      #                 showarrow = FALSE,
      #                 font = list(size = 14, color = "black")
      #                   )
      
      p
      
    }, error = function(e) {
      showNotification("Error en generar el gráfico de barras interactivo de excelents", type = "warning")
    })
  })
  
  
  
  
  
  
  
  
  
  # Gráfico de waffle para la media de AE y AN
  output$grafico_waffle_media_ae_an <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas con notas AE y AN por alumno
      contar_ae_an <- function(dades_alumnes) {
        # Contar cuántas veces aparecen "AE" y "AN" en cada fila (alumno)
        ae_an <- apply(dades_alumnes, 1, function(x) sum(x %in% c("AE", "AN"), na.rm = TRUE))
        return(ae_an)
      }
      
      # Calcular el número de notas AE y AN por alumno
      ae_an_por_alumno <- contar_ae_an(dades_reactives$net)
      
      # Calcular la media de AE y AN de toda la clase
      media_ae_an <- mean(ae_an_por_alumno)
      
      # Crear un dataframe con la media de AE y AN
      datos_waffle <- data.frame(
        Etiqueta = paste("Mitja de AE i AN"),
        Valor = 1  # Un único cuadrado
      )
      
      # Definir una paleta de colores que varíe de blanco a verde
      colores <- colorRampPalette(c("#FFFFFF", "#00C03F"))(100)  # 100 tonos de gradiente
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = media_ae_an)) +
        geom_tile(color = "white", size = 2, width = 0.5, height = 0.5) +  # Cuadrado más pequeño
        scale_fill_gradient(low = "#FFFFFF", high = "#00C03F", limits = c(0, max(ncol(dades_reactives$net)))) +  # Paleta de colores
        annotate("text", x = 1, y = 1.2, label = "Mitja de AE i AN", color = "black", size = 4, fontface = "bold") +  # Título
        annotate("text", x = 1, y = 0.8, label = round(media_ae_an, 2), color = "black", size = 5, fontface = "bold") +  # Valor
        theme_void() +  # Eliminar ejes y fondo
        theme(
          legend.position = "none",  # Ocultar la leyenda
          plot.margin = margin(10, 10, 10, 10)  # Ajustar márgenes
        ) +
        coord_fixed(ratio = 1)  # Mantener la proporción del cuadrado
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de la media de AE y AN", type = "warning")
    })
  })
  
  
  
  
  # Gráfico de barras interactivo de frecuencias de excelents
  output$grafico_barras_interactivo_en_ae <- renderPlotly({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas suspendidas por alumno
      contar_excelents <- function(dades_alumnes) {
        # Contar cuántas veces aparece "NA" en cada fila (alumno)
        excelents <- apply(dades_alumnes, 1, function(x) sum(x %in% c("AE", "AN"), na.rm = TRUE))
        return(excelents)
      }
      
      # Calcular el número de excelents por alumno
      excelents_por_alumno <- contar_excelents(dades_reactives$net)
      
      # Crear un dataframe con los nombres de los alumnos y sus excelents
      datos_alumnos <- data.frame(
        Alumno = rownames(dades_reactives$net),
        excelents = excelents_por_alumno
      )
      
      # Crear una tabla de frecuencias de excelents
      tabla_excelents <- table(excelents_por_alumno)
      
      # Convertir la tabla a un dataframe para facilitar el manejo
      df_excelents <- as.data.frame(tabla_excelents)
      colnames(df_excelents) <- c("excelents", "Frecuencia")
      
      # Obtener los nombres de los alumnos para cada frecuencia de excelents
      nombres_por_excelents <- split(datos_alumnos$Alumno, datos_alumnos$excelents)
      df_excelents$Nombres <- sapply(df_excelents$excelents, function(x) {
        paste(nombres_por_excelents[[as.character(x)]], collapse = "<br>")  # Usar <br> para saltos de línea en HTML
      })
      
      
      
      # Crear una paleta de colores que vaya de blanco a rojo
      colores <- colorRampPalette(c("white", "#00C03F"))(nrow(df_excelents))
      
      # Crear un gráfico de barras interactivo con plotly
      p <- plot_ly(df_excelents, x = ~excelents, y = ~Frecuencia, type = 'bar',
                   marker = list(color = colores, line = list(color = "black", width = 1.5)),  # Bordes negros
                   text = ~Nombres,  # Mostrar nombres de alumnos en el tooltip
                   hoverinfo = 'text',  # Mostrar solo el texto en el tooltip
                   hoverlabel = list(bgcolor = "white", font = list(size = 12))) %>%
        layout(title = "Distribución de alumnos por número de asignaturas suspendidas",
               xaxis = list(title = "Número de excelents"),
               yaxis = list(title = "Frecuencia de alumnos"))
      # %>%
      # add_annotations(text = ~Frecuencia,  # Mostrar la frecuencia encima de las barras
      #                 x = ~excelents, y = ~Frecuencia,
      #                 yshift = 10,  # Desplazar el texto hacia arriba
      #                 showarrow = FALSE,
      #                 font = list(size = 14, color = "black")
      #                   )
      
      p
      
    }, error = function(e) {
      showNotification("Error en generar el gráfico de barras interactivo de excelents", type = "warning")
    })
  })
  
  
  
  
  
  
  # Gráfico circular de notas AE
  output$grafico_circular_ae <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas con nota AE por alumno
      contar_ae <- function(dades_alumnes) {
        # Contar cuántas veces aparece "AE" en cada fila (alumno)
        ae <- apply(dades_alumnes, 1, function(x) sum(x == "AE", na.rm = TRUE))
        return(ae)
      }
      
      # Calcular el número de notas AE por alumno
      ae_por_alumno <- contar_ae(dades_reactives$net)
      
      # Crear una tabla de frecuencias de notas AE
      tabla_ae <- table(ae_por_alumno)
      
      # Convertir la tabla a un dataframe para facilitar el manejo
      df_ae <- as.data.frame(tabla_ae)
      colnames(df_ae) <- c("AE", "Frecuencia")
      
      # Calcular el porcentaje de alumnos para cada número de notas AE
      df_ae$Porcentaje <- round(df_ae$Frecuencia / sum(df_ae$Frecuencia) * 100, 2)
      
      # Crear una paleta de colores que vaya de blanco a verde
      colores <- colorRampPalette(c("white", "#00c03f"))(nrow(df_ae))
      
      # Crear el gráfico circular
      pie(df_ae$Frecuencia,
          labels = paste(df_ae$AE, " AE\n", df_ae$Frecuencia, " alumnes (", df_ae$Porcentaje, "%)", sep = ""),
          col = colores,
          # main = "Distribución de alumnos por número de notas AE",
          cex = 1)
    }, error = function(e) {
      showNotification("Error en generar el gráfico circular de notas AE", type = "warning")
    })
  })  
  
  
  
  
  
  output$tabla_ae_GT <- render_gt({
    
    req(dades_reactives$net)
    
    tryCatch({
    
    # Verificar que dades_reactives$net esté disponible
    if (!exists("dades_reactives") || is.null(dades_reactives$net)) {
      stop("dades_reactives$net no está disponible.")
    }
    
    # Contar las ocurrencias de "AE" por alumno
    ae_por_alumno <- apply(dades_reactives$net, 1, function(x) sum(x == "AE", na.rm = TRUE))
    
    # Crear un dataframe con los nombres de los alumnos y sus ocurrencias de "AE"
    datos_alumnos_ae <- data.frame(
      Alumno = rownames(dades_reactives$net),
      AE = ae_por_alumno
    )
    
    # Crear una tabla de frecuencias de ocurrencias de "AE"
    tabla_ae <- table(ae_por_alumno)
    
    # Convertir la tabla a un dataframe para facilitar el manejo
    df_ae <- as.data.frame(tabla_ae)
    colnames(df_ae) <- c("AE", "Frecuencia")
    
    # Convertir la columna AE a numérica
    df_ae$AE <- suppressWarnings(as.numeric(as.character(df_ae$AE)))
    
    # Obtener los nombres de los alumnos para cada frecuencia de "AE"
    nombres_por_ae <- split(datos_alumnos_ae$Alumno, datos_alumnos_ae$AE)
    df_ae$Nombres <- sapply(df_ae$AE, function(x) {
      paste(nombres_por_ae[[as.character(x)]], collapse = "<br>")  # Usar <br> para saltos de línea en HTML
    })
    
    # Mostrar el dataframe resultante

    
    # Generar la tabla con gt
    df_ae %>%
      gt() %>%
      tab_header(
        title = "Resumen de AE"
      ) %>%
      cols_label(
        AE = "Número de AE",
        Frecuencia = "Cantidad de Estudiantes",
        Nombres = "Nombres de los Estudiantes"
      ) %>%
      data_color(
        # columns = vars(AE),  # Aplicar gradiente a la columna AE
        columns = c(AE),
        colors = scales::col_numeric(
          palette = c("white", "#00c03f"),  # De blanco a verde
          domain = c(0, max(df_ae$AE))  # Los valores de la columna varían de 0 al máximo de AE
        )
      ) %>%
      fmt_markdown(columns = c(Nombres)) %>%  # Renderizar HTML en la columna Nombres
      # fmt_markdown(columns = vars(Nombres)) %>%  # Antic      
      tab_options(
        table.width = "60%",  # Ajustar el ancho de la tabla
        table.font.size = "14px"  # Ajustar el tamaño de la fuente
      )
      # tab_options(
      #   table.width = "100%"
      # )

  }, error = function(e) {
    showNotification("Error en generar el gráfico circular de notas AE", type = "warning")
  })
})  


  
  
  # Gráfico de waffle solo para AE
  output$grafico_waffle_ae <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para contar el número de asignaturas con nota AE por alumno
      contar_ae <- function(dades_alumnes) {
        # Contar cuántas veces aparece "AE" en cada fila (alumno)
        ae <- apply(dades_alumnes, 1, function(x) sum(x == "AE", na.rm = TRUE))
        return(ae)
      }
      
      # Calcular el número de notas AE por alumno
      ae_por_alumno <- contar_ae(dades_reactives$net)
      
      # Crear un dataframe con los nombres de los alumnos y sus notas AE
      datos_waffle <- data.frame(
        Alumno = rownames(dades_reactives$net),
        AE = ae_por_alumno
      )
      
      # Ordenar el dataframe de menor a mayor número de AE
      datos_waffle <- datos_waffle[order(datos_waffle$AE), ]
      
      # Añadir el número de AE al nombre del alumno
      datos_waffle$Etiqueta <- paste(datos_waffle$Alumno, "(", datos_waffle$AE, ")", sep = "")
      
      # Definir una paleta de colores que varíe de blanco a verde
      colores <- colorRampPalette(c("#FFFFFF", "#00C03F"))(max(datos_waffle$AE) + 1)
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = AE)) +
        geom_tile(color = "white", size = 0.5) +  # Crear cuadrados
        facet_wrap(~ reorder(Etiqueta, AE), ncol = 5) +  # Ordenar y organizar los cuadrados por alumno
        scale_fill_gradient(low = "#FFFFFF", high = "#00C03F") +  # Paleta de colores
        geom_text(aes(label = Etiqueta), color = "black", size = 5) +  # Añadir nombres de alumnos y notas AE
        theme_void() +  # Eliminar ejes y fondo
        theme(
          strip.text = element_blank(),  # Ocultar títulos de facetas
          legend.position = "bottom"  # Posición de la leyenda
        ) +
        labs(
          title = "Distribución de notas AE por alumno",
          fill = "Número de AE"
        )
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de AE", type = "warning")
    })
  })
  
  
  
  # Gráfico de waffle personalizado con nombres de alumnos y nota numérica
  output$grafico_waffle_notas <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para convertir las notas a valores numéricos
      convertir_notas_numericas <- function(dades_alumnes) {
        notas_numericas <- dades_alumnes
        notas_numericas[notas_numericas == "AS"] <- 5
        notas_numericas[notas_numericas == "AN"] <- 7
        notas_numericas[notas_numericas == "AE"] <- 9
        notas_numericas[notas_numericas == "NA"] <- 0  # NA se considera 0
        return(notas_numericas)
      }
      
      # Convertir las notas a valores numéricos
      notas_numericas <- convertir_notas_numericas(dades_reactives$net)
      
      # Calcular la media de las notas numéricas por alumno
      media_notas <- rowMeans(notas_numericas, na.rm = TRUE)
      
      # Crear un dataframe con los nombres de los alumnos y sus medias de notas
      datos_waffle <- data.frame(
        Alumno = rownames(dades_reactives$net),
        Nota_Media = media_notas
      )
      
      # Ordenar el dataframe de menor a mayor nota media
      datos_waffle <- datos_waffle[order(datos_waffle$Nota_Media), ]
      
      # Añadir la nota media al nombre del alumno
      datos_waffle$Etiqueta <- paste(datos_waffle$Alumno, "(", round(datos_waffle$Nota_Media, 2), ")", sep = "")
      
      # Definir una paleta de colores que varíe de blanco a verde
      colores <- colorRampPalette(c("#FFFFFF", "#00C03F"))(max(datos_waffle$Nota_Media) + 1)
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = Nota_Media)) +
        geom_tile(color = "white", size = 0.5) +  # Crear cuadrados
        facet_wrap(~ reorder(Etiqueta, Nota_Media), ncol = 5) +  # Ordenar y organizar los cuadrados por alumno
        scale_fill_gradient(low = "#FFFFFF", high = "#00C03F") +  # Paleta de colores
        geom_text(aes(label = Etiqueta), color = "black", size = 3) +  # Añadir nombres de alumnos y notas medias
        theme_void() +  # Eliminar ejes y fondo
        theme(
          strip.text = element_blank(),  # Ocultar títulos de facetas
          legend.position = "bottom"  # Posición de la leyenda
        ) +
        labs(
          title = "Distribución de notas medias por alumno",
          fill = "Nota media"
        )
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de notas", type = "warning")
    })
  })  
  
  
  # Gráfico de waffle para la media de notas de toda la clase
  output$grafico_waffle_media_notas <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      # Función para convertir las notas a valores numéricos
      convertir_notas_numericas <- function(dades_alumnes) {
        notas_numericas <- dades_alumnes
        notas_numericas[notas_numericas == "AS"] <- 5
        notas_numericas[notas_numericas == "AN"] <- 7
        notas_numericas[notas_numericas == "AE"] <- 9
        notas_numericas[notas_numericas == "NA"] <- 0  # NA se considera 0
        return(notas_numericas)
      }
      
      # Convertir las notas a valores numéricos
      notas_numericas <- convertir_notas_numericas(dades_reactives$net)
      
      # Calcular la media de notas de toda la clase
      media_notas <- mean(rowMeans(notas_numericas, na.rm = TRUE))
      
      # Crear un dataframe con la media de notas
      datos_waffle <- data.frame(
        Etiqueta = paste("Mitja de notes"),
        Valor = 1  # Un único cuadrado
      )
      
      # Definir una paleta de colores que varíe de blanco a verde
      colores <- colorRampPalette(c("#FFFFFF", "#00C03F"))(100)  # 100 tonos de gradiente
      
      # Crear un gráfico de waffle personalizado con ggplot2
      ggplot(datos_waffle, aes(x = 1, y = 1, fill = media_notas)) +
        geom_tile(color = "white", size = 2, width = 0.5, height = 0.5) +  # Cuadrado más pequeño
        scale_fill_gradient(low = "#FFFFFF", high = "#00C03F", limits = c(0, 10)) +  # Paleta de colores
        annotate("text", x = 1, y = 1.2, label = "Mitja de notes", color = "black", size = 4, fontface = "bold") +  # Título
        annotate("text", x = 1, y = 0.8, label = round(media_notas, 2), color = "black", size = 5, fontface = "bold") +  # Valor
        theme_void() +  # Eliminar ejes y fondo
        theme(
          legend.position = "none",  # Ocultar la leyenda
          plot.margin = margin(10, 10, 10, 10)  # Ajustar márgenes
        ) +
        coord_fixed(ratio = 1)  # Mantener la proporción del cuadrado
    }, error = function(e) {
      showNotification("Error en generar el gráfico de waffle de la media de notas", type = "warning")
    })
  })  
  
  
  

  
  output$grafic_assignatures_ordenat_plotty <- renderPlotly({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    
    tryCatch({
      
      # Convertir el dataframe a formato largo
      df_long <- dades_reactives$net %>%
        rownames_to_column(var = "alumne") %>%
        pivot_longer(cols = -alumne, names_to = "assignatura", values_to = "nota")
      
      # Eliminar NA
      df_long <- df_long[!is.na(df_long$nota),]
      
      # Contar las frecuencias de cada nota por alumno
      tabla_frecuencias <- df_long %>%
        group_by(alumne, nota) %>%
        summarise(Frecuencia = n(), .groups = "drop") %>%
        pivot_wider(names_from = nota, values_from = Frecuencia, values_fill = 0)
      
      # Convertir a formato largo para ggplot
      tabla_frecuencias_long <- tabla_frecuencias %>%
        pivot_longer(cols = -alumne, names_to = "nota", values_to = "frecuencia")
      
      # Calcular la media de las notas por alumno
      nota_valores <- c("NA" = 3.5, "AS" = 5.5, "AN" = 7, "AE" = 9)  # Asignar valores numéricos a cada nota
      
      media_notas <- tabla_frecuencias_long %>%
        mutate(nota_num = nota_valores[nota] * frecuencia) %>%
        group_by(alumne) %>%
        summarise(nota_media = sum(nota_num, na.rm = TRUE) / sum(frecuencia), .groups = "drop")
      
      # Unir la media de notas con los datos originales
      tabla_frecuencias_long <- tabla_frecuencias_long %>%
        left_join(media_notas, by = "alumne")
      
      # Ordenar los alumnos por nota media (de menor a mayor)
      tabla_frecuencias_long <- tabla_frecuencias_long %>%
        mutate(alumne = factor(alumne, levels = unique(alumne[order(nota_media)])))
      
      # Definir colores personalizados para las notas
      colores_personalizados <- c("NA" = "#f9011c", "AS" = "#ffd82f", "AN" = "#b0d50c", "AE" = "#00c03f")
      
      # Crear el texto para el tooltip en el orden deseado
      tabla_frecuencias_long <- tabla_frecuencias_long %>%
        group_by(alumne) %>%
        mutate(tooltip_text = paste(
          paste("Alumne:", alumne),
          paste("AE:", sum(frecuencia[nota == "AE"])),
          paste("AN:", sum(frecuencia[nota == "AN"])),
          paste("AS:", sum(frecuencia[nota == "AS"])),
          paste("NA:", sum(frecuencia[nota == "NA"])),
          paste("Nota mitjana:", round(nota_media, 1)),
          sep = "<br>"
        )) %>%
        ungroup()
      
      # Crear el gráfico de barras apilado horizontal con plotly
      p <- plot_ly(tabla_frecuencias_long, 
                   x = ~frecuencia, 
                   y = ~alumne, 
                   color = ~nota, 
                   colors = colores_personalizados,
                   type = 'bar', 
                   orientation = 'h',
                   hoverinfo = 'text',
                   text = ~tooltip_text,
                   hoverlabel = list(bgcolor = "black",  # Fondo negro para el tooltip
                                     font = list(color = "white"))) %>%  # Texto en blanco
        layout(barmode = 'stack',
               xaxis = list(title = 'Frequència'),
               yaxis = list(title = 'Alumne', categoryorder = "array", categoryarray = levels(tabla_frecuencias_long$alumne)),
               showlegend = TRUE)
      
      # Añadir la nota media a la derecha de la barra
      p <- p %>% add_annotations(xref = 'x', yref = 'y',
                                 x = ~nota_media, y = ~alumne,
                                 text = ~round(nota_media, 1),
                                 showarrow = FALSE,
                                 xanchor = 'left',
                                 font = list(color = 'black'))
      
      p
      
    }, error = function(e) {
      print(e)
      return(NULL)
    })
  })
  
  
  
  # Gràfic distribucións 2:
  output$grafic_densitats_2 <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    tryCatch({
      
      # dades_alumnes <- dades_reactives$net  #Les que ja tenim (assolimnet)
      dades_alumnes_numeric <- dades_reactives$net_numeric #Convertim a numeric
      means_notes <- rowMeans(dades_alumnes_numeric, na.rm = TRUE)
      
      plot(density(means_notes), main = "Distribución de Notas", col = "blue")
      rug(notas, col = "red", lwd = 2)
    
      
    }, error = function(e) {
      showNotification("Error en generar el gráfico de distribucin.", type = "warning")
    })
  })  
  
  
  
  
  
  
  # Grafic distribucions totes les notes : Cancel·lat actualment
  # 
  # # Gràfic distribucións 3: Singular notes
  # output$grafic_densitats_3 <- renderPlotly({
  #   req(dades_reactives$net)  # Asegura que los datos estén cargados
  #   tryCatch({
  #     
  #     # Obtenim dades:
  #     notes_numeric_compendi <- dades_reactives$net_compendi
  #     
  #     # Gráfico
  #     p <- ggplot(notes_numeric_compendi, aes(x = "", y = nota)) +
  #       geom_violin(fill = "lightblue", alpha = 0.5) +
  #       # geom_jitter(aes(color = colores, text = alumne), width = 0.2, size = 2) +
  #       geom_jitter(aes(color = colores, text = paste("Alumne: ", alumne, "<br>Nota: ", nota,"<br>Asignatura: ", assignatura)), width = 0.2, size = 2) +  
  #       scale_color_manual( values = c("#f9011c" = "#f9011c", "#ffd82f" = "#ffd82f", "#b0d50c" = "#b0d50c", "#00c03f" = "#00c03f" )) + 
  #       guides(color = "none") +
  #       #scale_color_manual(values = c("A" = "red", "B" = "blue", "C" = "green")) +
  #       theme_minimal()
  #     
  #     # Hacerlo interactivo
  #     ggplotly(p, tooltip = "text")
  #     
  #     
  #     
  #   }, error = function(e) {
  #     showNotification("Error en generar el gráfico de distribucin.", type = "warning")
  #   })
  # })  
  # 
  # 
  
  




  # Gràfic ridge
  output$grafic_dens_ridge <- renderPlot({
    req(dades_reactives$net)  # Asegura que los datos estén cargados
    tryCatch({

      notes_numeric_compendi <- dades_reactives$net_compendi

      # Re-ordenem per nota:
      notes_numeric_compendi$alumne <- reorder(notes_numeric_compendi$alumne, notes_numeric_compendi$nota, FUN = mean)

      # Assignacio color

      colorejat_notes_numeric_compendi <- notes_numeric_compendi

      # Asignar los colores de notes_numeric_mean_compendi a notes_numeric_compendi
      colorejat_notes_numeric_compendi <- colorejat_notes_numeric_compendi %>%
        select(-colores) %>%  # Eliminar la columna colores existente (si es necesario)
        left_join(notes_numeric_mean_compendi %>% select(alumne, colores), by = "alumne")

      colorejat_notes_numeric_compendi$alumne <- reorder(colorejat_notes_numeric_compendi$alumne, colorejat_notes_numeric_compendi$nota, FUN = mean)


      # Ver el resultado
      # head(colorejat_notes_numeric_compendi)

      # Crear un vector de colores único por alumno
      colores <- unique(colorejat_notes_numeric_compendi[, c("alumne", "colores")])
      colores <- setNames(colores$colores, colores$alumne)


      # basic example
      ggplot(colorejat_notes_numeric_compendi, aes(x = nota, y = alumne, fill = alumne)) +
        geom_density_ridges() +
        theme_ridges() +
        theme(legend.position = "none") +
        xlim(0, 10)  +
        scale_fill_manual(values = colores)

      # alumne nota  assignatura colores



    }, error = function(e) {
      showNotification("Error en generar el gráfico Ridge.", type = "warning")
    })
  })



  
  # Gràfic ridge
  # output$grafic_dens_ridge <- renderPlotly({
  #   req(dades_reactives$net)  # Asegura que los datos estén cargados
  #   tryCatch({
  #     
  #     notes_numeric_compendi <- dades_reactives$net_compendi 
  #     
  #     # Re-ordenem per nota:      
  #     notes_numeric_compendi$alumne <- reorder(notes_numeric_compendi$alumne, notes_numeric_compendi$nota, FUN = mean)
  #     
  #     # Assignacio color
  #     colorejat_notes_numeric_compendi <- notes_numeric_compendi
  #     
  #     # Asignar los colores de notes_numeric_mean_compendi a notes_numeric_compendi
  #     colorejat_notes_numeric_compendi <- colorejat_notes_numeric_compendi %>%
  #       select(-colores) %>%  # Eliminar la columna colores existente (si es necesario)
  #       left_join(notes_numeric_mean_compendi %>% select(alumne, colores), by = "alumne")
  #     
  #     colorejat_notes_numeric_compendi$alumne <- reorder(colorejat_notes_numeric_compendi$alumne, colorejat_notes_numeric_compendi$nota, FUN = mean)
  #     
  #     
  #     # Crear un vector de colores único por alumno
  #     colores <- unique(colorejat_notes_numeric_compendi[, c("alumne", "colores")])
  #     colores <- setNames(colores$colores, colores$alumne)
  #     
  #     # Crear el gráfico con ggplot2
  #     p <- ggplot(colorejat_notes_numeric_compendi, aes(x = nota, y = alumne, fill = alumne)) +
  #       geom_density_ridges() +
  #       theme_ridges() + 
  #       theme(legend.position = "none") +
  #       xlim(0, 10)  +
  #       scale_fill_manual(values = colores)
  #     
  #     # Convertir el gráfico de ggplot2 a interactivo con plotly
  #     plotly::ggplotly(p)
  #     
  #   }, error = function(e) {
  #     showNotification(paste("Error: ", e$message), type = "error")
  #     return(NULL)
  #   })
  # })
  # 
  # 
  # 
  # 
  # 
  
  
  
  
  
  
  
  #Visualització dades Globals -----------------------------------
  
  # Gràfic global assignatures NA  -----------------------------------------
  output$graf_global_1 <- renderPlot({
    req(dades_reactives$net)
    tryCatch({
      
      # Agrupa totes les notes i assignatures
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      # Obtener los valores de la tabla
      counts <- transpoar_tabula_notes(taula_conjunt_trans)
      

      # Crear el gráfico de barras
      bar_positions <- barplot(
        counts,
        col = c("#f9011c", "#ffd82f", "#b0d50c", "#00c03f"),
        main = "Distribució Global de Notes",
        ylim = c(0, max(colSums(counts)) + 4),
        las = 2,
        cex.names = 0.8
      )
      
      # Agregar los valores dentro de cada rectángulo y el porcentaje debajo con mayor separación
      for (i in 1:ncol(counts)) {
        cumulative_sum <- c(0, cumsum(counts[, i])) # Acumulado para posicionar los textos
        total_asignatura <- sum(counts[, i])  # Total de cada asignatura
        
        # Mostrar el total de notas encima de cada barra
        text(
          x = bar_positions[i], 
          y = sum(counts[, i]) + 1,  # Posición encima de la barra
          labels = total_asignatura, 
          cex = 1.2,  # Aumentar el tamaño del valor
          col = "black",
          font = 1  # Hacer el texto en negrita
        )
        
        for (j in 1:nrow(counts)) {
          # Solo agregar texto si el valor no es 0
          if (counts[j, i] != 0) {
            # Calcular porcentaje
            percentage <- (counts[j, i] / total_asignatura) * 100
            
            # Agregar el valor dentro de la barra (más grande y en negrita)
            text(
              x = bar_positions[i], 
              y = (cumulative_sum[j] + cumulative_sum[j+1]) / 2, 
              labels = counts[j, i], 
              cex = 1.2,  # Aumentar el tamaño del valor
              col = "black",
              font = 2  # Hacer el texto en negrita
            )
            
            # Agregar el porcentaje debajo del valor (más separado)
            text(
              x = bar_positions[i], 
              y = (cumulative_sum[j] + cumulative_sum[j+1]) / 2 - 1.2,  # Mayor separación entre valor y porcentaje
              labels = paste("(", round(percentage, 1), "%", ")", sep = ""), 
              cex = 0.85,  # Tamaño del porcentaje más grande
              col = "black"
            )
          }
        }
      }
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  })
  
  
  #Suspensos en assignatures
  output$graf_global_2 <- renderPlot({
    req(dades_reactives$net)
    tryCatch({
      # Agrupa totes les notes i assignatures
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      # Gráfico de suspensos (NA)
      graficar_valors_NA <- transpoar_tabula_notes(ordenar_taula_notes(taula_conjunt_trans, "NA", T))
      
      # Calcular el porcentaje de suspendidos por asignatura
      total_per_assignatura <- colSums(graficar_valors_NA)
      suspendidos_per_assignatura <- graficar_valors_NA["NA", ]
      percentatge_suspensos <- suspendidos_per_assignatura / total_per_assignatura
      
      # Ordenar asignaturas por porcentaje de suspendidos
      ordre <- order(percentatge_suspensos, decreasing = TRUE, na.last = TRUE)
      graficar_valors_NA <- graficar_valors_NA[, ordre]
      assignatures_ordenades <- colnames(graficar_valors_NA)
      
      grafic_barplot_NA <- barplot(graficar_valors_NA,
                                   main = "Suspesos en assignatures",
                                   ylim = c(0, max(colSums(graficar_valors_NA)) + 5),
                                   ylab = "Assoliment",
                                   axes = TRUE, 
                                   col = c("#f9011c", "#FFFFFF", "#FFFFFF", "#FFFFFF"),
                                   border = "brown",
                                   las = 2,
                                   width = 0.9)
      
      graficar_valors_NA_sols <- sumar_excloent_nota(graficar_valors_NA, "AS")
      graficar_valors_NA_sols <- sumar_excloent_nota(graficar_valors_NA_sols, "AN")
      graficar_valors_NA_sols <- sumar_excloent_nota(graficar_valors_NA_sols, "AE")
      
      text(x = grafic_barplot_NA, y = colSums(graficar_valors_NA) + 3.5, labels = graficar_valors_NA_sols, col = "black", cex = 1, font = 2)
      
      percentatge_NA <- paste("(", as.character(round(graficar_valors_NA_sols / colSums(graficar_valors_NA) * 100)), "%", ")", sep = "")
      text(x = grafic_barplot_NA, y = colSums(graficar_valors_NA) + 1.5, labels = percentatge_NA, col = "black", cex = 1)
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  })
  
  
  
  
  # Gràfic global amb gestió d'errors -----------------------------------------
  output$graf_global_3 <- renderPlot({
    req(dades_reactives$net)
    tryCatch({
      # Agrupa totes les notes i assignatures
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      # Gráfico de excelentes (AE)
      graficar_notes_AE <- transpoar_tabula_notes(ordenar_taula_notes(taula_conjunt_trans, "AE", T))
      
      grafic_barplot_AE <- barplot(graficar_notes_AE,
                                   main = "Excel·lents en assignatures",
                                   ylim = c(0, max(colSums(graficar_notes_AE)) + 5),
                                   ylab = "Assoliment",
                                   axes = TRUE, 
                                   col = c("#FFFFFF", "#FFFFFF", "#FFFFFF", "#00c03f"),
                                   border = "brown",
                                   las = 2,
                                   width = 0.9)
      
      graficar_valors_AE_sols <- sumar_excloent_nota(graficar_notes_AE, "NA")
      graficar_valors_AE_sols <- sumar_excloent_nota(graficar_valors_AE_sols, "AS")
      graficar_valors_AE_sols <- sumar_excloent_nota(graficar_valors_AE_sols, "AN")
      
      text(x = grafic_barplot_AE, y = colSums(graficar_notes_AE) + 3.5, labels = graficar_valors_AE_sols, col = "black", cex = 1, font = 2)
      
      percentatge_AE <- paste("(", as.character(round(graficar_valors_AE_sols / colSums(graficar_notes_AE) * 100)), "%", ")", sep = "")
      text(x = grafic_barplot_AE, y = colSums(graficar_notes_AE) + 1.5, labels = percentatge_AE, col = "black", cex = 1)
      
      
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  })
  
  
  
  # Gràfic global amb gestió d'errors -----------------------------------------
  output$graf_global_4 <- renderPlot({
    req(dades_reactives$net)
    tryCatch({
      # Agrupa totes les notes i assignatures
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      
      # Gráfico de aprobados (excluyendo NA)
      graficar_notes_aprovats <- transpoar_tabula_notes(ordenar_taula_notes(taula_conjunt_trans, "NA", F))
      
      grafic_barplot_aprovats <- barplot(graficar_notes_aprovats,
                                         main = "Aprovats en assignatures",
                                         ylim = c(0, max(colSums(graficar_notes_aprovats)) + 5),                                   
                                         ylab = "Assoliment",
                                         axes = TRUE, 
                                         col = c("#FFFFFF", "#ffd82f", "#b0d50c", "#00c03f"),
                                         border = "brown",
                                         las = 2)
      
      graficar_valors_aprovats <- sumar_excloent_nota(graficar_notes_aprovats, "NA")
      
      text(x = grafic_barplot_aprovats, y = colSums(graficar_notes_aprovats) + 3.5, labels = colSums(graficar_valors_aprovats), col = "black", cex = 1, font = 2)
      # 
      percentatge_valors <- colSums(graficar_valors_aprovats)/colSums(graficar_notes_aprovats)
      percentatge_aprovats <- paste("(", as.character(round(round(percentatge_valors*100))), "%", ")", sep = "")
      text(x = grafic_barplot_aprovats, y = colSums(graficar_notes_aprovats) + 1.5, labels = percentatge_aprovats, col = "black", cex = 1)
      
      
      
      
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  })
    
  

  


  
  
  
  
  
  # Descarregar PDF ----------------------------------------------------------
  output$descarregar_pdf <- downloadHandler(
    filename = function() {
      paste("resultats_analisi_notes", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      guardar_pdf(file, input, output, session, dades_reactives)
    }
  )
  
  
  # ___PDF de l'apartat Global Alumnes___
  
  generar_grafico_alumne <- function(alumne) {
    req(dades_reactives$net)
    tryCatch({
      notes_alumne <- dades_reactives$net[alumne, ]
      taula <- table(factor(unlist(notes_alumne), levels = c("NA", "AS", "AN", "AE")))
      
      barres <- barplot(taula,
                        col = c("#f9011c", "#ffd82f", "#b0d50c", "#00c03f"),
                        main = paste("Notes de", alumne),
                        ylab = "Nombre d'alumnes",
                        ylim = c(0, max(taula) + 1))
      
      text(x = barres, y = taula + 0.7, labels = taula, col = "black", cex = 1, font = 2)
      
    }, error = function(e) {
      showNotification("Error en generar gràfic per alumne", type = "warning")
    })
  }
  
  
  
  # ___PDF de l'apartat Per Alumne___
  
  

  # ___PDF de l'apartat Per Assignatura___
  
  
  
  

  # ___PDF de l'apartat Global Assignatures___
  
  # Graficar en PDF del gràfic: graf_global_1
  generar_grafico_1 <- function() {
    req(dades_reactives$net)
    tryCatch({
      # El código para generar el gráfico 1 ya está aquí
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      counts <- transpoar_tabula_notes(taula_conjunt_trans)
      
      bar_positions <- barplot(
        counts,
        col = c("#f9011c", "#ffd82f", "#b0d50c", "#00c03f"),
        main = "Distribució Global de Notes",
        ylim = c(0, max(colSums(counts)) + 4),
        las = 2,
        cex.names = 0.8
      )
      
      for (i in 1:ncol(counts)) {
        cumulative_sum <- c(0, cumsum(counts[, i])) 
        total_asignatura <- sum(counts[, i])  
        
        text(
          x = bar_positions[i], 
          y = sum(counts[, i]) + 1,  
          labels = total_asignatura, 
          cex = 1.2,  
          col = "black",
          font = 1
        )
        
        for (j in 1:nrow(counts)) {
          if (counts[j, i] != 0) {
            percentage <- (counts[j, i] / total_asignatura) * 100
            
            text(
              x = bar_positions[i], 
              y = (cumulative_sum[j] + cumulative_sum[j+1]) / 2, 
              labels = counts[j, i], 
              cex = 1.2,  
              col = "black",
              font = 2  
            )
            
            text(
              x = bar_positions[i], 
              y = (cumulative_sum[j] + cumulative_sum[j+1]) / 2 - 1.2,  
              labels = paste("(", round(percentage, 1), "%", ")", sep = ""), 
              cex = 0.85,  
              col = "black"
            )
          }
        }
      }
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  }
  
  # Graficar en PDF del gràfic: graf_global_2
  generar_grafico_2 <- function() {
    req(dades_reactives$net)
    tryCatch({
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      graficar_valors_NA <- transpoar_tabula_notes(ordenar_taula_notes(taula_conjunt_trans, "NA", T))
      
      total_per_assignatura <- colSums(graficar_valors_NA)
      suspendidos_per_assignatura <- graficar_valors_NA["NA", ]
      percentatge_suspensos <- suspendidos_per_assignatura / total_per_assignatura
      
      ordre <- order(percentatge_suspensos, decreasing = TRUE, na.last = TRUE)
      graficar_valors_NA <- graficar_valors_NA[, ordre]
      assignatures_ordenades <- colnames(graficar_valors_NA)
      
      grafic_barplot_NA <- barplot(graficar_valors_NA,
                                   main = "Suspesos en assignatures",
                                   ylim = c(0, max(colSums(graficar_valors_NA)) + 5),
                                   ylab = "Assoliment",
                                   axes = TRUE, 
                                   col = c("#f9011c", "#FFFFFF", "#FFFFFF", "#FFFFFF"),
                                   border = "brown",
                                   las = 2,
                                   width = 0.9)
      
      graficar_valors_NA_sols <- sumar_excloent_nota(graficar_valors_NA, "AS")
      graficar_valors_NA_sols <- sumar_excloent_nota(graficar_valors_NA_sols, "AN")
      graficar_valors_NA_sols <- sumar_excloent_nota(graficar_valors_NA_sols, "AE")
      
      text(x = grafic_barplot_NA, y = colSums(graficar_valors_NA) + 3.5, labels = graficar_valors_NA_sols, col = "black", cex = 1, font = 2)
      
      percentatge_NA <- paste("(", as.character(round(graficar_valors_NA_sols / colSums(graficar_valors_NA) * 100)), "%", ")", sep = "")
      text(x = grafic_barplot_NA, y = colSums(graficar_valors_NA) + 1.5, labels = percentatge_NA, col = "black", cex = 1)
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  }
  
  # Graficar en PDF del gràfic: graf_global_3
  generar_grafico_3 <- function() {
    req(dades_reactives$net)
    tryCatch({
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      graficar_notes_AE <- transpoar_tabula_notes(ordenar_taula_notes(taula_conjunt_trans, "AE", T))
      
      grafic_barplot_AE <- barplot(graficar_notes_AE,
                                   main = "Excel·lents en assignatures",
                                   ylim = c(0, max(colSums(graficar_notes_AE)) + 5),
                                   ylab = "Assoliment",
                                   axes = TRUE, 
                                   col = c("#FFFFFF", "#FFFFFF", "#FFFFFF", "#00c03f"),
                                   border = "brown",
                                   las = 2,
                                   width = 0.9)
      
      graficar_valors_AE_sols <- sumar_excloent_nota(graficar_notes_AE, "NA")
      graficar_valors_AE_sols <- sumar_excloent_nota(graficar_valors_AE_sols, "AS")
      graficar_valors_AE_sols <- sumar_excloent_nota(graficar_valors_AE_sols, "AN")
      
      text(x = grafic_barplot_AE, y = colSums(graficar_notes_AE) + 3.5, labels = graficar_valors_AE_sols, col = "black", cex = 1, font = 2)
      
      percentatge_AE <- paste("(", as.character(round(graficar_valors_AE_sols / colSums(graficar_notes_AE) * 100)), "%", ")", sep = "")
      text(x = grafic_barplot_AE, y = colSums(graficar_notes_AE) + 1.5, labels = percentatge_AE, col = "black", cex = 1)
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  }
  
  # Graficar en PDF del gràfic: graf_global_3
  generar_grafico_4 <- function() {
    req(dades_reactives$net)
    tryCatch({
      notes_tot <- unlist(dades_reactives$net)
      assignatures_tot <- rep(colnames(dades_reactives$net), each = nrow(dades_reactives$net))
      taula_conjunt_trans <- table(notes_tot, assignatures_tot)
      
      graficar_notes_aprovats <- transpoar_tabula_notes(ordenar_taula_notes(taula_conjunt_trans, "NA", F))
      
      grafic_barplot_aprovats <- barplot(graficar_notes_aprovats,
                                         main = "Aprovats en assignatures",
                                         ylim = c(0, max(colSums(graficar_notes_aprovats)) + 5),                                   
                                         ylab = "Assoliment",
                                         axes = TRUE, 
                                         col = c("#FFFFFF", "#ffd82f", "#b0d50c", "#00c03f"),
                                         border = "brown",
                                         las = 2)
      
      graficar_valors_aprovats <- sumar_excloent_nota(graficar_notes_aprovats, "NA")
      
      text(x = grafic_barplot_aprovats, y = colSums(graficar_notes_aprovats) + 3.5, labels = colSums(graficar_valors_aprovats), col = "black", cex = 1, font = 2)
      
      percentatge_valors <- colSums(graficar_valors_aprovats)/colSums(graficar_notes_aprovats)
      percentatge_aprovats <- paste("(", as.character(round(round(percentatge_valors*100))), "%", ")", sep = "")
      text(x = grafic_barplot_aprovats, y = colSums(graficar_notes_aprovats) + 1.5, labels = percentatge_aprovats, col = "black", cex = 1)
      
    }, error = function(e) {
      showNotification("Error en generar gràfic global", type = "warning")
    })
  }
  
  

  
  # Descargar los gráficos como un archivo PDF
  output$descargar_graficos <- downloadHandler(
    filename = function() {
      paste("graficos_", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      # Crear el archivo PDF para guardar los gráficos
      pdf(file)  # Abrimos un archivo PDF para escribir los gráficos
      
      
      #__Per alumne__
      
      generar_grafico_alumne()
      
      
      # __Global Assignatures ___
      # Generar y guardar los gráficos
      generar_grafico_1()  # Llamamos a la función que genera el gráfico 1
      # Puedes agregar más gráficos llamando a las funciones correspondientes:
      generar_grafico_2()
      generar_grafico_3()
      generar_grafico_4()
      
      
      
      
      dev.off()  # Cerramos el dispositivo PDF
    }
  )
    
    
  
}  #Fi de server--







# Executar aplicació ----------------------------------------------------------
shinyApp(ui, server)