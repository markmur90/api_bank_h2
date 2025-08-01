# 🔧 Troubleshooting - Agentes ElizaOS

## 🚨 Problemas Comunes y Soluciones

### 1. **Error 400 Bad Request - HTTP en puerto HTTPS**

**Problema**: `400 Bad Request - Plain HTTP request was sent to HTTPS port`

**Causa**: El puerto 9182 está configurado para HTTPS en Nginx, pero ElizaOS usa HTTP.

**Solución**:
```bash
# Usar el script de solución automática
./scripts/solucionar_puerto_9182.sh

# O crear agente en puerto alternativo
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9190
```

**URLs correctas**:
- ✅ http://amara.coretransapi.com:9190
- ❌ http://amara.coretransapi.com:9182 (conflicto con HTTPS)

### 2. **Puerto no accesible - UFW bloqueando**

**Problema**: No se puede acceder al agente desde fuera del servidor.

**Solución**:
```bash
# Configurar UFW automáticamente
./scripts/configurar_ufw.sh

# O manualmente
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "sudo ufw allow 9190/tcp"
```

### 3. **Agente no inicia - Puerto ocupado**

**Problema**: `EADDRINUSE` - Puerto ya en uso.

**Solución**:
```bash
# Ver puertos en uso
./scripts/gestionar_agentes.sh ports

# Usar puerto diferente
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9191
```

### 4. **Error de plugins no encontrados**

**Problema**: `Cannot find module '@elizaos/plugin-*'`

**Solución**:
```bash
# Instalar plugins
./scripts/instalar_plugins.sh

# Verificar instalación
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "cd eliza-develop && ls -la packages/plugin-*/dist/"
```

### 5. **Agente no responde - Proceso caído**

**Problema**: El agente se detiene inesperadamente.

**Solución**:
```bash
# Ver logs del agente
./scripts/gestionar_agentes.sh logs mi-agente

# Reiniciar agente
./scripts/gestionar_agentes.sh restart mi-agente

# Verificar estado
./scripts/gestionar_agentes.sh status mi-agente
```

### 6. **Error de conexión SSH**

**Problema**: No se puede conectar al VPS.

**Solución**:
```bash
# Verificar clave SSH
ls -la vps_njalla_nueva

# Probar conexión
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "echo 'Conexión exitosa'"
```

## 🔍 Diagnóstico Rápido

### Verificar Estado del Sistema
```bash
# 1. Ver agentes activos
./scripts/gestionar_agentes.sh list

# 2. Ver puertos abiertos
./scripts/gestionar_agentes.sh ports

# 3. Ver logs del agente
./scripts/gestionar_agentes.sh logs mi-agente

# 4. Verificar UFW
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "sudo ufw status"
```

### Verificar Configuración
```bash
# 1. Ver configuración del agente
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "cat eliza-develop/.eliza/agents/mi-agente/config.json"

# 2. Ver variables de entorno
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "cat eliza-develop/.env"

# 3. Ver plugins instalados
ssh -i vps_njalla_nueva markmur88@80.78.30.242 "ls -la eliza-develop/packages/plugin-*/dist/"
```

## 🛠️ Comandos de Reparación

### Reiniciar Todo el Sistema
```bash
# 1. Detener todos los agentes
./scripts/gestionar_agentes.sh clean

# 2. Reinstalar plugins
./scripts/instalar_plugins.sh

# 3. Configurar UFW
./scripts/configurar_ufw.sh

# 4. Crear agente nuevo
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9190
```

### Limpiar y Recrear
```bash
# Limpiar completamente
ssh -i vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'
cd eliza-develop
pm2 delete all
rm -rf .eliza/agents/*
rm -f .env
EOF

# Recrear desde cero
./scripts/instalar_plugins.sh
./scripts/configurar_ufw.sh
./scripts/crear_agente_template.sh agente_completo_local mi-agente 9190
```

## 📋 Checklist de Verificación

### Antes de Crear un Agente
- [ ] Plugins instalados: `./scripts/instalar_plugins.sh`
- [ ] UFW configurado: `./scripts/configurar_ufw.sh`
- [ ] Puerto libre: `./scripts/gestionar_agentes.sh ports`
- [ ] Conexión SSH funcionando

### Después de Crear un Agente
- [ ] Agente aparece en PM2: `./scripts/gestionar_agentes.sh list`
- [ ] Puerto abierto: `./scripts/gestionar_agentes.sh ports`
- [ ] Logs sin errores: `./scripts/gestionar_agentes.sh logs mi-agente`
- [ ] Accesible desde navegador: http://amara.coretransapi.com:PUERTO

## 🆘 Contacto y Soporte

Si los problemas persisten:

1. **Revisar logs completos**:
   ```bash
   ./scripts/gestionar_agentes.sh logs mi-agente 100
   ```

2. **Verificar estado del servidor**:
   ```bash
   ssh -i vps_njalla_nueva markmur88@80.78.30.242 "top -n 1"
   ```

3. **Verificar espacio en disco**:
   ```bash
   ssh -i vps_njalla_nueva markmur88@80.78.30.242 "df -h"
   ```

4. **Verificar memoria disponible**:
   ```bash
   ssh -i vps_njalla_nueva markmur88@80.78.30.242 "free -h"
   ``` 