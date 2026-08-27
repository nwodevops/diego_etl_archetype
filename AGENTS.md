# AGENTS.md — diego_etl_archetype (Acciones PIN)

ETL **Acciones PIN** sobre el arquetipo OEFA Hop: `inputs.yaml` + Python DDL `STG_*` →
Hop extract → H2 → R → Oracle `RPT_ACCIONES_UBIGEO`.

**Skill:** [`.agents/skills/oefa-hop-etl/SKILL.md`](.agents/skills/oefa-hop-etl/SKILL.md)

## Flujo

```
inputs.yaml (3 vistas SISUD)
  → python/create_stg.py          CREATE TABLE STG_ORA_*
  → pl_stage_{acciones,adminuf,documentos}.hpl
  → H2 mem:csep
  → r/logica/acciones_pin.R
  → Oracle APP|REPOCSEP.RPT_ACCIONES_UBIGEO
```

| Path | Rol |
|------|-----|
| `inputs.yaml` | Declara fuentes → `STG_ORA_*` |
| `workflows/wf_create_stg.hwf` | Diseño: Reset + Python STG (H2 vivo) |
| `workflows/wf_main.hwf` | Corrida completa |
| `pipelines/pl_stage_*.hpl` | Oracle → H2 truncate |
| `r/logica/acciones_pin.R` | Lógica pristine |
| `r/CONTRATO.md` | Contrato R |
| `docs/conexion-*.txt` | Fuente de verdad credenciales |
| `docs/rpt_acciones_ubigeo*.sql` | DDL destino |
| `switch-env.ps1` | `local\|remote` → `project-config.json` |

## Entornos

| | local | remote |
|---|-------|--------|
| OS | Linux (`SCRIPT_EXT=sh`) | Windows (`SCRIPT_EXT=bat`) |
| Input | `DB_ORA_SISUD_*` | `DB_ORA_SISUD_*` |
| Output | `DB_ORA_REPO_*` schema `APP` | `DB_ORA_REPO_*` schema `REPOCSEP` |
| H2 | `mem:csep` :9092 | igual |

Credenciales: actualizar primero `docs/conexion-*.txt`, luego `environments/*` y el
`project-config.json` activo.

## Cómo ejecutar

1. `pip install -r python/requirements.txt`
2. Entorno en `project-config.json` (`SCRIPT_EXT` + DBs).
3. Diseño STG: Play `wf_create_stg` → H2 con `STG_*` vacías.
4. Corrida: Play `wf_main`.

Orden `wf_main`: Reset H2 → Python STG → Acciones → AdminUF → Documentos → Run R → Success.

## Reglas para agentes

1. Responder en español.
2. No inventar conexiones, tablas ni columnas.
3. Fuentes nuevas: `inputs.yaml` → `wf_create_stg` → `pl_stage_*.hpl` → `lecturas` en `leer_h2.R`.
4. No poner `STG_*` en `h2/sql/01_schema.sql` (opción B: Python después del reset).
5. Un solo `.R` en `r/logica/`; no tocar pristine salvo pedido explícito.
6. Salida Oracle legado (`escribir_oracle` + `DB_ORA_REPO_*`); no MySQL/Excel para este ETL.
7. Mantener pares `.sh` / `.bat` en sync.
8. `options(java.parameters=...)` antes de RJDBC.
9. No commitear secretos ni `h2/sql/02_stg.sql` (generado).

## Gotchas

- H2 in-memory: cada reset borra la BD; Python debe recrear `STG_*` en cada corrida.
- Metadata Hop: `oracle_sisud` (input), `h2` (staging). Write Oracle solo en R.
- Heap R `-Xmx6g` (Documentos ~724k filas).
- `pl_demo.hpl` es legado del arquetipo; la corrida usa `pl_stage_*`.
