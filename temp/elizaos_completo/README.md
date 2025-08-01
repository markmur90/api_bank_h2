# 🚀 ElizaOS Completo - Sistema Integrado

Carpeta que contiene todos los archivos y configuraciones para ElizaOS, incluyendo scripts de instalación, configuración y gestión de agentes.

## 📁 Estructura de la Carpeta

```
elizaos_completo/
├── README.md                    # Este archivo - Documentación principal
├── configs/
│   ├── agente_completo.json     # Configuración del agente completo
│   └── elizaos_config.env       # Variables de entorno de ejemplo
├── scripts/
│   ├── configurar_elizaos.sh    # Script para configurar ElizaOS en puerto 9182
│   ├── configurar_version_completa.sh # Script para configurar versión completa
│   ├── crear_agente_completo.sh # Script para crear agente completo
│   └── instalar_elizaos.sh      # Script de instalación principal
└── agentes_elizaos/             # Sistema completo de agentes (carpeta separada)
    ├── templates/               # Templates JSON para agentes
    ├── scripts/                 # Scripts de gestión de agentes
    ├── configs/                 # Configuraciones de agentes
    └── docs/                    # Documentación de agentes
```

## 🚀 Uso Rápido

### 1. Subir al VPS
```bash
# Desde el directorio local donde están los archivos
./subir_elizaos_completo.sh
```

### 2. Instalación en el VPS
```bash
# Conectar al VPS
ssh -i vps_njalla_nueva markmur88@80.78.30.242

# Navegar al directorio
cd ~/elizaos_completo

# Ejecutar instalación completa
./scripts/instalacion_completa.sh
```

### 3. Instalación Manual (Alternativa)
```bash
# Instalar ElizaOS básico
./scripts/instalar_elizaos.sh

# Configurar versión completa
./scripts/configurar_version_completa.sh
```

### 2. Configuración del Agente
```bash
# Crear agente completo con módulos locales
./scripts/crear_agente_completo.sh

# O configurar en puerto específico
./scripts/configurar_elizaos.sh
```

### 3. Sistema de Agentes Avanzado
```bash
# Navegar a la carpeta de agentes
cd agentes_elizaos/

# Levantar sistema completo
./scripts/levantar_sistema_completo.sh

# Crear agentes específicos
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9190
```

## 📋 Archivos Principales

### Configuraciones
- **`configs/agente_completo.json`** - Configuración del agente principal
- **`configs/elizaos_config.env`** - Variables de entorno de ejemplo

### Scripts de Instalación
- **`scripts/instalar_elizaos.sh`** - Instalación básica de ElizaOS
- **`scripts/configurar_elizaos.sh`** - Configuración en puerto 9182
- **`scripts/configurar_version_completa.sh`** - Configuración de versión completa
- **`scripts/crear_agente_completo.sh`** - Creación de agente con módulos locales

### Sistema de Agentes
- **`agentes_elizaos/`** - Sistema completo para gestión de múltiples agentes

## 🌐 URLs de Acceso

- **ElizaOS Básico**: http://amara.coretransapi.com:9182
- **Agente Completo**: http://amara.coretransapi.com:9190
- **Agentes Especializados**: http://amara.coretransapi.com:9183-9187

## ⚡ Características

- ✅ **Instalación Automatizada** - Scripts de instalación y configuración
- ✅ **Configuración Completa** - Agente con todos los módulos locales
- ✅ **Sistema de Agentes** - Gestión de múltiples agentes especializados
- ✅ **100% Local** - Sin dependencias de APIs externas
- ✅ **Módulos Integrados** - Thor Toys, Stable Diffusion, etc.

## 📖 Documentación

- [Sistema de Agentes](agentes_elizaos/README.md) - Documentación completa del sistema de agentes
- [Guía Rápida](agentes_elizaos/docs/guia_rapida.md) - Uso en 5 minutos
- [Troubleshooting](agentes_elizaos/docs/troubleshooting.md) - Solución de problemas

## 🎯 Casos de Uso

### Instalación Inicial
```bash
# 1. Subir archivos al VPS
# 2. Ejecutar instalación
./scripts/instalar_elizaos.sh
# 3. Configurar agente completo
./scripts/crear_agente_completo.sh
```

### Gestión de Agentes
```bash
# 1. Navegar al sistema de agentes
cd agentes_elizaos/
# 2. Levantar sistema completo
./scripts/levantar_sistema_completo.sh
# 3. Crear agentes específicos según necesidades
```

## 🎉 ¡Listo para Usar!

Con esta estructura tienes:
- **Instalación automatizada** de ElizaOS
- **Configuración completa** con módulos locales
- **Sistema de agentes** especializados
- **Documentación completa** y scripts de gestión

**¡Tu sistema ElizaOS está completamente organizado y listo para usar!** 