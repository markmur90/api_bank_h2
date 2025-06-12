# Checklist de Auditoría de Aplicaciones Android

## Sesión y Autenticación
- [ ] No se usa SharedPreferences para tokens sensibles.
- [ ] Tiempo de expiración corto y renovación de tokens.
- [ ] Logout invalida sesión por completo.

## Almacenamiento de Datos
- [ ] Sin datos sensibles en almacenamiento externo.
- [ ] EncryptedSharedPreferences o SQLCipher habilitados.
- [ ] `android:allowBackup="false"` en manifest.

## Comunicaciones
- [ ] TLS 1.2 mínimo requerido.
- [ ] Cert pinning habilitado.
- [ ] No se usan URLs en texto plano.

## Hardening
- [ ] Código ofuscado (ProGuard/R8).
- [ ] Detección de root y hooking activa.
- [ ] SafetyNet/Play Integrity implementado.
