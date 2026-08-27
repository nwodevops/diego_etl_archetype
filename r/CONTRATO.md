# CONTRATO — Acciones PIN (capa R)

I/O genérico; lógica solo en `r/logica/` (un único `.R`).

```
r/main.R            orquesta: SETUP → io/leer_h2.R → logica/ → io/escribir_oracle.R
r/io/leer_h2.R      ENTRADA: H2 STG_* → Acciones / Documentos / AdminUF
r/logica/           LOGICA: acciones_pin.R (pristine)
r/io/escribir_oracle.R  SALIDA: Acciones_Ubigeo → RPT_ACCIONES_UBIGEO
```

Staging declarado en `inputs.yaml` → Python DDL → Hop extract → tablas H2:

| DF R | Tabla H2 | Vista Oracle |
|------|----------|--------------|
| `Acciones` | `PUBLIC.STG_ORA_ACCIONES` | `SISUD.CSEP_ACCIONES_VIEW` |
| `Documentos` | `PUBLIC.STG_ORA_DOCUMENTOS` | `SISUD.CSEP_DOCUMENTOS_VIEW` |
| `AdminUF` | `PUBLIC.STG_ORA_ADMINUF` | `SISUD.CSEP_ADMINUF_VIEW` |

## Entrada (columnas que lee `leer_h2.R`)

### `Acciones` (20 cols)
TXMES, TXCUC, TXESTADO, IDADMINISTRADO, TXADMINISTRADO_ADM, TXSUBSECTOR_UND,
TXSUBUNIDAD, TXUBIGEO_INAF, TXUBIGEO_INEI, TXDEPARTAMENTO, TXPROVINCIA, TXDISTRITO,
TXCOORDINACION, TXTIPSUP, TXFUENTE, TXACCION, FEFIN, FGSUPUPD_2DOTIEMPO,
FGSUP_ORIENTATIVA, IDUF_SIG

### `Documentos` (3 cols)
TXCUC, TXTIPO_DOC, FEFIN

### `AdminUF` (7 cols)
UF_SIG_ID, UF_TXESTADO, UF_UBIGEO_INAF, TXUBIGEO_INEI, UF_DPTO, UF_PROV, UF_DIST

## Salida

Data.frame **`Acciones_Ubigeo`** (`SALIDA_DF` en `main.R`) → Oracle
`APP|REPOCSEP.RPT_ACCIONES_UBIGEO` vía `DB_ORA_REPO_*` (+ `DB_ORA_REPO_SCHEMA`).

15 columnas: TXCOORDINACION, SUBSECTOR, TXCUC, FEFIN, IDADMINISTRADO, IDUF_SIG,
TXTIPSUP, TXFUENTE, TXACCION, FGSUP_ORIENTATIVA, TXUBIGEO_INEI, TXUBIGEO_INAF,
TXDEPARTAMENTO, TXPROVINCIA, TXDISTRITO.

DDL: `docs/rpt_acciones_ubigeo.sql` / `docs/rpt_acciones_ubigeo_local.sql`.

## Reglas

- En `r/logica/` no hay conexiones, jars ni `library()`.
- Exactamente un `.R` en `r/logica/`.
- No modificar el bloque pristine de `acciones_pin.R` salvo migración explícita.
- `options(java.parameters=...)` **antes** de RJDBC/rJava en `main.R`.
