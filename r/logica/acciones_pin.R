# =============================================================================
# logica/acciones_pin.R  --  LOGICA DE NEGOCIO (bloque pristine, no modificar)
#
# Contrato de entrada (variables en el entorno, dejadas por r/io/leer_h2.R):
#   Acciones   : data.frame con las columnas de SISUD.CSEP_ACCIONES_VIEW
#   Documentos : data.frame con las columnas de SISUD.CSEP_DOCUMENTOS_VIEW
#   AdminUF    : data.frame con las columnas de SISUD.CSEP_ADMINUF_VIEW
#
# Contrato de salida (queda en el entorno):
#   Acciones_Ubigeo : data.frame de 15 columnas (ver r/CONTRATO.md)
#
# El bloque de abajo es la logica del developer: NO MODIFICAR.
# =============================================================================
# =============================================================================
# Lógica pristine (copiada de docs/new_version/Acciones_actualizado (2).R) — no modificar
# =============================================================================

#Periodo
Desde<- as.Date("2017-01-01")


# Revisión de carga de documentos ----
CargaDocs_R2 <- Documentos %>%
  filter(FEFIN>=as.Date("2016-01-01"))%>%
  distinct(TXCUC,TXTIPO_DOC) %>%  # Quitamos Duplicados
  filter(str_detect(TXTIPO_DOC,"^Acta de Supervisión$|^Documento de Registro de Informacion$|^Acta$")) %>%
  mutate(ACC_DOC = 1) %>%
  distinct(TXCUC, ACC_DOC)

RegionUF<- AdminUF %>%
  filter(str_detect(UF_TXESTADO,"^ACTIVO$"), !is.na(UF_SIG_ID), !is.na(UF_UBIGEO_INAF)) %>%
  distinct(UF_SIG_ID,TXUBIGEO_INEI,UF_UBIGEO_INAF,UF_DPTO, UF_PROV, UF_DIST) %>%
  rename("IDUF_SIG" = UF_SIG_ID,
         "TXUBIGEO_INAF" = UF_UBIGEO_INAF,
         "TXDEPARTAMENTO" = UF_DPTO ,
         "TXPROVINCIA" = UF_PROV,
         "TXDISTRITO" =  UF_DIST)


