# =============================================================================
# io/escribir_oracle.R
# SALIDA: data.frame -> MySQL RPT_ACCIONES_UBIGEO (TRUNCATE + INSERT)
#
# Conexion: DB_MYSQL_* desde project-config.json (host, puerto, db, user, pass).
# Si url/user/password son placeholders "<...>", omite el write (smoke H2-only).
#
# Uso:
#   source(file.path(root, "r", "io", "escribir_oracle.R"))
#   escribir_oracle(df, mysql_jar = mysql_jar, root = root)
# =============================================================================

escribir_oracle <- function(df,
                            tabla = "RPT_ACCIONES_UBIGEO",
                            database = NULL,
                            url = NULL,
                            user = NULL,
                            password = NULL,
                            mysql_jar,
                            root = NULL) {
  if (missing(mysql_jar) || !file.exists(mysql_jar)) {
    stop("No se encuentra mysql_jar: ", mysql_jar)
  }

  if (!is.null(root)) {
    source(file.path(root, "r", "io", "leer_config.R"), local = TRUE)
    vars <- leer_hop_vars(root)
    if (is.null(url)) url <- hop_var(vars, "DB_MYSQL_URL")
    if (is.null(user)) user <- hop_var(vars, "DB_MYSQL_USERNAME")
    if (is.null(password)) password <- hop_var(vars, "DB_MYSQL_PASSWORD")
    if (is.null(database)) database <- hop_var(vars, "DB_MYSQL_DATABASE")
  } else {
    if (is.null(url) || is.null(user) || is.null(password)) {
      stop("Sin root ni url/user/password: pasa root= o credenciales explicitas")
    }
  }

  if (grepl("^<", url) || grepl("^<", user) || grepl("^<", password)) {
    message("AVISO: credenciales MySQL placeholder -> se OMITE el write (tabla ",
            tabla, ").")
    message("Resultado en memoria: ", nrow(df), " filas x ", ncol(df), " columnas")
    return(invisible(nrow(df)))
  }

  message("MySQL out: ", url, " user=", user, " db=", ifelse(is.null(database), "?", database))

  out <- df
  out[] <- lapply(out, function(x) if (is.factor(x)) as.character(x) else x)
  for (nm in names(out)) {
    if (inherits(out[[nm]], "POSIXt") || inherits(out[[nm]], "Date")) {
      out[[nm]] <- format(out[[nm]], "%Y-%m-%d %H:%M:%S")
    }
  }
  out <- as.data.frame(out, stringsAsFactors = FALSE)

  drv_mysql <- RJDBC::JDBC("com.mysql.cj.jdbc.Driver", mysql_jar)
  con <- DBI::dbConnect(drv_mysql, url, user, password)
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  RJDBC::dbSendUpdate(con, paste("TRUNCATE TABLE ", tabla, sep = ""))
  DBI::dbWriteTable(con, tabla, out, overwrite = FALSE, append = TRUE, row.names = FALSE)

  n_out <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS N FROM ", tabla, sep = ""))$N
  DBI::dbDisconnect(con)
  on.exit(NULL)

  message(tabla, ": ", nrow(out), " filas -> ", tabla, " (", n_out, " en BD)")
  invisible(n_out)
}
