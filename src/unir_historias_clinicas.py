# =============================================================================
# unir_historias_clinicas.py
# Proyecto: Unificador de Historias Clínicas en PDF
# Autor: Mauricio Sánchez
# Descripción: Versión Python del unificador. Agrupa, ordena y une PDFs de
#              historias clínicas por paciente, especialidad y fecha.
# Requisito: pypdf instalado (pip install pypdf)
# =============================================================================

import os
import re
import unicodedata
import logging
from pathlib import Path
from datetime import datetime
from pypdf import PdfWriter, PdfReader

# -----------------------------------------------------------------------------
# CONFIGURACIÓN
# -----------------------------------------------------------------------------

RAIZ_SOPORTES   = r"C:\SOPORTES"
RAIZ_SALIDA     = r"C:\SOPORTES\SALIDA"
RAIZ_LOGS       = r"C:\SOPORTES\LOGS"
RAIZ_TEMP       = r"C:\SOPORTES\TEMP_PDFS"

# Dejar vacío para procesar todos los meses, o especificar uno: "ENERO"
MES_ESPECIFICO  = ""

MESES = [
    "ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
    "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"
]

# -----------------------------------------------------------------------------
# ORDEN DE DOCUMENTOS EN LA HISTORIA CLÍNICA
# -----------------------------------------------------------------------------

ORDEN_DOCUMENTOS = [
    "HC", "HISTORIA_CLINICA", "ANAMNESIS",
    "MEDICAMENTOS", "FORMULA_MEDICA",
    "LABORATORIO", "RESULTADO_LAB",
    "AYUDA_DIAGNOSTICA", "IMAGEN", "ECOGRAFIA", "RADIOGRAFIA", "TAC", "RMN",
    "REMISIONES_CE", "REMISION", "CONTRARREMISION",
    "PROCEDIMIENTOS", "CIRUGIA",
    "RECOMENDACIONES", "EGRESO", "EPICRISIS",
    "CONSULTAS_E_INTERCONSULTAS", "INTERCONSULTA",
    "CONSENTIMIENTO", "CERTIFICADO"
]

# -----------------------------------------------------------------------------
# ESPECIALIDADES — PATRONES DE DETECCIÓN
# -----------------------------------------------------------------------------

