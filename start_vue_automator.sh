#!/bin/zsh

# 1. Configurar un PATH completo para asegurar que todos los comandos se encuentren.
# Se prioriza la ruta de Homebrew para comandos.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_PATH="/Users/paolazapatagonzalez/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
PROJECT_NAME="vue-gamestream"

# Asegúrate de que el script cambie al directorio del proyecto
cd "$PROJECT_PATH" || { echo "❌ No se pudo entrar a la carpeta del proyecto. Abortando." >&2; exit 1 }

echo "🚀 Iniciando proyecto $PROJECT_NAME..."

if [[ "$PROJECT_PATH" == *"/Downloads/"* ]]; then
  echo "⚠ Estás trabajando desde la carpeta Downloads. Puede que Sublime solicite permisos."
fi

---

# Preguntar si el usuario quiere ejecutar el archivo git.sh
SHOULD_RUN_HOLA=$(osascript -e 'display dialog "¿Quieres ejecutar el script \"git.sh\"?" buttons {"No", "Sí"} default button "Sí" with icon caution' -e 'button returned of result')

if [[ "$SHOULD_RUN_HOLA" == "Sí" ]]; then
  # Ruta al script git.sh
  HOLA_SCRIPT="$PROJECT_PATH/git.sh"

  if [ -f "$HOLA_SCRIPT" ]; then
    echo "🔄 Ejecutando script: '$HOLA_SCRIPT'..."
    "$HOLA_SCRIPT"
    if [ $? -eq 0 ]; then
      echo "✅ Script 'git.sh' completado."
    else
      echo "❌ El script 'git.sh' terminó con errores. Revisa la salida de Automator."
    fi
  else
    echo "❌ Error: El script 'git.sh' no se encontró en '$HOLA_SCRIPT'."
    echo "Asegúrate de que el archivo exista y esté en la ubicación correcta."
  fi
else
  echo "⏩ Saltando la ejecución de 'git.sh'."
fi

---

echo "--- Continuando con el proyecto ---"

# Abrir Sublime Text usando 'open -a' si 'subl' no funciona directamente.
if ! command -v subl &> /dev/null; then
  echo "❌ 'subl' no está disponible directamente. Intentando abrir Sublime Text con 'open -a'."
  open -a "Sublime Text" "$PROJECT_PATH" &
else
  echo "📝 Abriendo en Sublime Text usando 'subl'..."
  subl "$PROJECT_PATH" &
fi

sleep 2 # Pequeña pausa para permitir que Sublime se inicie

echo "📦 Ejecutando 'npm run dev'..."
# Captura la salida de npm en un archivo de log para luego buscar la URL
npm run dev > "$PROJECT_PATH/logs/npm_output.log" 2>&1 &
NPM_PID=$! # Guarda el PID de npm para poder matarlo si es necesario

echo "Esperando la URL local..."
URL_FOUND=false
TIMEOUT=60 # Esperar hasta 60 segundos por la URL

for i in $(seq 1 $TIMEOUT); do
  if grep -q "Local:" "$PROJECT_PATH/logs/npm_output.log"; then
    url=$(grep "Local:" "$PROJECT_PATH/logs/npm_output.log" | grep -o 'http://[^ ]*' | head -1)
    if [[ -n "$url" ]]; then
      echo "🌐 Abriendo navegador en $url"
      open "$url"
      URL_FOUND=true
      break
    fi
  fi
  sleep 1
done

if [ "$URL_FOUND" = false ]; then
  echo "❌ No se encontró la URL local después de $TIMEOUT segundos. Revisa $PROJECT_PATH/logs/npm_output.log para errores."
fi

echo "Script finalizado. El servidor de desarrollo Vue debería estar ejecutándose."