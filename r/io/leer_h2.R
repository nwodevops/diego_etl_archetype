# =============================================================================
# io/leer_h2.R
# ENTRADA generica: H2 mem:csep -> Acciones / Documentos / AdminUF (desde STG_*)
#
# Las claves de `lecturas` son el contrato de entrada de r/logica/acciones_pin.R.
# Fuentes Hop: STG_ORA_ACCIONES / STG_ORA_ADMINUF / STG_ORA_DOCUMENTOS
# (creadas por python/create_stg.py desde inputs.yaml).
#
# Requisito: options(java.parameters=...) ANTES de library(RJDBC)/rJava
# =============================================================================

leer_h2 <- function(root) {

  lecturas <- list(
    Acciones = paste(
      "SELECT TXMES, TXCUC, TXESTADO, IDADMINISTRADO, TXADMINISTRADO_ADM,",
      "TXSUBSECTOR_UND, TXSUBUNIDAD, TXUBIGEO_INAF, TXUBIGEO_INEI,",
      "TXDEPARTAMENTO, TXPROVINCIA, TXDISTRITO, TXCOORDINACION, TXTIPSUP,",
      "TXFUENTE, TXACCION, FEFIN, FGSUPUPD_2DOTIEMPO, FGSUP_ORIENTATIVA, IDUF_SIG",
      "FROM PUBLIC.STG_ORA_ACCIONES"
    ),
    Documentos = paste(
      "SELECT TXCUC, TXTIPO_DOC, FEFIN",
      "FROM PUBLIC.STG_ORA_DOCUMENTOS"
    ),
    AdminUF = paste(
      "SELECT UF_SIG_ID, UF_TXESTADO, UF_UBIGEO_INAF, TXUBIGEO_INEI,",
      "UF_DPTO, UF_PROV, UF_DIST",
      "FROM PUBLIC.STG_ORA_ADMINUF"
    )
  )

  h2_jars <- list.files(file.path(root, "h2", "lib"), pattern = "^h2-[0-9].*\\.jar$", full.names = TRUE)
  h2_jar <- if (length(h2_jars) > 0) h2_jars[1] else file.path(root, "h2", "lib", "h2.jar")
  if (!file.exists(h2_jar)) stop("No se encuentra: ", h2_jar)

  if (!requireNamespace("RJDBC", quietly = TRUE)) stop("Paquete RJDBC no disponible")

  drv <- RJDBC::JDBC("org.h2.Driver", h2_jar)
  con <- DBI::dbConnect(
    drv,
    "jdbc:h2:tcp://localhost:9092/mem:csep;DB_CLOSE_DELAY=-1;MODE=Oracle;DATABASE_TO_UPPER=TRUE;DEFAULT_NULL_ORDERING=HIGH;AUTO_RECONNECT=TRUE",
    "sa",
    "csep"
  )
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  datos <- lapply(lecturas, function(q) DBI::dbGetQuery(con, q))

  datos <- lapply(datos, function(df) {
    for (nm in names(df)) {
      if (inherits(df[[nm]], "POSIXct") || inherits(df[[nm]], "Date")) {
        df[[nm]] <- as.Date(df[[nm]])
      }
    }
    df
  })

  if ("FGSUPUPD_2DOTIEMPO" %in% names(datos$Acciones)) {
    datos$Acciones$FGSUPUPD_2DOTIEMPO <- as.character(datos$Acciones$FGSUPUPD_2DOTIEMPO)
  }
  if ("FGSUP_ORIENTATIVA" %in% names(datos$Acciones)) {
    datos$Acciones$FGSUP_ORIENTATIVA <- as.character(datos$Acciones$FGSUP_ORIENTATIVA)
  }

  DBI::dbDisconnect(con)
  on.exit(NULL)

  for (nm in names(datos)) {
    message(nm, ": ", nrow(datos[[nm]]), " x ", ncol(datos[[nm]]))
  }

  datos
}
