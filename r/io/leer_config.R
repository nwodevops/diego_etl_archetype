# =============================================================================
# io/leer_config.R
# Lee variables Hop desde project-config.json + override Sys.getenv
# =============================================================================

leer_hop_vars <- function(root) {
  path <- file.path(root, "project-config.json")
  vars <- list()

  if (file.exists(path)) {
    .libPaths(c(path.expand("~/R/library"), .libPaths()))
    if (requireNamespace("jsonlite", quietly = TRUE)) {
      cfg <- jsonlite::fromJSON(path, simplifyVector = FALSE)
      for (v in cfg$config$variables) {
        vars[[v$name]] <- as.character(v$value)
      }
    } else {
      py <- paste(
        "import json,sys",
        "c=json.load(open(sys.argv[1]))",
        "for v in c['config']['variables']:",
        " print(v['name']+'\\t'+v['value'])",
        sep = "; "
      )
      out <- system2("python3", args = c("-c", py, path), stdout = TRUE, stderr = FALSE)
      if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
        stop("No se pudo leer project-config.json (falta jsonlite y python3)")
      }
      for (line in out) {
        parts <- strsplit(line, "\t", fixed = TRUE)[[1]]
        if (length(parts) >= 2) vars[[parts[1]]] <- paste(parts[-1], collapse = "\t")
      }
    }
  }

  for (n in names(vars)) {
    ev <- Sys.getenv(n, unset = "")
    if (nzchar(ev)) vars[[n]] <- ev
  }
  extra <- c(
    "DB_ORA_REPO_URL", "DB_ORA_REPO_USERNAME", "DB_ORA_REPO_PASSWORD",
    "DB_ORA_REPO_SCHEMA", "DB_H2_URL", "DB_H2_USERNAME", "DB_H2_PASSWORD"
  )
  for (n in extra) {
    if (is.null(vars[[n]]) || !nzchar(vars[[n]])) {
      ev <- Sys.getenv(n, unset = "")
      if (nzchar(ev)) vars[[n]] <- ev
    }
  }
  vars
}

hop_var <- function(vars, name, default = NULL) {
  v <- vars[[name]]
  if (is.null(v) || !nzchar(v)) {
    if (is.null(default)) stop("Falta variable Hop: ", name)
    return(default)
  }
  v
}
