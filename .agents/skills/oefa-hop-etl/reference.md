# Referencia — staging H2 y tipos

Leer desde [SKILL.md](SKILL.md). No duplicar reglas de arquitectura aquí.

## Introspección por tipo de fuente

Opción **B** (fija): Reset H2 primero; después `python python/create_stg.py` lee `inputs.yaml`, introspecta, escribe `h2/sql/02_stg.sql` y aplica `CREATE TABLE IF NOT EXISTS` por JDBC (`jaydebeapi` + `h2/lib/h2-*.jar`). No reescribe `01_schema.sql`. Reset **no** ejecuta `02_stg.sql`.

Entry point: `python/create_stg.py`. Adapters: `python/introspect/{oracle,mysql,sheets}.py`. Mapeo H2: `python/h2_ddl.py`.

### Oracle (`type: oracle`)

```sql
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE
FROM ALL_TAB_COLUMNS
WHERE OWNER = :owner AND TABLE_NAME = :object
ORDER BY COLUMN_ID
```

Conexión: variables `DB_ORA_SISUD_*`. `object` en el manifiesto es `OWNER.NOMBRE` (vista o tabla).

### MySQL (`type: mysql`)

```sql
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = :schema AND TABLE_NAME = :table
ORDER BY ORDINAL_POSITION
```

Conexión: `DB_MYSQL_*`. `object` es `schema.tabla`.

### Google Sheets (`type: sheets`)

- Auth: `${PROJECT_HOME}/client_secret.json` (service account).
- Key: `spreadsheet_key` (variable Hop, no hardcodear el id en el skill).
- Schema = **fila de headers**. Tipos: **todos VARCHAR**. No inferir NUMBER (gotcha `#N/A`).
- Sanitizar nombres de columna a identificadores H2 (sin espacios ni `)` `(` `/`).

## Mapeo de tipos → H2 (MODE=Oracle)

Landing tolerante: **todo nullable**. VARCHAR **sin longitud** (máximo H2; evita `Value too long`).

| Fuente (Oracle / MySQL) | H2 |
|---|---|
| VARCHAR2, CHAR, CLOB, TEXT, JSON | VARCHAR |
| NUMBER / DECIMAL / NUMERIC sin escala (enteros) | BIGINT o DECIMAL |
| NUMBER / DECIMAL con escala, FLOAT, DOUBLE | DECIMAL o VARCHAR si la fuente mezcla `#N/A` |
| DATE | TIMESTAMP o DATE |
| TIMESTAMP / DATETIME | TIMESTAMP |
| BOOLEAN / BIT | VARCHAR o BOOLEAN |
| Sheets (cualquier columna) | VARCHAR |

Si hay duda (Sheets, columnas sucias, montos): **VARCHAR**.

Plantilla de tabla:

```sql
CREATE TABLE IF NOT EXISTS STG_ORA_EJEMPLO (
    COL_A VARCHAR,
    COL_B TIMESTAMP,
    COL_C VARCHAR
);
```

Sin PK, sin NOT NULL, sin índices en landing.

## Convención `STG_*`

| Origen | Prefijo | Ejemplo |
|---|---|---|
| Oracle SISUD | `STG_ORA_` | `STG_ORA_VW_MULTA_COERCITIVA` |
| MySQL | `STG_MYSQL_` | `STG_MYSQL_T_MVC_MULTACOERCITIVA` |
| Google Sheets libro 1 | `STG_GS1_` | `STG_GS1_MULTAS_COERCITIVAS` |
| Google Sheets libro 2 | `STG_GS2_` | `STG_GS2_MULTAS_COERCITIVAS` |

Una fuente = una tabla STG. No UNION en H2.

## Orden en los workflows

**Diseño** — `workflows/wf_create_stg.hwf` (deja H2 vivo; no extrae filas):

```
Start
  -> Reset H2 clean
  -> Python create STG       (SHELL: python python\create_stg.py)
  -> Success
```

Tras Success: mapear `pl_stage_*.hpl` en el GUI (TableOutput ve `STG_*`). Si se para el server H2, in-memory se pierde; volver a Play `wf_create_stg`.

**Corrida / smoke** — `workflows/wf_main.hwf`:

```
Start
  -> Reset H2 clean          (stop + start + DROP ALL + 01_schema.sql)
  -> Python create STG       (SHELL: python python\create_stg.py)
  -> load_sheets / pl_stage_*  (después de Python; demo: pl_demo.hpl)
  -> Run R
  -> Success
```

No mezclar con opción A (generar SQL antes del reset y que el bat aplique `02_stg.sql`).

## Pipeline Hop (extract)

Patrón: Input → (Select values si hace falta) → TableOutput H2.

- Oracle/MySQL: `TableInput` con `SELECT` explícito de columnas (mismo orden que STG).
- Sheets: `GoogleSheetsInput` + campos String; credencial `${PROJECT_HOME}/client_secret.json`.
- TableOutput: conexión `h2`, tabla `STG_*`, **truncate** en cada corrida.
- No transformar negocio en el pipeline de staging.

## Capa R (salida)

- Lectura: añadir query en `lecturas` de `r/io/leer_h2.R`. Nombre de la clave = nombre del data.frame.
- Escritura nueva (default):
  - MySQL: `r/io/escribir_mysql.R` — TRUNCATE + INSERT; skip si placeholders `<...>`.
  - Excel: `openxlsx` o `writexl` hacia `output/<nombre>.xlsx`.
- `r/io/escribir_oracle.R` existe en el arquetipo para smoke/legado. No usarlo como destino de ETLs nuevos.
- `options(java.parameters=...)` antes de RJDBC.

## Calidad mínima al añadir una fuente

- Contar filas STG vs origen (mismo filtro).
- Log de Hop sin `${VAR}` literal.
- Sheets: una fila `#N/A` no debe tumbar el pipeline (por eso VARCHAR).
- No INNER JOIN de identificadores distintos (ej. `COD_MA` vs `CUM`) en staging.

## Debug rápido

| Síntoma | Causa habitual |
|---|---|
| Workflow colgado en Reset H2 | Falta `>nul 2>&1` en `start_h2.bat`; java/H2 huérfano |
| H2 vacío | Server reiniciado; in-memory se pierde |
| `${DB_H2_URL}` en el log | Proyecto Hop activo incorrecto o variable no definida |
| `Value too long` | VARCHAR con longitud; quitar longitud |
| R no ve la tabla | Falta clave en `lecturas` o STG no se cargó |
| `%ERRORLEVEL%` de R mal | Falta `call Rscript` + delayed expansion |
| `Falta pyyaml` / `oracledb` / `gspread` | `pip install -r python/requirements.txt` |
| Python create STG no-op inesperado | `inputs.yaml` tiene `sources: []` |
| GUI no lista tablas `STG_*` | No corriste `wf_create_stg`, o H2 se reinició (in-memory) |