#Acciones e Informes 2018
Acciones_R2 <- Acciones %>%
  filter(!str_detect(TXCOORDINACION,"SOCIOAMB")) %>%
  filter(FEFIN >= Desde) %>%
  mutate(IDADMINISTRADO = ifelse(str_detect(TXADMINISTRADO_ADM,"^NO DETERMINA"),NA_character_,IDADMINISTRADO),
         IDUF_SIG = ifelse(str_detect(TXSUBUNIDAD,"^NO DETERMINA"),NA_character_,IDUF_SIG)) %>%
  left_join(CargaDocs_R2, by = "TXCUC") %>%
  mutate(
    ACC_DOC = ifelse(is.na(ACC_DOC),0,ACC_DOC),
    ANO_SUP = year(FEFIN),
  #Tipo de Acción
  TXACCION = case_when(
    str_detect(TXACCION,"^PRESENCIAL|^IN SITU") ~ "IN SITU",
    str_detect(TXACCION,"^NO PRESENCIAL|^EN GABINETE") ~ "EN GABINETE"),

  #Acciones
  ACC_EJEC= case_when(
      str_detect(TXESTADO,"^ANÁLISIS DE RESULTADOS$|^CON RESULTADOS$|^CONCLUIDO$|^EJECUTADA$|^EN CUSTODIA$") ~ 1,
      TRUE ~ 0),
  ACC_CLEAN= case_when(
      ACC_EJEC==1 & FGSUPUPD_2DOTIEMPO=="1" & TXACCION=="IN SITU" & ACC_DOC==1       ~ 1,
      ACC_EJEC==1 & FGSUPUPD_2DOTIEMPO=="1" & TXACCION=="EN GABINETE" & ACC_DOC==1   ~ 1,
      ACC_EJEC==1 & FGSUPUPD_2DOTIEMPO=="1" & TXACCION=="EN GABINETE" & ACC_DOC==0   ~ 1)) %>%
  distinct(TXCUC,TXUBIGEO_INEI, .keep_all = TRUE) %>%
  #Estandarizamos coordinaciones
  mutate(TXCOORDINACION = str_replace_all(TXCOORDINACION,c("COORDINACIÓN DE SUPERVISIÓN AMBIENTAL EN " = "",
                                                           "COORDINACIÓN DE SEGUIMIENTO Y VERIFICACIÓN A LAS " = "",
                                                           "COORDINACIÓN DE " = "",
                                                           "OFICINA DE ENLACE" = "OE",
                                                           "OFICINA DESCONCENTRADA DE" = "OD",
                                                           "OFICINA ITINERANTE" = "OI",
                                                           "BIOSEGURIDAD - OVM" = "AGRICULTURA")),
         TXCOORDINACION = case_when(str_detect(TXCOORDINACION, "PESQ") ~ "PESCA",
                                    str_detect(TXCOORDINACION, "RESIDUOS SÓLIDOS") ~ "RESIDUOS SOLIDOS",
                                    str_detect(TXCOORDINACION, "VIVIENDA") ~ "VIVIENDA Y CONSTRUCCION",
                                    str_detect(TXCOORDINACION, "EDUCACIÓN") ~ "EDUCACION, JUSTICIA Y CULTURA",
                                    TRUE ~ TXCOORDINACION)) %>%
  #Subsectores
  mutate(
    SUBSECTOR =
      case_when(str_detect(TXCOORDINACION,"MINE") ~ "MIN",
                str_detect(TXCOORDINACION,"HIDR") ~ "HID",
                str_detect(TXCOORDINACION,"ELEC") ~ "ELE",
                str_detect(TXCOORDINACION,"INDU") ~ "IND",
                str_detect(TXCOORDINACION,"PESC") ~ "PES",
                str_detect(TXCOORDINACION,"AGRI") ~ "AGR",
                str_detect(TXCOORDINACION,"CONSUL") ~ "CAM",
                str_detect(TXCOORDINACION,"RESI") ~ "RES",
                str_detect(TXCOORDINACION, "EDUCA") & str_detect(TXSUBSECTOR_UND,"EDUCA") ~ "EDU",
                str_detect(TXCOORDINACION, "EDUCA") & str_detect(TXSUBSECTOR_UND,"JUST") ~ "JUS",
                str_detect(TXCOORDINACION, "EDUCA") & str_detect(TXSUBSECTOR_UND,"CULT") ~ "CUL",
                str_detect(TXCOORDINACION, "VIVIENDA") ~ "VCS",
                #Oficinas desconcentradas / enlace / itinerantes
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & is.na(TXSUBSECTOR_UND) ~ "HID",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "HIDRO") ~ "HID",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "RESID") ~ "RES",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "AGR") ~ "AGR",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "PES") ~ "PES",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "IND") ~ "IND",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "ELE") ~ "ELE",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "EDU") ~ "EDU",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "JUST") ~ "JUS",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "CULT") ~ "CUL",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "VIV") ~ "VCS",
                str_detect(TXCOORDINACION, "^(OD|OE|OI)") & str_detect(TXSUBSECTOR_UND, "CONSUL") ~ "CAM",
                TRUE ~ TXCOORDINACION),
    #Direcciones
    DIREC = case_when(
      str_detect(TXCOORDINACION,"OD|OE|OI") ~ "CODE",
      str_detect(SUBSECTOR,"MIN|HID|ELE") ~ "DSEM",
      str_detect(SUBSECTOR,"IND|PES|AGR") ~ "DSAP",
      str_detect(SUBSECTOR,"EDU|JUS|CUL|RES|VCS|CAM") ~ "DSIS",
      # str_detect(SUBSECTOR,"CAM") & FEFIN >= as.Date("2026-08-01") ~ "DSIS",
      TRUE ~ "DPEF"),
  # Factorizamos los niveles de MES
    TXMES = factor(TXMES, levels = c("ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
                                     "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE")),
  # #Standarizamos fuente
    TXFUENTE= case_when(
      str_detect(TXFUENTE,"OTRAS CIRCUNSTANCIAS") ~ "OTRAS CIRCUNSTANCIAS",
      str_detect(TXFUENTE,"ACCIDENTE O EMERGENCIA DE CARÁCTER AMBIENTAL") ~ "EMERGENCIA AMBIENTAL",
      str_detect(TXFUENTE,"DENUNCIAS") ~ "DENUNCIA AMBIENTAL",
      str_detect(TXFUENTE,"SOLICITUDES DE INTERVENCIÓN FORMULADAS POR ORGANISMOS PÚBLICOS") ~ "SOLICITUD DE INTERVENCIÓN FORMULADA POR UN ORGANISMO PÚBLICO",
      str_detect(TXFUENTE,"VERIFICACIÓN DE MEDIDAS ADMINISTRATIVAS") ~ "VERIFICACIÓN DEL CUMPLIMIENTO DE LAS MEDIDAS ADMINISTRATIVAS ORDENADAS POR EL OEFA",
      str_detect(TXFUENTE,"VERIFICACIÓN DE ACUERDO") ~ "VERIFICACIÓN DE ACUERDO DE CUMPLIMIENTO",
      str_detect(TXFUENTE,"TERMINACIÓN DE ACTIVIDADES") ~ "TERMINACIÓN DE ACTIVIDADES TOTAL O PARCIAL",
      str_detect(TXFUENTE, "PLANEFA") ~ "PLANEFA",
      TRUE ~ TXFUENTE))


#Regiones Desagregado
if("dpto"=="dpto"){

  #Acciones In situ
  Acc_insitu<- Acciones_R2 %>%
    filter(str_detect(TXACCION,"IN SITU"),
           ACC_CLEAN==1) %>%
    distinct(TXCOORDINACION,SUBSECTOR,TXCUC,FEFIN,IDADMINISTRADO,IDUF_SIG,TXTIPSUP,TXFUENTE,TXACCION,FGSUP_ORIENTATIVA,TXUBIGEO_INEI,TXUBIGEO_INAF,TXDEPARTAMENTO,TXPROVINCIA,TXDISTRITO)

  # Acciones en gabinete
  Acc_gabinete<- Acciones_R2 %>%
    filter(str_detect(TXACCION,"EN GABINETE"),
           ACC_CLEAN==1) %>%
    distinct(TXMES,TXCOORDINACION,SUBSECTOR,TXCUC,TXTIPSUP,TXFUENTE,FEFIN,IDADMINISTRADO,IDUF_SIG,TXACCION, FGSUP_ORIENTATIVA) %>%
    left_join(RegionUF, relationship = "many-to-many") %>%
    distinct(TXCOORDINACION,SUBSECTOR,TXCUC,FEFIN,IDADMINISTRADO,IDUF_SIG,TXTIPSUP,TXFUENTE,TXACCION,FGSUP_ORIENTATIVA,TXUBIGEO_INEI,TXUBIGEO_INAF,TXDEPARTAMENTO,TXPROVINCIA,TXDISTRITO)
  Acciones_Ubigeo<- bind_rows(Acc_insitu, Acc_gabinete) %>% mutate(FEFIN = as.Date(FEFIN)) %>%
    arrange(FEFIN)

  rm(Acc_insitu,Acc_gabinete)
}
