-- =============================================================================
-- APP — tabla destino local Acciones_Ubigeo (PIN) para RPT_ACCIONES_UBIGEO
-- Instancia: localhost:1524 / BD_CURSOR
-- Usuario  : app
-- JDBC     : jdbc:oracle:thin:@//localhost:1524/BD_CURSOR
--
-- Crear conectado como app. r/main.R hace TRUNCATE + INSERT (no CREATE).
-- =============================================================================

-- Requiere (como SYS): ALTER USER APP DEFAULT TABLESPACE USERS;
--                     ALTER USER APP QUOTA UNLIMITED ON USERS;
-- Evita ORA-01950 (sin privilegios en SYSTEM).

CREATE TABLE APP.RPT_ACCIONES_UBIGEO (
    TXCOORDINACION      VARCHAR2(4000),
    SUBSECTOR           VARCHAR2(4000),
    TXCUC               VARCHAR2(4000),
    FEFIN               DATE,
    IDADMINISTRADO      VARCHAR2(4000),
    IDUF_SIG            VARCHAR2(4000),
    TXTIPSUP            VARCHAR2(4000),
    TXFUENTE            VARCHAR2(4000),
    TXACCION            VARCHAR2(4000),
    FGSUP_ORIENTATIVA   VARCHAR2(4000),
    TXUBIGEO_INEI       VARCHAR2(4000),
    TXUBIGEO_INAF       VARCHAR2(4000),
    TXDEPARTAMENTO      VARCHAR2(4000),
    TXPROVINCIA         VARCHAR2(4000),
    TXDISTRITO          VARCHAR2(4000),
    FE_CARGA            DATE
) TABLESPACE USERS;

COMMENT ON TABLE  APP.RPT_ACCIONES_UBIGEO
    IS 'Reporte de acciones de supervisión por ubicación geográfica.';

COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXCOORDINACION
    IS 'Coordinación del OEFA (normalizada; sin prefijo "COORDINACIÓN DE")';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.SUBSECTOR
    IS 'Código de subsector: MIN, HID, ELE, IND, PES, AGR, CAM, RES, EDU, JUS, CUL, VCS';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXCUC
    IS 'Código Único de Control (CUC) de la supervisión';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.FEFIN
    IS 'Fecha fin de la supervisión';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.IDADMINISTRADO
    IS 'RUC o identificador del administrado supervisado';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.IDUF_SIG
    IS 'Identificador de la Unidad Fiscalizadora (seguimiento)';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXTIPSUP
    IS 'Tipo de supervisión (orientativa u otra)';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXFUENTE
    IS 'Fuente o denuncia que originó la supervisión';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXACCION
    IS 'Tipo de acción: IN SITU (presencial) o EN GABINETE';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.FGSUP_ORIENTATIVA
    IS 'Flag supervisión orientativa: 1 = sí, 0 = no';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXUBIGEO_INEI
    IS 'Código INEI del distrito del punto de intervención';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXUBIGEO_INAF
    IS 'Código INAF del distrito del punto de intervención';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXDEPARTAMENTO
    IS 'Departamento de la intervención';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXPROVINCIA
    IS 'Provincia de la intervención';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.TXDISTRITO
    IS 'Distrito de la intervención';
COMMENT ON COLUMN APP.RPT_ACCIONES_UBIGEO.FE_CARGA
    IS 'Fecha y hora de carga del registro (sello de corrida ETL)';

CREATE INDEX IDX_RPT_ACC_UBI_CUC ON APP.RPT_ACCIONES_UBIGEO (TXCUC) TABLESPACE USERS;
CREATE INDEX IDX_RPT_ACC_UBI_FEFIN ON APP.RPT_ACCIONES_UBIGEO (FEFIN) TABLESPACE USERS;
CREATE INDEX IDX_RPT_ACC_UBI_IDUF ON APP.RPT_ACCIONES_UBIGEO (IDUF_SIG) TABLESPACE USERS;
CREATE INDEX IDX_RPT_ACC_UBI_CARGA ON APP.RPT_ACCIONES_UBIGEO (FE_CARGA) TABLESPACE USERS;

-- Si la tabla ya existe (migración):
-- ALTER TABLE APP.RPT_ACCIONES_UBIGEO ADD (FE_CARGA DATE);
-- CREATE INDEX IDX_RPT_ACC_UBI_CARGA ON APP.RPT_ACCIONES_UBIGEO (FE_CARGA) TABLESPACE USERS;