ESPECIALIDADES = {
    "MEDICINA_GENERAL"          : ["MEDICINA_GENERAL", "MDGENERAL", "MED_GENERAL", "CONSULTA_GENERAL"],
    "MEDICINA_INTERNA"          : ["MEDICINA_INTERNA", "MDINTERNA", "MED_INTERNA", "INTERNISTA"],
    "URGENCIAS"                 : ["URGENCIA", "EMERGENCIA", "TRIAGE"],
    "CIRUGIA_GENERAL"           : ["CIRUGIA_GENERAL", "CX_GENERAL"],
    "CIRUGIA_ORTOPEDIA"         : ["ORTOPEDIA", "TRAUMATOLOGIA", "ORTOPEDISTA"],
    "CIRUGIA_PLASTICA"          : ["CIRUGIA_PLASTICA", "PLASTICA", "RECONSTRUCTIVA"],
    "GINECOLOGIA"               : ["GINECOLOGIA", "GINECO", "OBSTETRICIA"],
    "PEDIATRIA"                 : ["PEDIATRIA", "PEDIATRICO", "NEONATOLOGIA"],
    "CARDIOLOGIA"               : ["CARDIOLOGIA", "CARDIOLOGO"],
    "NEUROLOGIA"                : ["NEUROLOGIA", "NEUROLOGO"],
    "NEUROCIRUGIA"              : ["NEUROCIRUGIA", "NEUROCIRUJANO"],
    "PSIQUIATRIA"               : ["PSIQUIATRIA", "PSIQUIATRA", "SALUD_MENTAL"],
    "PSICOLOGIA"                : ["PSICOLOGIA", "PSICOLOGO", "PSICOLOGA"],
    "FISIOTERAPIA"              : ["FISIOTERAPIA", "FISIOTERAPEUTA", "REHABILITACION_FISICA"],
    "TERAPIA_OCUPACIONAL"       : ["TERAPIA_OCUPACIONAL", "TERAPEUTA_OCUPACIONAL"],
    "FONOAUDIOLOGIA"            : ["FONOAUDIOLOGIA", "FONOAUDIOLOGO", "LENGUAJE"],
    "NUTRICION"                 : ["NUTRICION", "NUTRICIONISTA", "DIETETICA"],
    "TRABAJO_SOCIAL"            : ["TRABAJO_SOCIAL", "TRABAJADOR_SOCIAL"],
    "ENFERMERIA"                : ["ENFERMERIA", "ENFERMERO", "ENFERMERA"],
    "REUMATOLOGIA"              : ["REUMATOLOGIA", "REUMATOLOGO"],
    "ENDOCRINOLOGIA"            : ["ENDOCRINOLOGIA", "ENDOCRINOLOGO"],
    "GASTROENTEROLOGIA"         : ["GASTROENTEROLOGIA", "GASTROENTEROLOGO"],
    "NEUMOLOGIA"                : ["NEUMOLOGIA", "NEUMOLOGO", "PULMONOLOGIA"],
    "DERMATOLOGIA"              : ["DERMATOLOGIA", "DERMATOLOGO"],
    "OFTALMOLOGIA"              : ["OFTALMOLOGIA", "OFTALMOLOGO", "OPTOMETRIA"],
    "OTORRINOLARINGOLOGIA"      : ["OTORRINOLARINGOLOGIA", "OTORRINO", "ORL"],
    "UROLOGIA"                  : ["UROLOGIA", "UROLOGO"],
    "NEFROLOGIA"                : ["NEFROLOGIA", "NEFROLOGO"],
    "HEMATOLOGIA"               : ["HEMATOLOGIA", "HEMATOLOGO", "ONCOHEMATOLOGIA"],
    "ONCOLOGIA"                 : ["ONCOLOGIA", "ONCOLOGO", "QUIMIOTERAPIA"],
    "INFECTOLOGIA"              : ["INFECTOLOGIA", "INFECTOLOGO"],
    "GERIATRIA"                 : ["GERIATRIA", "GERIATRA"],
    "MEDICINA_FISICA"           : ["MEDICINA_FISICA", "REHABILITACION_ESPECIALISTA", "FISIATRA"],
    "DOLOR_PALIATIVOS"          : ["DOLOR", "PALIATIVO", "PALIATIVOS"],
    "MEDICINA_LABORAL"          : ["MEDICINA_LABORAL", "SALUD_TRABAJO", "SALUD_OCUPACIONAL"],
    "ODONTOLOGIA"               : ["ODONTOLOGIA", "ODONTOLOGO", "DENTAL"],
    "BACTERIOLOGIA"             : ["BACTERIOLOGIA", "BACTERIOLOGO", "LABORATORIO_CLINICO"],
}

# -----------------------------------------------------------------------------
# FUNCIONES AUXILIARES
# -----------------------------------------------------------------------------

def limpiar_texto(texto: str) -> str:
    """Elimina tildes y caracteres especiales, convierte a mayúsculas."""
    nfkd = unicodedata.normalize("NFD", texto)
    sin_tildes = "".join(c for c in nfkd if unicodedata.category(c) != "Mn")
    limpio = re.sub(r"[^A-Z0-9_.\-]", "_", sin_tildes.upper())
    return limpio


def detectar_especialidad(nombre: str) -> str:
    """Detecta la especialidad médica según el nombre del archivo."""
    for esp, patrones in ESPECIALIDADES.items():
        for patron in patrones:
            if patron in nombre:
                return esp
    return "GENERAL"


def ordenar_pdfs(archivos: list) -> list:
    """Ordena los PDFs según el orden clínico definido."""
    ordenados = []
    usados = set()

    for cat in ORDEN_DOCUMENTOS:
        for arch in archivos:
            nombre = Path(arch).stem.upper()
            if cat in nombre and arch not in usados:
                ordenados.append(arch)
                usados.add(arch)

    for arch in archivos:
        if arch not in usados:
            ordenados.append(arch)

    return ordenados


