## 🔍 Auditoría de Seguridad Wi-Fi Corporativa

### 📋 Introducción
Este documento detalla las fases y acciones clave para realizar una auditoría completa de seguridad en redes Wi-Fi corporativas, análisis operativo de registros de red y buenas prácticas en el desarrollo seguro de aplicaciones Android orientadas a entornos financieros.

---

## Fase 1: Análisis de Red

### 📍 1. Inventario de Puntos de Acceso (APs)

#### Auditoría:
- Usar herramientas como **Acrylic Wi-Fi**, **Kismet** o **Wireshark** para mapear APs activos.
- Identificar **APs rogue** (no autorizados) que puedan comprometer la red.
- Documentar:
  - Ubicación física (incluir mapa de calor si es posible).
  - Marca y modelo (ej. Cisco, Aruba, Ubiquiti).
  - Versión de firmware (verificar si está actualizado).
  - Configuración técnica:
    - Canales utilizados
    - Potencia de señal
    - SSID (visible u oculto)
    - Aislamiento de clientes

#### Recomendaciones:
- Activar detección automática de **APs no autorizados** en el controlador de red.
- Mantener **firmware actualizado**, idealmente mediante actualizaciones automatizadas.
- Desactivar **WPS** (Wi-Fi Protected Setup) por vulnerabilidades conocidas.

---

### 🔐 2. Políticas de Seguridad Wi-Fi

#### Auditoría:
Verificar existencia de un **documento formal de políticas** con los siguientes elementos:
- Uso obligatorio de **WPA3** o **WPA2-Enterprise**.
- Autenticación basada en **802.1X + RADIUS**.
- Contraseñas con rotación periódica y requisitos de complejidad:
  - Mínimo **12 caracteres**
  - Combinación alfanumérica y símbolos
- Red de invitados separada:
  - En **VLAN dedicada**
  - Con acceso restringido a recursos internos

#### Recomendaciones:
- Forzar rotación de contraseñas cada **trimestre**.
- Implementar **MFA** (Autenticación Multifactor) para administradores de red.
- Segmentar redes usando múltiples SSIDs según roles (empleados, invitados, IoT).

---

## Fase 2: Análisis de Seguridad Operativa

### 🧰 3. Análisis de Registros de Firewall (último mes)

#### Auditoría:
Buscar anomalías en logs de firewall, tales como:
- Conexiones frecuentes a **IPs extranjeras no justificadas**.
- Accesos en **horarios atípicos** (ej. entre las 2 AM y 5 AM).
- Uso de **puertos inusuales** (ej. 3389 – RDP, 23 – Telnet, 445 – SMB).

Herramientas recomendadas:
- **Splunk**
- **Graylog**
- **ELK Stack**

#### Recomendaciones:
- Aplicar **geo-bloqueo** si la empresa no opera internacionalmente.
- Cerrar **puertos innecesarios**.
- Configurar **alertas automáticas** ante picos de tráfico saliente sospechoso.

---

### ⚠️ 4. Alertas del IDS (última semana en red gubernamental)

#### Auditoría:
Clasificación de alertas por nivel de severidad:

| Severidad | Tipos de eventos |
|----------|------------------|
| Alta     | Inyecciones SQL, explotación de CVEs, escaneos activos |
| Media    | Autenticaciones fallidas múltiples, anomalías DNS |
| Baja     | Cambios menores en patrones de tráfico |

#### Respuesta sugerida (alta severidad):
- Aislar el segmento afectado.
- Recolectar evidencia forense (**tcpdump**, **pcap**).
- Actualizar firmas del IDS.
- Notificar al **CISO** y aplicar parches inmediatos si aplica.

---

### 📨 5. Registros de Correo: Análisis de Phishing (empresa minorista)

#### Auditoría:
Revisar correos electrónicos buscando:
- Adjuntos ejecutables (.exe, .scr).
- URLs acortadas o dominios similares al corporativo.
- Patrones comunes de phishing:
  - Urgencia de pago.
  - Dominios falsificados (ej. corp-sec.com vs corpsec.com).
  - Lenguaje amenazante o mal traducido.

#### Recomendaciones:
- Integrar sistemas de sandboxing de links como **Proofpoint** o **Mimecast**.
- Implementar protocolos de autenticación de correo:
  - **SPF**
  - **DKIM**
  - **DMARC**
- Capacitación recurrente con simulaciones de phishing (ej. **KnowBe4**, **PhishMe**).

---

## Fase 3: Desarrollo Seguro – Aplicaciones Android

### ✅ Lista de Verificación de Seguridad para Revisión de Código

Objetivo: Prevenir vulnerabilidades típicas en apps bancarias.

---

### 🔐 Sesiones

- Evitar uso de `SharedPreferences` sin cifrado para almacenar tokens.
- Invalidar sesión tras **logout** o **inactividad prolongada**.
- Usar **SecureStorage** o librerías de cifrado como **AES-256**.
- Renovar tokens con expiración corta (máximo **15 minutos**).

---

### 🧱 Almacenamiento Seguro

- No guardar datos sensibles en almacenamiento externo (`/sdcard/`).
- Usar `EncryptedSharedPreferences` o `SQLCipher` para bases de datos locales.
- Validar que en `AndroidManifest.xml` esté configurado:

### 🕵️ Anti-Reversing y Hardening 

- Aplicar obfuscación con ProGuard  o R8 .
- Usar SafetyNet Attestation  o Play Integrity API  para verificar integridad del dispositivo.
- Detectar entornos modificados:
    - Root/Jailbreak.
    - Hooking tools (ej. Frida , Xposed )

---

### 🔑 Autenticación 

- No almacenar credenciales localmente.
- Implementar autenticación multifactor (MFA)  con soporte de biometría.
- Obligatorio usar TLS 1.2/1.3  para comunicaciones seguras.

---

### 📁 Archivos y Recursos Adicionales (Sugeridos) 

- Para completar esta auditoría, se recomienda incluir: 

- Diagramas de red (topología, VLANs, zonas DMZ).
- Listado de dispositivos y firmware usado.
- Logs de ejemplo de firewall, IDS y correo.
- Plantillas de reporte de incidentes y hallazgos críticos.
- Scripts básicos de detección de APs rogue o revisión de políticas de red.
