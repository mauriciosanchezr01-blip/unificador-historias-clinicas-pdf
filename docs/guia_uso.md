# 📖 Guía de Uso — Unificador de Historias Clínicas

## Paso 1 — Organizar las carpetas de soportes

Crea la siguiente estructura en tu computador:

```
C:\SOPORTES\
├── ENERO\
├── FEBRERO\
├── MARZO\
├── ABRIL\
├── MAYO\
├── JUNIO\
├── JULIO\
├── AGOSTO\
├── SEPTIEMBRE\
├── OCTUBRE\
├── NOVIEMBRE\
└── DICIEMBRE\
```

## Paso 2 — Nombrar los archivos correctamente

Cada PDF debe seguir esta convención:

```
[TIPO_DOC][NUMERO]_[ESPECIALIDAD]_[CATEGORIA]_[YYYYMMDD].pdf
```

| Campo | Valores válidos | Ejemplo |
|-------|----------------|---------|
| TIPO_DOC | CC, TI, RC, SC, PT, CE, PA, MS, AS | CC |
| NUMERO | Número del documento | 10234567 |
| ESPECIALIDAD | Ver lista de especialidades | FISIOTERAPIA |
| CATEGORIA | HC, MEDICAMENTOS, LABORATORIO, etc. | HC |
| FECHA | Formato YYYYMMDD | 20240115 |

## Paso 3 — Configurar las rutas en el script

Abre el script y ajusta estas variables:

```powershell
$RAIZ_SOPORTES  = "C:\SOPORTES"      # Ruta donde están las carpetas de meses
$RAIZ_SALIDA    = "C:\SOPORTES\SALIDA"  # Donde se guardan los PDFs unificados
$MES_ESPECIFICO = ""                  # Dejar vacío para todos los meses
```

## Paso 4 — Ejecutar

```powershell
.\scripts\unir_historias_clinicas.ps1
```

## Paso 5 — Revisar resultados

Los PDFs unificados quedan en:
```
C:\SOPORTES\SALIDA\ENERO\CC10234567_HC_FISIOTERAPIA_20240115.pdf
```

Los logs de ejecución quedan en:
```
C:\SOPORTES\LOGS\log_20240115_093045.txt
```

## Solución de problemas comunes

| Error | Causa | Solución |
|-------|-------|---------|
| pdftk no encontrado | pdftk no está instalado | Descargar desde pdflabs.com |
| SIN FECHA | El nombre no termina en YYYYMMDD | Renombrar el archivo |
| SIN DOCUMENTO | No detecta tipo de documento | Verificar que empiece con CC, TI, etc. |
| PDF vacío | Archivo corrupto | Verificar el PDF original |
