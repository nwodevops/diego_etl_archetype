# =============================================================================
# io/escribir_oracle.R
# SALIDA: data.frame -> Oracle RPT_ACCIONES_UBIGEO (TRUNCATE + INSERT)
#
# Conexion: DB_ORA_REPO_* (+ DB_ORA_REPO_SCHEMA) desde project-config.json.
# Si url/user/password son placeholders "<...>", omite el write (smoke H2-only).
#
# Uso:
#   source(file.path(root, "r", "io", "escribir_oracle.R"))
#   escribir_oracle(df, ojdbc_jar = ojdbc_jar, root = root)
# =============================================================================

escribir_oracle <- function(df,
                            tabla = "RPT_ACCIONES_UBIGEO",
                            esquema = NULL,
                            url = NULL,
                            user = NULL,
                            password = NULL,
                            ojdbc_jar,
                            root = NULL) {
  if (missing(ojdbc_jar) || !file.exists(ojdbc_jar)) {
    stop("No se encuentra ojdbc_jar: ", ojdbc_jar)
  }

  if (!is.null(root)) {
    source(file.path(root, "r", "io", "leer_config.R"), local = TRUE)
    vars <- leer_hop_vars(root)
    if (is.null(url)) url <- hop_var(vars, "DB_ORA_REPO_URL")
    if (is.null(user)) user <- hop_var(vars, "DB_ORA_REPO_USERNAME")
    if (is.null(password)) password <- hop_var(vars, "DB_ORA_REPO_PASSWORD")
    if (is.null(esquema)) {
      esquema <- hop_var(vars, "DB_ORA_REPO_SCHEMA", default = toupper(user))
    }
  } else {
    if (is.null(url) || is.null(user) || is.null(password)) {
      stop("Sin root ni url/user/password: pasa root= o credenciales explicitas")
    }
    if (is.null(esquema)) esquema <- toupper(user)
  }

  if (grepl("^<", url) || grepl("^<", user) || grepl("^<", password)) {
    message("AVISO: credenciales Oracle placeholder -> se OMITE el write (tabla ",
            esquema, ".", tabla, ").")
    message("Resultado en memoria: ", nrow(df), " filas x ", ncol(df), " columnas")
    return(invisible(nrow(df)))
  }

  message("Oracle out: ", url, " user=", user, " schema=", esquema)

  out <- df
  out[] <- lapply(out, function(x) if (is.factor(x)) as.character(x) else x)
  for (nm in names(out)) {
    if (inherits(out[[nm]], "Date")) {
      out[[nm]] <- format(out[[nm]], "%Y-%m-%d %H:%M:%S")
    }
  }
  out <- as.data.frame(out, stringsAsFactors = FALSE)

  drv_ora <- RJDBC::JDBC("oracle.jdbc.OracleDriver", ojdbc_jar)
  con <- DBI::dbConnect(drv_ora, url, user, password)
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  RJDBC::dbSendUpdate(con, "ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'")
  RJDBC::dbSendUpdate(con, paste("TRUNCATE TABLE ", esquema, ".", tabla, sep = ""))
  DBI::dbWriteTable(con, tabla, out, overwrite = FALSE, append = TRUE, row.names = FALSE)

  n_out <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS N FROM ", esquema, ".", tabla, sep = ""))$N
  DBI::dbDisconnect(con)
  on.exit(NULL)

  message(tabla, ": ", nrow(out), " filas -> ", esquema, ".", tabla, " (", n_out, " en BD)")
  invisible(n_out)
}
