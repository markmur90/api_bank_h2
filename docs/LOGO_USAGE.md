# 🎨 Guía de Uso del Logo - API BanK

## 📋 Descripción

El logo de API BanK es una "C" estilizada en 3D con efectos de luz azul y púrpura, diseñada para transmitir modernidad y tecnología.

## 📁 Archivos Disponibles

### Versiones Optimizadas
- `logo_header.png` (40x40) - Para el header principal
- `logo_navbar.png` (28x28) - Para la barra de navegación
- `logo_mobile.png` (24x24) - Para dispositivos móviles
- `logo_favicon.png` (32x32) - Para favicon
- `logo_large.png` (64x64) - Para modales y popups
- `favicon.ico` (32x32) - Favicon del sitio web

### Ubicación
```
static/images/optimized/
```

## 🎯 Clases CSS Disponibles

### Clases Principales
- `.header-logo` - Logo para el header principal
- `.navbar-logo` - Logo para la barra de navegación
- `.modal-logo` - Logo para modales y popups
- `.card-logo` - Logo para tarjetas y widgets
- `.footer-logo` - Logo para el footer

### Clases de Efectos
- `.logo-glow` - Efecto de brillo azul
- `.logo-loading` - Animación de pulso
- `.logo-bordered` - Logo con borde

## 💻 Ejemplos de Uso

### 1. Header Principal
```html
<img src="{% static 'images/optimized/logo_header.png' %}" 
     alt="API BanK Logo" 
     class="header-logo">
```

### 2. Barra de Navegación
```html
<img src="{% static 'images/optimized/logo_navbar.png' %}" 
     alt="API BanK Logo" 
     class="navbar-logo">
```

### 3. Modal o Popup
```html
<img src="{% static 'images/optimized/logo_large.png' %}" 
     alt="API BanK Logo" 
     class="modal-logo">
```

### 4. Tarjeta con Efecto
```html
<img src="{% static 'images/optimized/logo_large.png' %}" 
     alt="API BanK Logo" 
     class="card-logo logo-glow">
```

### 5. Footer
```html
<img src="{% static 'images/optimized/logo_favicon.png' %}" 
     alt="API BanK Logo" 
     class="footer-logo">
```

## 🔧 Optimización Automática

### Script de Optimización
```bash
python scripts/optimize_logo.py
```

Este script:
- Redimensiona el logo original (1024x1024)
- Crea versiones optimizadas para diferentes usos
- Mejora la nitidez y calidad
- Genera el favicon.ico

### Requisitos
```bash
pip install Pillow
```

## 📱 Responsive Design

El logo se adapta automáticamente a diferentes tamaños de pantalla:

- **Desktop**: Tamaño completo
- **Tablet**: Reducción del 20%
- **Mobile**: Reducción del 40%

## 🎨 Personalización

### Cambiar Colores de Efectos
```css
.logo-glow {
    filter: drop-shadow(0 0 8px rgba(59, 130, 246, 0.5));
}
```

### Ajustar Tamaños
```css
.header-logo {
    height: 40px;
    max-width: 40px;
}
```

## ✅ Mejores Prácticas

1. **Siempre usar las versiones optimizadas** para mejor rendimiento
2. **Incluir alt text** para accesibilidad
3. **Usar las clases CSS apropiadas** para cada contexto
4. **Mantener proporciones** - no estirar el logo
5. **Usar el favicon.ico** en el head del HTML

## 🚀 Implementación Actual

### Archivos Modificados
- `templates/partials/header.html` - Logo en header
- `templates/partials/navGeneral.html` - Logo en navbar
- `templates/partials/footer.html` - Logo en footer
- `templates/base.html` - Favicon y CSS
- `templates/client.html` - Logo en página de cliente

### CSS Incluido
- `static/css/logo-styles.css` - Estilos específicos del logo

## 🔄 Actualización del Logo

Para actualizar el logo:

1. Reemplazar `static/images/logo.png` con la nueva versión
2. Ejecutar `python scripts/optimize_logo.py`
3. Los archivos optimizados se actualizarán automáticamente

## 📞 Soporte

Para problemas con el logo o solicitudes de personalización, contactar al equipo de desarrollo.
