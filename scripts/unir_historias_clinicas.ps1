# =============================================================================
# unir_historias_clinicas.ps1
# Proyecto: Unificador de Historias Clínicas en PDF
# Autor: Mauricio Sánchez
# Descripción: Agrupa, ordena y une PDFs de historias clínicas por paciente,
#              especialidad y fecha. Compatible con todos los meses del año.
# Requisito: pdftk instalado en el sistema
# =============================================================================


# =============================================================================
# CONFIGURACIÓN — AJUSTAR SEGÚN EL SERVIDOR O EQUIPO
# =============================================================================

$RAIZ_SOPORTES  = "C:\SOPORTES"
$RAIZ_SALIDA    = "C:\SOPORTES\SALIDA"
$RAIZ_LOGS      = "C:\SOPORTES\LOGS"
$RAIZ_TEMP      = "C:\SOPORTES\TEMP_PDFS"

# Procesar todos los meses o solo uno específico
# Dejar vacío para procesar todos los meses disponibles
$MES_ESPECIFICO = ""   # Ejemplo: "ENERO", "FEBRERO" — dejar "" para todos


# =============================================================================
# MESES VÁLIDOS
# =============================================================================

$MESES = @(
    "ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
    "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"
)


# =============================================================================
# ORDEN DE DOCUMENTOS EN LA HISTORIA CLÍNICA
# =============================================================================

$ORDEN_DOCUMENTOS = @(
    "HC",
    "HISTORIA_CLINICA",
    "ANAMNESIS",
    "MEDICAMENTOS",
    "FORMULA_MEDICA",
    "LABORATORIO",
    "RESULTADO_LAB",
    "AYUDA_DIAGNOSTICA",
    "IMAGEN",
    "ECOGRAFIA",
    "RADIOGRAFIA",
    "TAC",
    "RMN",
    "REMISIONES_CE",
    "REMISION",
    "CONTRARREMISION",
    "PROCEDIMIENTOS",
    "CIRUGIA",
    "RECOMENDACIONES",
    "EGRESO",
    "EPICRISIS",
    "CONSULTAS_E_INTERCONSULTAS",
    "INTERCONSULTA",
    "CONSENTIMIENTO",
    "CERTIFICADO"
)


# =============================================================================
# ESPECIALIDADES MÉDICAS — DETECCIÓN AUTOMÁTICA POR NOMBRE DE ARCHIVO
# =============================================================================

