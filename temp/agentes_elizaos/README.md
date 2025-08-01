# 🤖 Sistema de Agentes ElizaOS

Carpeta principal que contiene todos los templates, scripts y documentación para crear y gestionar agentes de IA con ElizaOS.

## 📁 Estructura de la Carpeta

```
agentes_elizaos/
├── README.md                    # Este archivo - Documentación principal
├── templates/
│   ├── templates_agentes.json   # Biblioteca completa de templates JSON
│   ├── agente_completo.json     # Template agente completo local
│   ├── agente_web_developer.json # Template desarrollador web
│   ├── agente_creative_writer.json # Template escritor creativo
│   ├── agente_data_analyst.json # Template analista de datos
│   ├── agente_customer_support.json # Template soporte al cliente
│   └── agente_marketing.json    # Template marketing
├── scripts/
│   ├── crear_agente_template.sh       # Script automatizado para crear agentes
│   ├── gestionar_agentes.sh           # Script para gestionar agentes
│   ├── instalar_plugins.sh            # Script para instalar plugins
│   ├── configurar_ufw.sh              # Script para configurar UFW
│   ├── solucionar_puerto_9182.sh      # Script para solucionar conflicto de puerto
│   ├── diagnostico_completo.sh        # Script de diagnóstico completo
│   └── levantar_sistema_completo.sh   # Script para levantar todo el sistema
├── configs/
│   ├── .env.example             # Ejemplo de variables de entorno
│   └── pm2_config.json          # Configuración PM2
└── docs/
    ├── guia_rapida.md           # Guía rápida de uso
    ├── troubleshooting.md       # Solución de problemas
    └── casos_uso.md             # Casos de uso específicos
```

## 🚀 Uso Rápido

### 1. Crear un Agente
```bash
# Desde la carpeta agentes_elizaos/
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9182
```

### 2. Gestionar Agentes
```bash
# Ver agentes activos
./scripts/gestionar_agentes.sh list

# Reiniciar agente
./scripts/gestionar_agentes.sh restart mi-agente

# Detener agente
./scripts/gestionar_agentes.sh stop mi-agente
```

### 3. Instalar Plugins
```bash
# Instalar todos los plugins necesarios
./scripts/instalar_plugins.sh
```

### 4. Levantar Sistema Completo (Recomendado)
```bash
# Levantar todo el sistema desde cero
./scripts/levantar_sistema_completo.sh
```

### 5. Diagnóstico
```bash
# Verificar estado completo del sistema
./scripts/diagnostico_completo.sh
```

## 📋 Templates Disponibles

1. **Agente Completo Local** - Todos los módulos locales
2. **Agente Desarrollador Web** - Especializado en programación
3. **Agente Escritor Creativo** - Escritura y contenido
4. **Agente Analista de Datos** - Business intelligence
5. **Agente Soporte al Cliente** - Atención al cliente
6. **Agente Marketing** - Estrategias de crecimiento

## 🌐 URLs de Acceso

- **Agente Local**: http://amara.coretransapi.com:9182
- **Desarrollador Web**: http://amara.coretransapi.com:9183
- **Escritor Creativo**: http://amara.coretransapi.com:9184
- **Analista de Datos**: http://amara.coretransapi.com:9185
- **Soporte al Cliente**: http://amara.coretransapi.com:9186
- **Marketing**: http://amara.coretransapi.com:9187

## 📖 Documentación

- [Guía Rápida](docs/guia_rapida.md) - Cómo empezar rápidamente
- [Troubleshooting](docs/troubleshooting.md) - Solución de problemas
- [Casos de Uso](docs/casos_uso.md) - Ejemplos prácticos

## ⚡ Características

- ✅ **100% Local** - Sin APIs externas
- ✅ **Módulos Integrados** - Thor Toys, Stable Diffusion, etc.
- ✅ **Gestión Automática** - PM2 para reinicio y logs
- ✅ **Templates Reutilizables** - Fácil personalización
- ✅ **Scripts Automatizados** - Creación y gestión simplificada 