def configurar_log(ruta_logs: str) -> logging.Logger:
    """Configura el sistema de logging."""
    os.makedirs(ruta_logs, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    archivo_log = os.path.join(ruta_logs, f"log_{timestamp}.txt")

    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.FileHandler(archivo_log, encoding="utf-8"),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# FUNCIÓN PRINCIPAL — PROCESAR UN MES
# -----------------------------------------------------------------------------

def procesar_mes(ruta_mes: str, nombre_mes: str, logger: logging.Logger) -> dict:
    """Procesa todos los PDFs de un mes y genera los archivos unificados."""

    logger.info("=" * 55)
    logger.info(f"PROCESANDO MES: {nombre_mes}")
    logger.info(f"RUTA: {ruta_mes}")
    logger.info("=" * 55)

    temp_mes   = os.path.join(RAIZ_TEMP, nombre_mes)
    salida_mes = os.path.join(RAIZ_SALIDA, nombre_mes)

    os.makedirs(temp_mes,   exist_ok=True)
    os.makedirs(salida_mes, exist_ok=True)

    pdfs_encontrados = 0
    grupos = {}

    for archivo in Path(ruta_mes).glob("*.pdf"):
        nombre_limpio = limpiar_texto(archivo.stem) + ".pdf"
        destino = os.path.join(temp_mes, nombre_limpio)
        import shutil
        shutil.copy2(str(archivo), destino)
        pdfs_encontrados += 1

    logger.info(f"PDFs encontrados: {pdfs_encontrados}")

    if pdfs_encontrados == 0:
        logger.warning(f"No se encontraron PDFs en {ruta_mes}")
        return {"creados": 0, "errores": 0}

    for archivo in Path(temp_mes).glob("*.pdf"):
        nombre = archivo.stem.upper()

        match_fecha = re.search(r"(20\d{6})$", nombre)
        if not match_fecha:
            logger.warning(f"SIN FECHA: {archivo.name} — omitido")
            continue
        fecha = match_fecha.group(1)

        match_doc = re.search(r"(CC|TI|RC|SC|PT|CE|PA|MS|AS)\d+", nombre)
        if not match_doc:
            logger.warning(f"SIN DOCUMENTO: {archivo.name} — omitido")
            continue
        id_paciente = match_doc.group(0)

        especialidad = detectar_especialidad(nombre)
        key = f"{id_paciente}|{especialidad}|{fecha}"

        if key not in grupos:
            grupos[key] = []
        grupos[key].append(str(archivo))

    total_creados = 0
    total_errores = 0

    for key, archivos in grupos.items():
        id_paciente, especialidad, fecha = key.split("|")
        archivos_ordenados = ordenar_pdfs(archivos)

        nombre_salida = f"{id_paciente}_HC_{especialidad}_{fecha}.pdf"
        ruta_salida   = os.path.join(salida_mes, nombre_salida)

        logger.info(f"UNIENDO | {id_paciente} | {especialidad} | {fecha} | {len(archivos_ordenados)} PDFs")

        try:
            writer = PdfWriter()
            for ruta_pdf in archivos_ordenados:
                reader = PdfReader(ruta_pdf)
                for pagina in reader.pages:
                    writer.add_page(pagina)

            with open(ruta_salida, "wb") as f:
                writer.write(f)

            logger.info(f"OK: {ruta_salida}")
            total_creados += 1

        except Exception as e:
            logger.error(f"ERROR en {nombre_salida}: {e}")
            total_errores += 1

    import shutil
    shutil.rmtree(temp_mes, ignore_errors=True)

    logger.info(f"MES {nombre_mes} — Creados: {total_creados} | Errores: {total_errores}")
    return {"creados": total_creados, "errores": total_errores}


# -----------------------------------------------------------------------------
# EJECUCIÓN PRINCIPAL
# -----------------------------------------------------------------------------

def ejecutar():
    os.makedirs(RAIZ_SALIDA, exist_ok=True)
    os.makedirs(RAIZ_LOGS,   exist_ok=True)
    os.makedirs(RAIZ_TEMP,   exist_ok=True)

    logger = configurar_log(RAIZ_LOGS)
    logger.info("INICIANDO UNIFICADOR DE HISTORIAS CLÍNICAS")

    meses_a_procesar = [MES_ESPECIFICO.upper()] if MES_ESPECIFICO else MESES

    resumen = {"meses": 0, "creados": 0, "errores": 0}

    for mes in meses_a_procesar:
        ruta_mes = os.path.join(RAIZ_SOPORTES, mes)
        if os.path.exists(ruta_mes):
            resultado = procesar_mes(ruta_mes, mes, logger)
            resumen["meses"]   += 1
            resumen["creados"] += resultado["creados"]
            resumen["errores"] += resultado["errores"]
        else:
            logger.info(f"OMITIDO: No existe la carpeta {ruta_mes}")

    logger.info("=" * 55)
    logger.info("PROCESO COMPLETADO")
    logger.info(f"Meses procesados : {resumen['meses']}")
    logger.info(f"PDFs creados     : {resumen['creados']}")
    logger.info(f"Errores          : {resumen['errores']}")
    logger.info(f"Salida           : {RAIZ_SALIDA}")
    logger.info("=" * 55)


if __name__ == "__main__":
    ejecutar()
