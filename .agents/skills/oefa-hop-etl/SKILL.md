---
name: oefa-hop-etl
description: >-
  Apache Hop + H2 in-memory STG_* + R ETL archetype for OEFA. Inputs Google
  Sheets / Oracle SISUD / MySQL; staging H2 via inputs.yaml + Python DDL; logic
  in R; output MySQL or Excel. Use when cloning the archetype, adding a STG
  source, wiring wf_main / wf_create_stg, debugging Hop/H2/R logs, writing
  inputs.yaml, or choosing Hop-only vs R. Portable for Cursor, OpenCode, and
  agents reading AGENTS.md.
---

# OEFA Hop ETL (arquetipo)

## When to use

Working in this archetype or a clone: new source, staging H2, `inputs.yaml`, capa R, salida MySQL/Excel, o debug de un Play de Hop.

Plan de diseño: `docs/plan-skill-arquetipo-etl.md`. Dos workflows: `docs/plan-dos-workflows-stg.md`. Contrato R: `r/CONTRATO.md`.

## Architecture (do not mix layers)

```
Sheets / Oracle SISUD / MySQL
    -> inputs.yaml  (declara fuentes)
    -> Python DDL   (CREATE TABLE STG_* en H2; no extrae filas)
    -> Apache Hop   (extract: TableInput / GoogleSheetsInput -> TableOutput)
    -> H2 mem:csep  (landing STG_*, reset each run)
    -> R            (r/logica/: un solo .R)
    -> MySQL or Excel
```

| Capa | Hace | No hace |
|---|---|---|
| `inputs.yaml` | Declara fuentes y nombre `STG_*` | Extraer filas |
| Python | Introspecta schema vivo y crea DDL H2 | Cargar datos |
| Hop | Extrae y trunca/carga `STG_*` | Lógica de negocio multi-fuente |
| R | Unión, reglas, esquema ancho | Abrir conexiones dentro de `r/logica/` |

**Salida default de ETLs nuevos:** MySQL o Excel (`output/`). Oracle REPOCSEP es **legado** (nefa/diego/multa); no copiarlo a proyectos nuevos. Oracle SISUD es **fuente**.

## When Hop alone vs when R

- **Hop solo**: 1 fuente → 1 destino, mapeo 1:1.
- **R**: UNION multi-fuente, reglas de negocio, esquema ancho, `#N/A` → NA.

Un solo `.R` en `r/logica/` (auto-descubierto por `r/main.R`). Entrada = claves de `lecturas` en `r/io/leer_h2.R`. Salida = data.frame `RESULTADO` (`SALIDA_DF` en `main.R`). En `r/logica/` no hay `library()`, jars ni conexiones.

## Workflow to run

Dos workflows. No mezclar diseño con corrida.

**Diseño** (H2 vivo para mapear en el GUI): `workflows/wf_create_stg.hwf`

1. Completar `inputs.yaml`
2. Play `wf_create_stg`: Reset H2 + `python python/create_stg.py`
3. Success: H2 sigue en 9092 con `STG_*` vacías. Pintar `pl_stage_*.hpl` (TableOutput a esas tablas).

**Corrida / smoke**: `workflows/wf_main.hwf`

1. Reset H2 clean (`h2/scripts/reset_and_create.bat` → `00_reset.sql` + `01_schema.sql`)
2. Python create STG — `sources: []` = no-op; con fuentes, recrea `STG_*` (in-memory se borra en el reset)
3. Pipeline(s) de carga → `STG_*` (demo: `pl_demo.hpl`; extract se cablea **después** de Python)
4. Run R → MySQL o Excel
5. Success

Verificación = Hop GUI Play + log. No hay suite de tests.

## Staging (opción B: Python después del reset)

No reescribir `h2/sql/01_schema.sql`. Orden:

1. Declarar fuentes en `inputs.yaml` (raíz). Contrato: [inputs.example.yaml](inputs.example.yaml).
2. Play `wf_create_stg` (diseño) o el paso Python de `wf_main` (corrida): introspecta, escribe `h2/sql/02_stg.sql` (gitignore) y aplica `CREATE TABLE STG_*` por JDBC. Detalle: [reference.md](reference.md).
3. Hop extrae hacia esas tablas (truncate + insert).
4. Cablear `pl_stage_*.hpl` en `wf_main.hwf` **después** de Python.
5. Añadir clave en `r/io/leer_h2.R` → `lecturas`.

Deps: `pip install -r python/requirements.txt`. Python **solo crea DDL**. Hop extrae. Sheets: todos VARCHAR (`#N/A`). `sources: []` = exit 0.

Convención de nombre: `STG_<ORIGEN>_<ENTIDAD>` (`STG_ORA_*`, `STG_MYSQL_*`, `STG_GS1_*`). Landing: todo nullable, VARCHAR sin longitud.

## Extending a new source (checklist)

1. Mapear columnas del objeto vivo. Dumps en `docs/input_examples/` son **mapeo**, no extractos de producción.
2. Añadir entrada en `inputs.yaml`.
3. Play `wf_create_stg` (H2 vivo) y crear `pipelines/pl_stage_*.hpl` (TableInput o GoogleSheetsInput → H2 TableOutput truncate).
4. Wire action + hops en `wf_main.hwf` **después** de Python create STG.
5. Extender `lecturas` + el único `.R` de `r/logica/`.
6. Salida: escritor MySQL en `r/io/` o Excel a `output/` (`openxlsx` / `writexl`). Oracle write = legado.
7. Actualizar `AGENTS.md`.

## Connections (variables only)

Fuente única: `project-config.json` → `config.variables`. Entorno: `.\switch-env.ps1 local|remote`.

- `h2` → `DB_H2_*` (`jdbc:h2:tcp://localhost:9092/mem:csep;...MODE=Oracle...`, user `sa` / password `csep`)
- `oracle_sisud` → `DB_ORA_SISUD_*` (oefabd / SISUD, **fuente**)
- `mysql` → `DB_MYSQL_*` (fuente y/o **destino**)
- `oracle_repocsep` → `DB_ORA_REPO_*` (**legado**, no default)

Un `${VAR}` literal en el log = variable no definida o proyecto Hop activo equivocado.

Nunca commitear secretos. No pegar passwords de `docs/notas.txt` en skills, PRs ni chat. `client_secret.json` está en `.gitignore`.

## Hop gotchas already learned

- Sheets `#N/A` → String en Hop; VARCHAR en H2 (incl. montos).
- Workflow XML: escapar `&` como `&amp;` (ej. `2>&amp;1`).
- R en Windows: delayed expansion + `call Rscript` para que `%ERRORLEVEL%` sea correcto.
- Reset H2 SHELL debe background el server (`>nul 2>&1`) o Hop se cuelga.
- `options(java.parameters=...)` **antes** de `library(RJDBC)` / rJava. No mover esa línea en `r/main.R`.
- H2 in-memory: vacía si el server se reinició sin una corrida de staging.

## Additional resources

- Tipos STG, introspección por fuente, flujo Python: [reference.md](reference.md)
- Contrato del manifiesto: [inputs.example.yaml](inputs.example.yaml)
- Plan de diseño: `docs/plan-skill-arquetipo-etl.md`
- Dos workflows (diseño vs corrida): `docs/plan-dos-workflows-stg.md`
