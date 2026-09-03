# AGENTS.md — diego_etl_archetype (Acciones PIN)

ETL **Acciones PIN** sobre el arquetipo OEFA Hop: `inputs.yaml` + Python DDL `STG_*` →
Hop extract → H2 → R → MySQL `RPT_ACCIONES_UBIGEO` (gappsdb).

**Skill:** [`.agents/skills/oefa-hop-etl/SKILL.md`](.agents/skills/oefa-hop-etl/SKILL.md)

## Flujo

```
inputs.yaml (3 vistas SISUD)
  → python/create_stg.py          CREATE TABLE STG_ORA_*
  → pl_stage_{acciones,adminuf,documentos}.hpl
  → H2 mem:csep
  → r/logica/acciones_pin.R
  → MySQL gappsdb.RPT_ACCIONES_UBIGEO  (10.1.1.217:3306, DB_MYSQL_*)
```

| Path | Rol |
|------|-----|
| `inputs.yaml` | Declara fuentes → `STG_ORA_*` |
| `python/create_stg.py` | Introspect + DDL H2 (no extrae filas) |
| `python/jdbc_util.py` | JVM única + jars `lib/` + `h2/lib/` (ojdbc11, H2) |
| `python/run_create_stg.{sh,bat}` | Wrapper Hop; chequea deps / usa `.venv` |
| `workflows/wf_create_stg.hwf` | Diseño: Reset + Python STG (H2 vivo) |
| `workflows/wf_main.hwf` | Corrida completa |
| `pipelines/pl_stage_*.hpl` | Oracle → H2 truncate |
| `r/run_main.{sh,bat}` | Wrapper R (bat resuelve Rscript en PATH/latest) |
| `r/logica/acciones_pin.R` | Lógica pristine |
| `r/CONTRATO.md` | Contrato R |
| `docs/conexion-*.txt` | Fuente de verdad credenciales |
| `docs/rpt_acciones_ubigeo*.sql` | DDL destino |
| `switch-env.ps1` | `local\|remote` → `project-config.json` |
| `run_wf_main.bat` | Corrida headless Windows (`hop-run` → `wf_main`) |

## Entornos

| | local | remote |
|---|-------|--------|
| OS | Linux (`SCRIPT_EXT=sh`) | Windows (`SCRIPT_EXT=bat`) |
| Input | `DB_ORA_SISUD_*` | `DB_ORA_SISUD_*` |
| Output | `DB_MYSQL_*` (`gappsdb` 10.1.1.217:3306) | `DB_MYSQL_*` (mismo MySQL que local) |
| H2 | `mem:csep` :9092 | igual |

Credenciales: actualizar primero `docs/conexion-*.txt`, luego `environments/*` y el
`project-config.json` activo. En Hop el proyecto activo debe ser **`diego_etl_archetype`**.

## Cómo ejecutar

1. Deps Python (una vez por máquina):
   - Linux: `python3 -m pip install --user --break-system-packages -r python/requirements.txt`
     (o `python3 -m venv .venv && .venv/bin/pip install -r python/requirements.txt`)
   - Windows: `python -m pip install -r python\requirements.txt`
     (o `python -m venv .venv` + `.venv\Scripts\pip install -r python\requirements.txt`)
2. Entorno: `.\switch-env.ps1 local|remote` (o copiar `environments/<env>.json` → vars de `project-config.json`).
3. Diseño STG: Play `wf_create_stg` → H2 con `STG_*` vacías.
4. Corrida: Play `wf_main`.

Orden `wf_main`: Reset H2 → Python STG → Acciones → AdminUF → Documentos → Run R → Success.

## Scheduling Windows (8:00 y 13:00)

Corrida diaria en remote **sin Hop GUI**: Programador de tareas + [`run_wf_main.bat`](run_wf_main.bat).

1. Una vez: `.\switch-env.ps1 remote`, deps Python, R y Java en PATH; proyecto Hop registrado como `diego_etl_archetype`.
2. Probar a mano: `run_wf_main.bat` (override `set HOP_HOME=...` si Hop no está en `D:\Eder\hop`).
3. `taskschd.msc` → Crear tarea:
   - Desencadenadores: diario **08:00** y diario **13:00**.
   - Acción: `D:\Eder\workspace_etl_oefa\diego_etl_archetype\run_wf_main.bat`
   - Si ya corre → no iniciar nueva instancia (evitar solapes).
   - Ejecutar aunque el usuario no haya iniciado sesión (según política OEFA).

No programar el `Start` del `.hwf` en el GUI (`schedulerType=0`); usar Task Scheduler + `hop-run`.

## Python STG (introspect)

- Oracle fuente: introspección por **JDBC `lib/ojdbc11.jar`** (`python/introspect/oracle.py` + `jdbc_util.py`), no `oracledb` thin (falla en Oracle 23ai+ con DPY-3015).
- H2 apply DDL: mismo classpath (jars registrados **antes** del primer connect; una sola JVM).
- Wrappers fallan con mensaje claro si falta `yaml` / deps; no es un fallo de Hop.

## Reglas para agentes

1. Responder en español.
2. No inventar conexiones, tablas ni columnas.
3. Fuentes nuevas: `inputs.yaml` → `wf_create_stg` → `pl_stage_*.hpl` → `lecturas` en `leer_h2.R`.
4. No poner `STG_*` en `h2/sql/01_schema.sql` (opción B: Python después del reset).
5. Un solo `.R` en `r/logica/`; no tocar pristine salvo pedido explícito.
6. Salida a MySQL `RPT_ACCIONES_UBIGEO` (`escribir_oracle.R` + `DB_MYSQL_*`); no Oracle ni Excel para este ETL.
7. Mantener pares `.sh` / `.bat` en sync.
8. `options(java.parameters=...)` antes de RJDBC.
9. No commitear `h2/sql/02_stg.sql`, `__pycache__/`, `.venv/` (gitignore). Credenciales van en texto plano (patrón del repo); no propagar fuera.

## Gotchas

- H2 in-memory: cada reset borra la BD; Python debe recrear `STG_*` en cada corrida.
- Si tras stop sale `H2 ya esta arriba en puerto 9092`, hay Java/H2 huérfano: matar proceso y rerun (o `h2/scripts/stop_h2.*`).
- Metadata Hop: `oracle_sisud` (input), `h2` (staging). Write MySQL solo en R (`mysql`).
- Heap R `-Xmx6g` (Documentos ~724k filas).
- En log Hop, `message()` de R sale como `[Error]` en stderr aunque `result=[true]`.
- `pl_demo.hpl` es legado del arquetipo; la corrida usa `pl_stage_*`.
- Plugin Git de Hop puede loguear `MissingObjectException`; no aborta el workflow.
