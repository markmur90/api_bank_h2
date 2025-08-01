# 📁 Índice - Sistema de Agentes ElizaOS

## 🎯 **Estructura Completa Organizada**

```
agentes_elizaos/
├── 📄 README.md                           # Documentación principal
├── 📄 INDICE.md                           # Este archivo - Índice completo
│
├── 📁 templates/                          # Templates JSON
│   └── 📄 templates_agentes.json         # Biblioteca completa de templates
│
├── 📁 scripts/                           # Scripts automatizados
│   ├── 📄 crear_agente_template.sh       # Crear agentes con templates
│   ├── 📄 gestionar_agentes.sh           # Gestionar agentes (start/stop/logs)
│   └── 📄 instalar_plugins.sh            # Instalar plugins necesarios
│
├── 📁 configs/                           # Configuraciones
│   └── 📄 env_example.txt                # Variables de entorno de ejemplo
│
└── 📁 docs/                              # Documentación
    └── 📄 guia_rapida.md                 # Guía rápida de uso
```

## 🚀 **Uso Rápido**

### 1. **Instalar Plugins** (Solo primera vez)
```bash
cd agentes_elizaos
./scripts/instalar_plugins.sh
```

### 2. **Crear Agente**
```bash
# Agente completo local
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9182

# Agente desarrollador web
./scripts/crear_agente_template.sh agente_web_developer code-helper 9183

# Agente escritor creativo
./scripts/crear_agente_template.sh agente_creative_writer story-writer 9184
```

### 3. **Gestionar Agentes**
```bash
# Ver agentes activos
./scripts/gestionar_agentes.sh list

# Ver logs
./scripts/gestionar_agentes.sh logs mi-agente

# Reiniciar agente
./scripts/gestionar_agentes.sh restart mi-agente
```

## 📋 **Templates Disponibles**

| Template | Puerto | Descripción | Especialización |
|----------|--------|-------------|-----------------|
| `agente_completo_local` | 9182 | Agente completo | Todos los módulos locales |
| `agente_web_developer` | 9183 | Desarrollador web | Programación y código |
| `agente_creative_writer` | 9184 | Escritor creativo | Contenido y escritura |
| `agente_data_analyst` | 9185 | Analista de datos | Business intelligence |
| `agente_customer_support` | 9186 | Soporte al cliente | Atención al cliente |
| `agente_marketing` | 9187 | Marketing | Estrategias de crecimiento |

## 🌐 **URLs de Acceso**

- **Agente Local**: http://amara.coretransapi.com:9182
- **Desarrollador Web**: http://amara.coretransapi.com:9183
- **Escritor Creativo**: http://amara.coretransapi.com:9184
- **Analista de Datos**: http://amara.coretransapi.com:9185
- **Soporte al Cliente**: http://amara.coretransapi.com:9186
- **Marketing**: http://amara.coretransapi.com:9187

## ⚡ **Comandos Esenciales**

### **Crear Agentes**
```bash
./scripts/crear_agente_template.sh [tipo] [nombre] [puerto]
```

### **Gestionar Agentes**
```bash
./scripts/gestionar_agentes.sh list          # Listar agentes
./scripts/gestionar_agentes.sh status [agente] # Estado específico
./scripts/gestionar_agentes.sh logs [agente]   # Ver logs
./scripts/gestionar_agentes.sh restart [agente] # Reiniciar
./scripts/gestionar_agentes.sh stop [agente]    # Detener
./scripts/gestionar_agentes.sh delete [agente]  # Eliminar
./scripts/gestionar_agentes.sh monitor         # Monitor en tiempo real
./scripts/gestionar_agentes.sh ports           # Ver puertos
```

### **Instalar Plugins**
```bash
./scripts/instalar_plugins.sh
```

## 🎯 **Casos de Uso**

### **Para Desarrollo**
```bash
./scripts/crear_agente_template.sh agente_web_developer code-reviewer 9183
```

### **Para Contenido**
```bash
./scripts/crear_agente_template.sh agente_creative_writer content-writer 9184
```

### **Para Datos**
```bash
./scripts/crear_agente_template.sh agente_data_analyst data-sage 9185
```

### **Para Soporte**
```bash
./scripts/crear_agente_template.sh agente_customer_support support-bot 9186
```

### **Para Marketing**
```bash
./scripts/crear_agente_template.sh agente_marketing growth-ai 9187
```

## 🔧 **Características**

- ✅ **100% Local** - Sin APIs externas
- ✅ **Módulos Integrados** - Thor Toys, Stable Diffusion, etc.
- ✅ **Gestión Automática** - PM2 para reinicio y logs
- ✅ **Templates Reutilizables** - Fácil personalización
- ✅ **Scripts Automatizados** - Creación y gestión simplificada
- ✅ **Organización Clara** - Todo en una carpeta estructurada

## 📖 **Documentación**

- **[README.md](README.md)** - Documentación principal
- **[Guía Rápida](docs/guia_rapida.md)** - Uso en 5 minutos
- **[Templates](templates/templates_agentes.json)** - Biblioteca de templates

## 🎉 **¡Listo para Usar!**

Con esta estructura organizada tienes:
- **Templates JSON** reutilizables
- **Scripts automatizados** para crear y gestionar
- **Documentación completa** y fácil de seguir
- **Sistema modular** y escalable

**¡Tu sistema de agentes de IA está completamente organizado y listo para usar!** 