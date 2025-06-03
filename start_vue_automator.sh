#!/bin/zsh

# 1. Configurar un PATH completo para asegurar que todos los comandos se encuentren.
# Se prioriza la ruta de Homebrew para comandos.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_PATH="/Users/paolazapatagonzalez/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
PROJECT_NAME="vue-gamestream"
LOG_DIR="$PROJECT_PATH/logs"
NPM_OUTPUT_LOG="$LOG_DIR/npm_output.log" # <--- Ruta corregida aquí

# Asegúrate de que el script cambie al directorio del proyecto
cd "$PROJECT_PATH" || { echo "❌ No se pudo entrar a la carpeta del proyecto. Abortando." >&2; exit 1 }

echo "🚀 Iniciando proyecto $PROJECT_NAME..."

if [[ "$PROJECT_PATH" == *"/Downloads/"* ]]; then
  echo "⚠ Estás trabajando desde la carpeta Downloads. Puede que Sublime solicite permisos."
fi

# --- Inicio del TRAP ---
cleanup_on_exit() {
  echo "🚨 Script terminando. Deteniendo proceso de npm run dev (PID: $NPM_PID)..."
  if [ -n "$NPM_PID" ] && ps -p "$NPM_PID" > /dev/null; then
    kill -TERM "$NPM_PID"
    sleep 2
    if ps -p "$NPM_PID" > /dev/null; then
      echo "⚠️ El proceso de npm (PID: $NPM_PID) no se cerró amistosamente. Forzando cierre..."
      kill -KILL "$NPM_PID"
    fi
  else
    echo "ℹ️ No se encontró un proceso de npm run dev activo para detener."
  fi
  echo "✅ Limpieza completada."
}

trap cleanup_on_exit INT TERM EXIT
# --- Fin del TRAP ---

---

# Preguntar si el usuario quiere ejecutar el archivo git.sh
# Forzar la activación de System Events para asegurar que el diálogo se muestre al frente
osascript -e 'tell application "System Events" to activate' > /dev/null 2>&1
SHOULD_RUN_HOLA=$(osascript -e 'display dialog "¿Quieres ejecutar el script \"git.sh\"?" buttons {"No", "Sí"} default button "Sí" with icon caution' -e 'button returned of result')

if [[ "$SHOULD_RUN_HOLA" == "Sí" ]]; then
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

if ! command -v subl &> /dev/null; then
  echo "❌ 'subl' no está disponible directamente. Intentando abrir Sublime Text con 'open -a'."
  open -a "Sublime Text" "$PROJECT_PATH" &
else
  echo "📝 Abriendo en Sublime Text usando 'subl'..."
  subl "$PROJECT_PATH" &
fi

sleep 2

echo "📦 Ejecutando 'npm run dev'..."
mkdir -p "$LOG_DIR" || { echo "❌ No se pudo crear la carpeta de logs en '$LOG_DIR'. Abortando." >&2; exit 1; }

npm run dev > "$NPM_OUTPUT_LOG" 2>&1 & # <--- Se usa la variable de ruta corregida aquí
NPM_PID=$!

echo "Esperando la URL local..."
URL_FOUND=false
TIMEOUT=60

for i in $(seq 1 $TIMEOUT); do
  if grep -q "Local:" "$NPM_OUTPUT_LOG"; then # <--- Se usa la variable de ruta corregida aquí
    url=$(grep "Local:" "$NPM_OUTPUT_LOG" | grep -o 'http://[^ ]*' | head -1)
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
  echo "❌ No se encontró la URL local después de $TIMEOUT segundos. Revisa $NPM_OUTPUT_LOG para errores." # <--- Se usa la variable de ruta corregida aquí
fi

echo "Script finalizado. El servidor de desarrollo Vue debería estar ejecutándose."