$ESPECIALIDADES = [ordered]@{
    "MEDICINA_GENERAL"          = @("MEDICINA*GENERAL", "MDGENERAL", "MED*GENERAL", "CONSULTA*GENERAL")
    "MEDICINA_INTERNA"          = @("MEDICINA*INTERNA", "MDINTERNA", "MED*INTERNA", "INTERNISTA")
    "URGENCIAS"                 = @("URGENCIA", "EMERGENCIA", "TRIAGE")
    "CIRUGIA_GENERAL"           = @("CIRUGIA*GENERAL", "CIRUGIAGENERAL", "CX*GENERAL")
    "CIRUGIA_ORTOPEDIA"         = @("ORTOPEDIA", "TRAUMATOLOGIA", "ORTOPEDISTA")
    "CIRUGIA_PLASTICA"          = @("CIRUGIA*PLASTICA", "PLASTICA", "RECONSTRUCTIVA")
    "GINECOLOGIA"               = @("GINECOLOGIA", "GINECO", "OBSTETRICIA", "GINECO*OBSTETRICIA")
    "PEDIATRIA"                 = @("PEDIATRIA", "PEDIATRICO", "NEONATOLOGIA", "NEONATO")
    "CARDIOLOGIA"               = @("CARDIOLOGIA", "CARDIOLOGO", "CARDIACO")
    "NEUROLOGIA"                = @("NEUROLOGIA", "NEUROLOGO", "NEURO")
    "NEUROCIRUGÍA"              = @("NEUROCIRUGIA", "NEUROCIRUJANO")
    "PSIQUIATRIA"               = @("PSIQUIATRIA", "PSIQUIATRA", "SALUD*MENTAL")
    "PSICOLOGIA"                = @("PSICOLOGIA", "PSICOLOGO", "PSICOLOGA")
    "FISIOTERAPIA"              = @("FISIOTERAPIA", "FISIOTERAPEUTA", "REHABILITACION*FISICA")
    "TERAPIA_OCUPACIONAL"       = @("TERAPIA*OCUPACIONAL", "TERAPEUTA*OCUPACIONAL")
    "FONOAUDIOLOGIA"            = @("FONOAUDIOLOGIA", "FONOAUDIOLOGO", "LENGUAJE", "VOZ")
    "NUTRICION"                 = @("NUTRICION", "NUTRICIONISTA", "DIETETICA", "DIETETISTA")
    "TRABAJO_SOCIAL"            = @("TRABAJO*SOCIAL", "TRABAJADOR*SOCIAL", "TRABAJADORA*SOCIAL")
    "ENFERMERIA"                = @("ENFERMERIA", "ENFERMERO", "ENFERMERA", "JEFE*ENFERMERIA")
    "REUMATOLOGIA"              = @("REUMATOLOGIA", "REUMATOLOGO", "REUMATICA")
    "ENDOCRINOLOGIA"            = @("ENDOCRINOLOGIA", "ENDOCRINOLOGO", "DIABETES*ESPECIALISTA")
    "GASTROENTEROLOGIA"         = @("GASTROENTEROLOGIA", "GASTROENTEROLOGO", "GASTRO")
    "NEUMOLOGIA"                = @("NEUMOLOGIA", "NEUMOLOGO", "PULMONOLOGIA", "PULMONOLOGO")
    "DERMATOLOGIA"              = @("DERMATOLOGIA", "DERMATOLOGO", "PIEL")
    "OFTALMOLOGIA"              = @("OFTALMOLOGIA", "OFTALMOLOGO", "OPTOMETRIA", "OPTOMETRISTA")
    "OTORRINOLARINGOLOGIA"      = @("OTORRINOLARINGOLOGIA", "OTORRINO", "ORL", "OIDO*NARIZ")
    "UROLOGIA"                  = @("UROLOGIA", "UROLOGO", "UROLOGICA")
    "NEFROLOGIA"                = @("NEFROLOGIA", "NEFROLOGO", "RENAL*ESPECIALISTA")
    "HEMATOLOGIA"               = @("HEMATOLOGIA", "HEMATOLOGO", "ONCOHEMATOLOGIA")
    "ONCOLOGIA"                 = @("ONCOLOGIA", "ONCOLOGO", "CANCER", "QUIMIOTERAPIA")
    "INFECTOLOGIA"              = @("INFECTOLOGIA", "INFECTOLOGO", "INFECCIOSAS")
    "GERIATRIA"                 = @("GERIATRIA", "GERIATRA", "ADULTO*MAYOR*ESPECIALISTA")
    "MEDICINA_FISICA"           = @("MEDICINA*FISICA", "REHABILITACION*ESPECIALISTA", "FISIATRA")
    "DOLOR_CUIDADOS_PALIATIVOS" = @("DOLOR", "CUIDADO*PALIATIVO", "PALIATIVO", "PALIATIVOS")
    "MEDICINA_LABORAL"          = @("MEDICINA*LABORAL", "SALUD*TRABAJO", "SALUD*OCUPACIONAL")
    "ODONTOLOGIA"               = @("ODONTOLOGIA", "ODONTOLOGO", "ODONTOLOGA", "DENTAL")
    "OPTOMETRIA"                = @("OPTOMETRIA", "OPTOMETRISTA", "VISION")
    "BACTERIOLOGIA"             = @("BACTERIOLOGIA", "BACTERIOLOGO", "LABORATORIO*CLINICO")
}


# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

function Limpiar-Texto($t) {
    $t = $t.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $t.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne "NonSpacingMark") {
            [void]$sb.Append($c)
        }
    }
    return ($sb.ToString().Normalize([Text.NormalizationForm]::FormC)).ToUpper()
}

function Detectar-Especialidad($nombre) {
    foreach ($esp in $ESPECIALIDADES.Keys) {
        foreach ($patron in $ESPECIALIDADES[$esp]) {
            if ($nombre -like "*$patron*") {
                return $esp
            }
        }
    }
    return "GENERAL"
}

function Escribir-Log($mensaje, $archivo_log) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $linea = "[$timestamp] $mensaje"
    Write-Host $linea
    Add-Content -Path $archivo_log -Value $linea -Encoding UTF8
}


# =============================================================================
# FUNCIÓN PRINCIPAL — PROCESAR UN MES
# =============================================================================

