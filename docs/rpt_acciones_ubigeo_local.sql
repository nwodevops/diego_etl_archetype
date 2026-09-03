-- =============================================================================
-- RPT_ACCIONES_UBIGEO — tabla destino Acciones_Ubigeo (PIN) en MySQL
-- Instancia: 10.1.1.217:3306 / gappsdb (local tambien usa este mismo MySQL)
-- Usuario  : gapps
-- JDBC     : jdbc:mysql://10.1.1.217:3306/gappsdb
--
-- Crear manualmente conectado como gapps (la DB gappsdb ya esta activa en la
-- URL). El script R r/main.R hace TRUNCATE + INSERT (no CREATE).
--
-- NOTA: local y remote comparten el MISMO MySQL 10.1.1.217/gappsdb.
-- Las columnas textuales usan VARCHAR(255): dan margen sobre el max real
-- (~82 chars en TXFUENTE) y caben en el limite de fila de InnoDB con utf8mb4
-- (65535 bytes) sin llegar a TEXT, permitiendo indexar TXCUC/IDUF_SIG.
-- =============================================================================

CREATE TABLE RPT_ACCIONES_UBIGEO (
    TXCOORDINACION      VARCHAR(255),
    SUBSECTOR           VARCHAR(255),
    TXCUC               VARCHAR(255),
    FEFIN               DATETIME,
    IDADMINISTRADO      VARCHAR(255),
    IDUF_SIG            VARCHAR(255),
    TXTIPSUP            VARCHAR(255),
    TXFUENTE            VARCHAR(255),
    TXACCION            VARCHAR(255),
    FGSUP_ORIENTATIVA   VARCHAR(255),
    TXUBIGEO_INEI       VARCHAR(255),
    TXUBIGEO_INAF       VARCHAR(255),
    TXDEPARTAMENTO      VARCHAR(255),
    TXPROVINCIA         VARCHAR(255),
    TXDISTRITO          VARCHAR(255),
    FE_CARGA            DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Comentarios (MySQL no soporta COMMENT ON TABLE/COLUMN como Oracle):
-- TXCOORDINACION     Coordinación del OEFA (normalizada; sin prefijo "COORDINACIÓN DE")
-- SUBSECTOR          Código de subsector: MIN, HID, ELE, IND, PES, AGR, CAM, RES, EDU, JUS, CUL, VCS
-- TXCUC              Código Único de Control (CUC) de la supervisión
-- FEFIN              Fecha fin de la supervisión
-- IDADMINISTRADO     RUC o identificador del administrado supervisado
-- IDUF_SIG           Identificador de la Unidad Fiscalizadora (seguimiento)
-- TXTIPSUP           Tipo de supervisión (orientativa u otra)
-- TXFUENTE           Fuente o denuncia que originó la supervisión
-- TXACCION           Tipo de acción: IN SITU (presencial) o EN GABINETE
-- FGSUP_ORIENTATIVA  Flag supervisión orientativa: 1 = sí, 0 = no
-- TXUBIGEO_INEI      Código INEI del distrito del punto de intervención
-- TXUBIGEO_INAF      Código INAF del distrito del punto de intervención
-- TXDEPARTAMENTO     Departamento de la intervención
-- TXPROVINCIA        Provincia de la intervención
-- TXDISTRITO         Distrito de la intervención
-- FE_CARGA           Fecha y hora de carga del registro (sello de corrida ETL)

CREATE INDEX IDX_RPT_ACC_UBI_CUC   ON RPT_ACCIONES_UBIGEO (TXCUC);
CREATE INDEX IDX_RPT_ACC_UBI_FEFIN ON RPT_ACCIONES_UBIGEO (FEFIN);
CREATE INDEX IDX_RPT_ACC_UBI_IDUF  ON RPT_ACCIONES_UBIGEO (IDUF_SIG);
CREATE INDEX IDX_RPT_ACC_UBI_CARGA ON RPT_ACCIONES_UBIGEO (FE_CARGA);

-- Verificación rápida:
-- SELECT COUNT(*), MAX(FE_CARGA) FROM RPT_ACCIONES_UBIGEO;
