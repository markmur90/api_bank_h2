# 🚀 Guía Rápida - Agentes ElizaOS

Esta guía te ayudará a crear y gestionar agentes de IA con ElizaOS en menos de 5 minutos.

## ⚡ Inicio Rápido

### 1. Instalar Plugins (Solo la primera vez)
```bash
cd agentes_elizaos
./scripts/instalar_plugins.sh
```

### 2. Crear tu Primer Agente
```bash
# Agente completo local
./scripts/crear_agente_template.sh agente_completo_local mi-primer-agente 9182

# Agente desarrollador web
./scripts/crear_agente_template.sh agente_web_developer code-assistant 9183

# Agente escritor creativo
./scripts/crear_agente_template.sh agente_creative_writer story-writer 9184
```

### 3. Verificar que Funciona
```bash
# Ver agentes activos
./scripts/gestionar_agentes.sh list

# Ver logs de un agente
./scripts/gestionar_agentes.sh logs mi-primer-agente

# Ver puertos en uso
./scripts/gestionar_agentes.sh ports
```

### 4. Acceder al Agente
- **URL**: http://amara.coretransapi.com:9182
- **IP Directa**: http://80.78.30.242:9182

## 📋 Comandos Esenciales

### Crear Agentes
```bash
# Sintaxis básica
./scripts/crear_agente_template.sh [tipo] [nombre] [puerto]

# Ejemplos
./scripts/crear_agente_template.sh agente_completo_local local-ai 9182
./scripts/crear_agente_template.sh agente_web_developer dev-helper 9183
./scripts/crear_agente_template.sh agente_creative_writer content-ai 9184
./scripts/crear_agente_template.sh agente_data_analyst data-sage 9185
./scripts/crear_agente_template.sh agente_customer_support support-ai 9186
./scripts/crear_agente_template.sh agente_marketing growth-ai 9187
```

### Gestionar Agentes
```bash
# Listar todos los agentes
./scripts/gestionar_agentes.sh list

# Ver estado de un agente específico
./scripts/gestionar_agentes.sh status mi-agente

# Ver logs (últimas 20 líneas)
./scripts/gestionar_agentes.sh logs mi-agente

# Ver logs (últimas 50 líneas)
./scripts/gestionar_agentes.sh logs mi-agente 50

# Reiniciar agente
./scripts/gestionar_agentes.sh restart mi-agente

# Detener agente
./scripts/gestionar_agentes.sh stop mi-agente

# Eliminar agente
./scripts/gestionar_agentes.sh delete mi-agente

# Monitor en tiempo real
./scripts/gestionar_agentes.sh monitor

# Ver puertos en uso
./scripts/gestionar_agentes.sh ports
```

## 🎯 Casos de Uso Comunes

### Para Desarrollo
```bash
# Crear agente para análisis de código
./scripts/crear_agente_template.sh agente_web_developer code-reviewer 9183
```

### Para Contenido
```bash
# Crear agente para escritura creativa
./scripts/crear_agente_template.sh agente_creative_writer content-writer 9184
```

### Para Datos
```bash
# Crear agente para análisis de datos
./scripts/crear_agente_template.sh agente_data_analyst data-analyst 9185
```

### Para Soporte
```bash
# Crear agente para atención al cliente
./scripts/crear_agente_template.sh agente_customer_support support-bot 9186
```

### Para Marketing
```bash
# Crear agente para estrategias de marketing
./scripts/crear_agente_template.sh agente_marketing marketing-ai 9187
```

## 🔧 Personalización Rápida

### Cambiar Puerto
Si el puerto está ocupado, usa otro:
```bash
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9190
```

### Múltiples Agentes
Puedes tener varios agentes corriendo simultáneamente:
```bash
# Agente 1 en puerto 9182
./scripts/crear_agente_template.sh agente_completo_local agente1 9182

# Agente 2 en puerto 9183
./scripts/crear_agente_template.sh agente_web_developer agente2 9183

# Agente 3 en puerto 9184
./scripts/crear_agente_template.sh agente_creative_writer agente3 9184
```

## 🚨 Solución de Problemas Rápidos

### Agente no inicia
```bash
# Ver logs del agente
./scripts/gestionar_agentes.sh logs mi-agente

# Reiniciar agente
./scripts/gestionar_agentes.sh restart mi-agente

# Verificar plugins instalados
./scripts/instalar_plugins.sh
```

### Puerto ocupado
```bash
# Ver puertos en uso
./scripts/gestionar_agentes.sh ports

# Usar puerto diferente
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9190
```

### Error de conexión
```bash
# Verificar que el agente esté corriendo
./scripts/gestionar_agentes.sh list

# Ver estado específico
./scripts/gestionar_agentes.sh status mi-agente
```

## 📊 Monitoreo

### Ver todos los agentes
```bash
./scripts/gestionar_agentes.sh list
```

### Monitor en tiempo real
```bash
./scripts/gestionar_agentes.sh monitor
```

### Ver puertos activos
```bash
./scripts/gestionar_agentes.sh ports
```

## 🎉 ¡Listo!

Con estos comandos básicos ya puedes:
- ✅ Crear agentes especializados
- ✅ Gestionar múltiples agentes
- ✅ Monitorear su funcionamiento
- ✅ Solucionar problemas comunes

**¡Tu sistema de agentes de IA está listo para usar!** 