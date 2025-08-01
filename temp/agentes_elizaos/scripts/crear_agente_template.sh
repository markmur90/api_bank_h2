#!/bin/bash

# Script para crear agentes usando templates JSON
# Uso: ./crear_agente_template.sh [tipo_agente] [nombre_agente] [puerto]

TEMPLATE_TYPE=${1:-"agente_completo_local"}
AGENT_NAME=${2:-"mi-agente"}
AGENT_PORT=${3:-"9182"}

echo "🤖 Creando agente: $AGENT_NAME"
echo "📋 Template: $TEMPLATE_TYPE"
echo "🌐 Puerto: $AGENT_PORT"

# Función para extraer el JSON del template
get_template_json() {
    local template_type=$1
    local agent_name=$2
    local agent_port=$3
    
    case $template_type in
        "agente_completo_local")
            cat << EOF
{
  "name": "$agent_name",
  "description": "Agente completo con todos los módulos locales, sin APIs externas",
  "version": "1.0.0",
  "plugins": [
    "@elizaos/plugin-bootstrap",
    "@elizaos/plugin-dummy-services",
    "@elizaos/plugin-sql"
  ],
  "settings": {
    "port": $agent_port,
    "host": "0.0.0.0",
    "database": {
      "type": "pglite",
      "path": "/home/markmur88/eliza-develop/.eliza"
    },
    "local_modules": {
      "gaby_fullstack": {
        "path": "/home/markmur88/eliza-develop/Gaby_fullstack",
        "enabled": true,
        "models": {
          "stable_diffusion": {
            "path": "/home/markmur88/eliza-develop/Gaby_fullstack/stable-diffusion-webui",
            "enabled": true
          },
          "huggingface": {
            "path": "/home/markmur88/eliza-develop/Gaby_fullstack/models",
            "enabled": true
          }
        }
      },
      "my_agent": {
        "path": "/home/markmur88/eliza-develop/my-agent",
        "enabled": true
      }
    },
    "no_external_apis": true,
    "local_only": true
  },
  "character": {
    "name": "$agent_name",
    "personality": "Soy $agent_name, tu asistente de IA completa que funciona 100% localmente. Tengo acceso a todos los módulos locales incluyendo generación de imágenes, procesamiento de texto, y herramientas de desarrollo.",
    "capabilities": [
      "Generación de imágenes con Stable Diffusion",
      "Procesamiento de texto local",
      "Gestión de base de datos SQL",
      "Herramientas de desarrollo",
      "Análisis de código",
      "Generación de contenido multimedia"
    ]
  }
}
EOF
            ;;
        "agente_web_developer")
            cat << EOF
{
  "name": "$agent_name",
  "description": "Agente especializado en desarrollo web y programación",
  "version": "1.0.0",
  "plugins": [
    "@elizaos/plugin-bootstrap",
    "@elizaos/plugin-sql"
  ],
  "settings": {
    "port": $agent_port,
    "host": "0.0.0.0",
    "database": {
      "type": "pglite",
      "path": "/home/markmur88/eliza-develop/.eliza"
    },
    "specializations": {
      "web_development": {
        "enabled": true,
        "frameworks": ["React", "Vue", "Angular", "Node.js", "Python", "PHP"],
        "tools": ["Git", "Docker", "Webpack", "Babel"]
      },
      "code_analysis": {
        "enabled": true,
        "languages": ["JavaScript", "TypeScript", "Python", "PHP", "Java", "C++"]
      }
    },
    "local_modules": {
      "my_agent": {
        "path": "/home/markmur88/eliza-develop/my-agent",
        "enabled": true
      }
    }
  },
  "character": {
    "name": "$agent_name",
    "personality": "Soy $agent_name, tu asistente especializado en desarrollo web y programación. Puedo ayudarte con análisis de código, debugging, optimización, y mejores prácticas de desarrollo.",
    "capabilities": [
      "Análisis y revisión de código",
      "Debugging y solución de problemas",
      "Optimización de rendimiento",
      "Arquitectura de software",
      "Mejores prácticas de desarrollo",
      "Refactoring de código"
    ]
  }
}
EOF
            ;;
        "agente_creative_writer")
            cat << EOF
{
  "name": "$agent_name",
  "description": "Agente especializado en escritura creativa y generación de contenido",
  "version": "1.0.0",
  "plugins": [
    "@elizaos/plugin-bootstrap",
    "@elizaos/plugin-dummy-services"
  ],
  "settings": {
    "port": $agent_port,
    "host": "0.0.0.0",
    "database": {
      "type": "pglite",
      "path": "/home/markmur88/eliza-develop/.eliza"
    },
    "specializations": {
      "creative_writing": {
        "enabled": true,
        "genres": ["Ficción", "No ficción", "Poesía", "Guiones", "Artículos"],
        "styles": ["Narrativo", "Descriptivo", "Persuasivo", "Expositivo"]
      },
      "content_generation": {
        "enabled": true,
        "types": ["Blog posts", "Social media", "Marketing copy", "Technical writing"]
      }
    },
    "local_modules": {
      "gaby_fullstack": {
        "path": "/home/markmur88/eliza-develop/Gaby_fullstack",
        "enabled": true,
        "models": {
          "text_generation": {
            "enabled": true
          }
        }
      }
    }
  },
  "character": {
    "name": "$agent_name",
    "personality": "Soy $agent_name, tu asistente creativo especializado en escritura y generación de contenido. Puedo ayudarte a crear historias, artículos, poesía, y cualquier tipo de contenido escrito.",
    "capabilities": [
      "Escritura creativa y narrativa",
      "Generación de poesía y versos",
      "Creación de guiones y diálogos",
      "Redacción de artículos y blogs",
      "Copywriting y marketing",
      "Edición y mejora de textos"
    ]
  }
}
EOF
            ;;
        *)
            echo "❌ Template no reconocido: $template_type"
            echo "📋 Templates disponibles:"
            echo "   - agente_completo_local"
            echo "   - agente_web_developer"
            echo "   - agente_creative_writer"
            exit 1
            ;;
    esac
}

