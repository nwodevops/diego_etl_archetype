# =============================================================================
# main.R  --  ENTRY POINT Acciones PIN (orquestacion delgada)
#
# Flujo:
#   1. SETUP   : heap JVM + librerias + root
#   2. ENTRADA : io/leer_h2.R              -> Acciones / Documentos / AdminUF
#   3. LOGICA  : unico .R en r/logica/     -> Acciones_Ubigeo
#   4. SALIDA  : io/escribir_oracle.R      -> RPT_ACCIONES_UBIGEO (DB_MYSQL_*)
#
# Contrato: r/CONTRATO.md
# Uso: Rscript r/main.R  (o r/run_main.sh|.bat desde Hop)
# =============================================================================

# ---------------------------------------------------------------------------
# 0. CONFIG
# ---------------------------------------------------------------------------
SALIDA_DF <- "Acciones_Ubigeo"

# ---------------------------------------------------------------------------
# 1. SETUP: heap JVM ANTES de cargar rJava/RJDBC (no mover esta linea)
# ---------------------------------------------------------------------------
options(java.parameters = c("-Xmx6g", "-Xms512m"))

suppressPackageStartupMessages({
  .libPaths(c(path.expand("~/R/library"), .libPaths()))
  library(RJDBC)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(lubridate)
})

args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("r/main.R")
}
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

ojdbc_jar <- file.path(root, "lib", "ojdbc11.jar")
mysql_jar <- file.path(root, "lib", "mysql-connector-j-8.2.0.jar")

# ---------------------------------------------------------------------------
# 2. ENTRADA (H2 STG_* -> data.frames en el entorno)
# ---------------------------------------------------------------------------
source(file.path(root, "r", "io", "leer_h2.R"))
datos <- leer_h2(root)
if (length(datos) == 0) stop("leer_h2() no devolvio data.frames; revisa 'lecturas' en r/io/leer_h2.R")

for (nm in names(datos)) assign(nm, datos[[nm]], envir = globalenv())

# ---------------------------------------------------------------------------
# 3. LOGICA: auto-descubrir el UNICO .R de r/logica/
# ---------------------------------------------------------------------------
logica_dir <- file.path(root, "r", "logica")
archivos_r <- list.files(logica_dir, pattern = "\\.R$", ignore.case = TRUE, full.names = TRUE)
if (length(archivos_r) == 0) stop("No hay ningun .R en r/logica/. Pega ahi tu logica (ver r/plantilla_logica.R)")
if (length(archivos_r) > 1) stop("Hay mas de un .R en r/logica/: ", length(archivos_r),
                                 ". Deja un solo archivo de logica.")

message("Logica: ", basename(archivos_r))
source(archivos_r[1])

if (!exists(SALIDA_DF, envir = globalenv())) {
  stop("La logica no dejo el data.frame '", SALIDA_DF, "' (configurable en main.R). Ver r/CONTRATO.md")
}

df_salida <- get(SALIDA_DF, envir = globalenv())
# Sello de corrida (no forma parte de la logica pristine)
df_salida$FE_CARGA <- Sys.time()
message("Salida de logica: ", nrow(df_salida), " filas x ", ncol(df_salida), " columnas")

# ---------------------------------------------------------------------------
# 4. SALIDA (df -> MySQL RPT_ACCIONES_UBIGEO; skip si placeholders)
# ---------------------------------------------------------------------------
source(file.path(root, "r", "io", "escribir_oracle.R"))
escribir_oracle(df_salida, mysql_jar = mysql_jar, root = root)

message("Listo (H2 STG_* -> logica -> MySQL).")
