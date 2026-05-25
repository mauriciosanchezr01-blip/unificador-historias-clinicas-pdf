# 📄 Unificador de Historias Clínicas en PDF

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=flat-square&logo=powershell)
![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat-square&logo=python)
![Estado](https://img.shields.io/badge/Estado-Producción-green?style=flat-square)
![Licencia](https://img.shields.io/badge/Licencia-MIT-lightgrey?style=flat-square)

> Automatización para agrupar, ordenar y unir los documentos PDF de historias clínicas
> por paciente, especialidad y fecha. Compatible con todos los meses del año y más de
> 35 especialidades médicas del sector salud colombiano.

---

## 📌 Problema que resuelve

En IPS y hospitales colombianos, los documentos de soporte de cada atención se generan
de forma separada: historia clínica, fórmulas médicas, resultados de laboratorio,
imágenes diagnósticas, remisiones, entre otros. Consolidarlos manualmente para cada
paciente consume horas de trabajo del equipo administrativo y es propenso a errores
de organización.

Este proyecto automatiza ese proceso completamente.

---

## 🎯 Lo que hace

- Recorre las carpetas de soportes organizadas por mes
- Detecta automáticamente el documento de identidad, la especialidad y la fecha en el nombre del archivo
- Agrupa todos los PDFs del mismo paciente, especialidad y fecha
- Los ordena según la secuencia clínica estándar
- Los une en un único PDF por atención
- Genera un log detallado de todo lo procesado

---

## 🏥 Especialidades detectadas automáticamente

| Especialidad | Especialidad | Especialidad |
|-------------|-------------|-------------|
| Medicina general | Cardiología | Dermatología |
| Medicina interna | Neurología | Oftalmología |
| Urgencias | Neurocirugía | Otorrinolaringología |
| Cirugía general | Psiquiatría | Urología |
| Cirugía ortopédica | Psicología | Nefrología |
| Cirugía plástica | Fisioterapia | Hematología |
| Ginecología | Terapia ocupacional | Oncología |
| Pediatría | Fonoaudiología | Infectología |
| Reumatología | Nutrición | Geriatría |
| Endocrinología | Trabajo social | Medicina física |
| Gastroenterología | Enfermería | Dolor y paliativos |
| Neumología | Odontología | Medicina laboral |
| Y más... | Bacteriología | |

---

## 📁 Estructura del proyecto

```
unificador-historias-clinicas-pdf/
│
├── scripts/
│   └── unir_historias_clinicas.ps1    # Versión PowerShell (Windows)
│
├── src/
│   └── unir_historias_clinicas.py     # Versión Python (multiplataforma)
│
├── logs/                              # Logs de ejecución automáticos
│
├── docs/
│   ├── guia_uso.md                    # Guía de uso detallada
│   └── convencion_nombres.md          # Convención de nombres de archivos
│
├── ejemplos/
│   └── estructura_carpetas.md         # Estructura esperada de carpetas
│
├── requirements.txt
└── README.md
```

---

## ⚙️ Convención de nombres de archivos

Los archivos PDF deben seguir esta estructura para ser detectados correctamente:

```
[TIPO_DOC][NUMERO]_[ESPECIALIDAD]_[CATEGORIA]_[YYYYMMDD].pdf
```

Ejemplos:
```
CC10234567_FISIOTERAPIA_HC_000000.pdf
CC10234567_FISIOTERAPIA_MEDICAMENTOS_000000.pdf
TI98765432_PEDIATRIA_LABORATORIO_000000.pdf
CC20345678_MEDICINA_INTERNA_AYUDA_DIAGNOSTICA_000000.pdf
```

---

## 🗂️ Estructura esperada de carpetas

```
C:\SOPORTES\
├── ENERO\
│   ├── CC10234567_FISIOTERAPIA_HC_000000.pdf
│   ├── CC10234567_FISIOTERAPIA_MEDICAMENTOS_000000.pdf
│   └── ...
├── FEBRERO\
│   └── ...
├── MARZO\
│   └── ...
└── SALIDA\         ← PDFs unificados se guardan aquí
    ├── ENERO\
    │   └── CC10234567_HC_FISIOTERAPIA_000000.pdf
    └── FEBRERO\
```

---

## 🚀 Cómo usar

### Versión PowerShell

```powershell
# Ajustar las rutas al inicio del script
$RAIZ_SOPORTES = "C:\SOPORTES"
$MES_ESPECIFICO = ""   # Dejar vacío para todos los meses

# Ejecutar
.\scripts\unir_historias_clinicas.ps1
```

### Versión Python

```bash
# Instalar dependencias
pip install -r requirements.txt

# Ajustar las rutas en el script
# RAIZ_SOPORTES = r"C:\SOPORTES"

# Ejecutar
python src/unir_historias_clinicas.py
```

---

## 📋 Orden de documentos en el PDF final

1. Historia clínica / Anamnesis
2. Fórmulas y medicamentos
3. Resultados de laboratorio
4. Ayudas diagnósticas (imágenes, TAC, RMN)
5. Remisiones y contrarremisiones
6. Procedimientos y cirugías
7. Recomendaciones / Egreso / Epicrisis
8. Interconsultas
9. Consentimientos y certificados

---

## 📈 Resultados esperados

- Reducción del tiempo de consolidación de soportes en más del 80%
- Eliminación de errores de organización en historias clínicas
- Log automático de todo lo procesado para trazabilidad
- Compatible con todos los meses del año sin configuración adicional

---

## ⚠️ Requisitos

**Versión PowerShell:**
- Windows 10 o superior
- PowerShell 5.1+
- [pdftk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/) instalado y en el PATH

**Versión Python:**
- Python 3.10+
- pypdf (ver requirements.txt)
- Compatible con Windows, Linux y macOS

---

## 👤 Autor

**Mauricio Sánchez**
Analista de Datos en Salud | Especialista en Ciencia de Datos
Estudiante de Maestría en TIC en Salud — Universidad CES
📍 Medellín, Antioquia, Colombia
🔗 [GitHub](https://github.com/mauriciosanchezr01-blip)

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.