function Procesar-Mes($ruta_mes, $nombre_mes, $archivo_log) {

    Escribir-Log "==================================================" $archivo_log
    Escribir-Log "PROCESANDO MES: $nombre_mes" $archivo_log
    Escribir-Log "RUTA: $ruta_mes" $archivo_log
    Escribir-Log "==================================================" $archivo_log

    # Limpiar y crear carpeta TEMP
    $temp_mes = Join-Path $RAIZ_TEMP $nombre_mes
    if (Test-Path $temp_mes) {
        Remove-Item $temp_mes -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $temp_mes -Force | Out-Null

    # Carpeta de salida para el mes
    $salida_mes = Join-Path $RAIZ_SALIDA $nombre_mes
    New-Item -ItemType Directory -Path $salida_mes -Force | Out-Null

    # Copiar PDFs a TEMP con nombres limpios
    $pdfs_encontrados = 0
    Get-ChildItem $ruta_mes -File -Filter *.pdf | ForEach-Object {
        $nuevo = (Limpiar-Texto $_.Name) -replace "[^A-Z0-9_.\-]", "_"
        $destino = Join-Path $temp_mes $nuevo
        Copy-Item $_.FullName $destino -Force
        $pdfs_encontrados++
    }

    Escribir-Log "PDFs encontrados en $nombre_mes : $pdfs_encontrados" $archivo_log

    if ($pdfs_encontrados -eq 0) {
        Escribir-Log "ADVERTENCIA: No se encontraron PDFs en $ruta_mes" $archivo_log
        return
    }

    # Leer PDFs limpios y agrupar
    $archivos = Get-ChildItem $temp_mes -File -Filter *.pdf
    $grupos   = @{}

    foreach ($archivo in $archivos) {
        $nombre = $archivo.BaseName.ToUpper()

        # Extraer fecha (formato YYYYMMDD al final del nombre)
        if ($nombre -match "(20\d{6})$") {
            $fecha = $matches[1]
        } else {
            Escribir-Log "SIN FECHA: $($archivo.Name) — omitido" $archivo_log
            continue
        }

        # Extraer documento de identidad
        if ($nombre -match "(CC|TI|RC|SC|PT|CE|PA|MS|AS)\d+") {
            $id = $matches[0]
        } else {
            Escribir-Log "SIN DOCUMENTO: $($archivo.Name) — omitido" $archivo_log
            continue
        }

        # Detectar especialidad
        $esp = Detectar-Especialidad $nombre

        $key = "$id|$esp|$fecha"

        if (-not $grupos.ContainsKey($key)) {
            $grupos[$key] = @()
        }
        $grupos[$key] += $archivo
    }

    # Unir PDFs por grupo
    $total_creados  = 0
    $total_errores  = 0

    foreach ($key in $grupos.Keys) {

        $p     = $key.Split("|")
        $id    = $p[0]
        $esp   = $p[1]
        $fecha = $p[2]
        $grupo = $grupos[$key]

        # Ordenar según categorías clínicas
        $ordenados = @()
        foreach ($cat in $ORDEN_DOCUMENTOS) {
            $encontrados = $grupo | Where-Object { $_.Name.ToUpper() -like "*$cat*" }
            if ($encontrados) { $ordenados += $encontrados }
        }

        # Agregar los que no coincidieron con ninguna categoría
        $ordenados += $grupo | Where-Object {
            $enLista = $false
            foreach ($cat in $ORDEN_DOCUMENTOS) {
                if ($_.Name.ToUpper() -like "*$cat*") { $enLista = $true }
            }
            -not $enLista
        }

        if ($ordenados.Count -eq 0) { continue }

        $salida = Join-Path $salida_mes "$id`_HC_$esp`_$fecha.pdf"
        $files  = $ordenados | ForEach-Object { $_.FullName }

        Escribir-Log "UNIENDO | $id | $esp | $fecha | $($files.Count) PDFs" $archivo_log

        & pdftk $files cat output $salida 2>&1

        if (Test-Path $salida) {
            Escribir-Log "OK: $salida" $archivo_log
            $total_creados++
        } else {
            Escribir-Log "ERROR al crear: $salida" $archivo_log
            $total_errores++
        }
    }

    Escribir-Log "MES $nombre_mes FINALIZADO — Creados: $total_creados | Errores: $total_errores" $archivo_log

    # Limpiar TEMP del mes
    Remove-Item $temp_mes -Recurse -Force -ErrorAction SilentlyContinue
}


# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

# Crear carpetas base
New-Item -ItemType Directory -Path $RAIZ_SALIDA -Force | Out-Null
New-Item -ItemType Directory -Path $RAIZ_LOGS   -Force | Out-Null
New-Item -ItemType Directory -Path $RAIZ_TEMP   -Force | Out-Null

# Archivo de log con timestamp
$fecha_log   = Get-Date -Format "yyyyMMdd_HHmmss"
$archivo_log = Join-Path $RAIZ_LOGS "log_$fecha_log.txt"

Escribir-Log "INICIANDO UNIFICADOR DE HISTORIAS CLINICAS" $archivo_log
Escribir-Log "Raíz soportes : $RAIZ_SOPORTES" $archivo_log
Escribir-Log "Raíz salida   : $RAIZ_SALIDA" $archivo_log

# Determinar qué meses procesar
if ($MES_ESPECIFICO -ne "") {
    $meses_a_procesar = @($MES_ESPECIFICO.ToUpper())
} else {
    $meses_a_procesar = $MESES
}

$total_meses_procesados = 0

foreach ($mes in $meses_a_procesar) {
    $ruta_mes = Join-Path $RAIZ_SOPORTES $mes
    if (Test-Path $ruta_mes) {
        Procesar-Mes $ruta_mes $mes $archivo_log
        $total_meses_procesados++
    } else {
        Escribir-Log "OMITIDO: No existe la carpeta $ruta_mes" $archivo_log
    }
}

Escribir-Log "" $archivo_log
Escribir-Log "=================================================" $archivo_log
Escribir-Log "PROCESO COMPLETADO" $archivo_log
Escribir-Log "Meses procesados : $total_meses_procesados" $archivo_log
Escribir-Log "Log guardado en  : $archivo_log" $archivo_log
Escribir-Log "=================================================" $archivo_log

Write-Host ""
Write-Host "✅ PROCESO FINALIZADO — Revisa los PDFs en: $RAIZ_SALIDA" -ForegroundColor Cyan
Write-Host "📋 Log guardado en: $archivo_log" -ForegroundColor Yellow
