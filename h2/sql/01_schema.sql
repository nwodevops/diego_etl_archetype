-- ============================================================
-- Schema H2 in-memory (mem:csep) para Acciones PIN.
-- Se ejecuta SIEMPRE despues del start del server H2
-- (h2/scripts/reset_and_create.* → sql/00_reset.sql → sql/01_schema.sql).
--
-- STG_* NO van aqui: las crea Python (inputs.yaml → 02_stg.sql) despues del reset.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS PUBLIC;
