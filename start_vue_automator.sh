#!/bin/zsh

# 1. Configurar un PATH completo para asegurar que todos los comandos se encuentren.
# Se prioriza la ruta de Homebrew para comandos.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_PATH="/Users/paolazapatagonzalez/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
PROJECT_NAME="vue-gamestream"
LOG_DIR="$PROJECT_PATH/logs"
NPM_OUTPUT_LOG="$LOG_DIR/npm_output.log" # Todavía útil para depuración si la terminal no se abre

# Asegúrate de que el script cambie al directorio del proyecto
cd "$PROJECT_PATH" || { echo "❌ No se pudo entrar a la carpeta del proyecto. Abortando." >&2; exit 1 }

echo "🚀 Iniciando proyecto $PROJECT_NAME..."

if [[ "$PROJECT_PATH" == *"/Downloads/"* ]]; then
  echo "⚠ Estás trabajando desde la carpeta Downloads. Puede que Sublime solicite permisos."
fi

# --- Inicio del TRAP ---
# Esta función se ejecutará cuando el script reciba una señal de terminación
cleanup_on_exit() {
  echo "🚨 Script de Automatización principal terminando."
  # No matamos npm_PID aquí directamente porque ahora se ejecutará en su propia ventana de Terminal.
  # La terminal debería mantener el proceso vivo hasta que la cierres o se complete.
  echo "✅ Script principal finalizado."
}

trap cleanup_on_exit INT TERM EXIT
# --- Fin del TRAP ---

---

# Preguntar si el usuario quiere ejecutar el archivo git.sh
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

# Abrir Sublime Text usando 'open -a' si 'subl' no funciona directamente.
if ! command -v subl &> /dev/null; then
  echo "❌ 'subl' no está disponible directamente. Intentando abrir Sublime Text con 'open -a'."
  open -a "Sublime Text" "$PROJECT_PATH" &
else
  echo "📝 Abriendo en Sublime Text usando 'subl'..."
  subl "$PROJECT_PATH" &
fi

sleep 2 # Pequeña pausa para permitir que Sublime se inicie

echo "📦 Ejecutando 'npm run dev' en una nueva ventana de Terminal..."

# Crear la carpeta de logs si no existe (todavía útil para el caso de error de 'open -a Terminal')
mkdir -p "$LOG_DIR" || { echo "❌ No se pudo crear la carpeta de logs en '$LOG_DIR'. Abortando." >&2; exit 1; }


# Comando para abrir una nueva Terminal y ejecutar npm run dev
# Esto ejecutará `npm run dev` en una nueva ventana de Terminal y la mantendrá abierta
osascript -e 'tell application "Terminal" to activate' \
          -e '  tell application "System Events" to keystroke "t" using command down' \
          -e '  delay 1' \
          -e '  tell application "Terminal" to do script "cd \"'${PROJECT_PATH}'\" && npm run dev" in front window' \
          > "$NPM_OUTPUT_LOG" 2>&1 & # Todavía redirigimos la salida del osascript para capturar errores si no abre la terminal.

echo "Esperando que el servidor se inicie y obteniendo la URL local..."
URL_FOUND=false
TIMEOUT=60 # Esperar hasta 60 segundos por la URL

for i in $(seq 1 $TIMEOUT); do
  # Aquí leeremos del log que se genera en la Terminal si el comando osascript falla,
  # o si queremos asegurar que la URL se capture incluso si la Terminal no queda visible.
  # PERO la URL de "Local:" ahora se imprimirá en la nueva ventana de Terminal.
  # Para leerla, necesitamos un mecanismo diferente o confiar en que se abre la Terminal.
  # Para mantener la funcionalidad de apertura automática, podemos seguir leyendo el log,
  # ya que `npm run dev` sigue imprimiendo allí.
  if grep -q "Local:" "$NPM_OUTPUT_LOG"; then
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
  echo "❌ No se encontró la URL local después de $TIMEOUT segundos. Revisa $NPM_OUTPUT_LOG para errores."
  echo "Asegúrate de que la nueva ventana de Terminal se abrió y el servidor Vite se inició."
fi

echo "Script finalizado. Revisa la nueva ventana de Terminal para la salida de 'npm run dev'."