# Crear el agente en el VPS
echo "🚀 Configurando agente en el VPS..."

ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 << EOF

echo "📁 Creando directorio del agente..."
cd eliza-develop
mkdir -p .eliza/agents/$AGENT_NAME

echo "⚙️ Generando configuración del agente..."
cat > .eliza/agents/$AGENT_NAME/config.json << 'CONFIG_EOF'
$(get_template_json $TEMPLATE_TYPE $AGENT_NAME $AGENT_PORT)
CONFIG_EOF

echo "🔧 Configurando variables de entorno..."
cat > .env << 'ENV_EOF'
PORT=$AGENT_PORT
HOST=0.0.0.0
USE_LOCAL_MODULES=true
NO_EXTERNAL_APIS=true
PGLITE_DATA_DIR=/home/markmur88/eliza-develop/.eliza
LOG_LEVEL=info
ENV_EOF

echo "🛑 Deteniendo procesos anteriores..."
pm2 stop $AGENT_NAME 2>/dev/null || true
pm2 delete $AGENT_NAME 2>/dev/null || true

echo "🚀 Iniciando agente $AGENT_NAME..."
cd packages/cli
pm2 start dist/index.js --name "$AGENT_NAME"

echo "⏳ Esperando que el agente se inicie..."
sleep 5

echo "🔍 Verificando estado..."
if pm2 list | grep -q "$AGENT_NAME.*online"; then
    echo "✅ Agente $AGENT_NAME iniciado correctamente!"
    echo "🌐 Accesible en: http://amara.coretransapi.com:$AGENT_PORT"
    echo "🌐 Accesible en: http://80.78.30.242:$AGENT_PORT"
    
    echo "📊 Estado del puerto:"
    netstat -tlnp | grep :$AGENT_PORT || echo "⚠️ Puerto $AGENT_PORT no detectado"
    
    echo "📋 Información del agente:"
    pm2 show $AGENT_NAME
    
else
    echo "❌ Error al iniciar el agente $AGENT_NAME"
    pm2 logs $AGENT_NAME --lines 10
fi

EOF

echo "🎉 Agente $AGENT_NAME creado exitosamente!"
echo "🤖 Template: $TEMPLATE_TYPE"
echo "🌐 URL: http://amara.coretransapi.com:$AGENT_PORT"
echo "📁 Configuración: /home/markmur88/eliza-develop/.eliza/agents/$AGENT_NAME/config.json" 