#!/bin/zsh

# 1. Configurar un PATH completo para asegurar que todos los comandos se encuentren.
# Se prioriza la ruta de Homebrew para comandos.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_PATH="/Users/paolazapatagonzalez/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
PROJECT_NAME="vue-gamestream"
LOG_DIR="$PROJECT_PATH/logs"
NPM_OUTPUT_LOG="$LOG_DIR/npm_output.log"

# Asegúrate de que el script cambie al directorio del proyecto
cd "$PROJECT_PATH" || { echo "❌ No se pudo entrar a la carpeta del proyecto. Abortando." >&2; exit 1; }

echo "🚀 Iniciando proyecto $PROJECT_NAME..."

if [[ "$PROJECT_PATH" == *"/Downloads/"* ]]; then
  echo "⚠ Estás trabajando desde la carpeta Downloads. Puede que Sublime solicite permisos."
fi

# --- Inicio del TRAP ---
# Este TRAP es para el script PRINCIPAL de Automator, no para el npm run dev en la nueva terminal.
cleanup_on_exit() {
  echo "🚨 Script principal de Automator terminando su ejecución."
  # Puedes añadir aquí cualquier limpieza final que necesite el script principal,
  # pero NO intentes matar npm run dev aquí, ya que corre en su propia terminal.
}

# Configura la trampa para ejecutar la función cleanup_on_exit
# en caso de interrupción (Ctrl+C), terminación (kill) o salida del script.
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

# Crear la carpeta de logs si no existe
mkdir -p "$LOG_DIR" || { echo "❌ No se pudo crear la carpeta de logs en '$LOG_DIR'. Abortando." >&2; exit 1; }

# Elimina el contenido anterior del log para una ejecución limpia
echo "" > "$NPM_OUTPUT_LOG"

# ************ REVISIÓN CLAVE PARA LANZAR EN TERMINAL ************
# Aseguramos que la ejecución en la terminal sea robusta.
# Se usa `zsh -l` para cargar un shell de login (que lee .zprofile, .zshrc, etc.),
# y el comando `npm run dev` se envuelve en comillas dobles para que el shell lo interprete correctamente.
# Además, la redirección `> \"'${NPM_OUTPUT_LOG}'\" 2>&1` se hace dentro del comando que se le pasa a Terminal.app.
# El `&` al final del `do script` permite que el script de Automator continúe.

# NOTA: La ruta de `npm` dentro del comando de Terminal debería ser la que obtienes con `which npm`
# en una Terminal normal. Por ejemplo, si `which npm` te da `/opt/homebrew/bin/npm`, usa esa ruta.
# O déjalo como `npm` si tu PATH ya está bien configurado en la Terminal de macOS por defecto.
# Probemos con el comando completo ya que a veces los scripts de inicio de zsh requieren que se cargue todo.
# Si tu `which npm` te da `/usr/local/bin/npm`, usa esa ruta en vez de `/opt/homebrew/bin/npm`.

NPM_COMMAND_IN_TERMINAL="cd \\\"${PROJECT_PATH}\\\" && /usr/local/bin/npm run dev > \\\"${NPM_OUTPUT_LOG}\\\" 2>&1"
# ^^^ Reemplaza `/usr/local/bin/npm` con la salida de `which npm` si es diferente.
# Si sigue fallando, prueba con un comando más simple para depurar la terminal:
# NPM_COMMAND_IN_TERMINAL="echo \\\"Testing terminal execution\\\" > \\\"${NPM_OUTPUT_LOG}\\\" 2>&1 && ls -la >> \\\"${NPM_OUTPUT_LOG}\\\" 2>&1"


osascript -e 'tell application "Terminal" to activate' \
          -e '  tell application "System Events" to keystroke "t" using command down' \
          -e '  delay 1' \
          -e '  tell application "Terminal" to do script "${NPM_COMMAND_IN_TERMINAL}" in front window' &

echo "Esperando que el servidor se inicie y obteniendo la URL local para abrir el navegador..."
URL_FOUND=false
TIMEOUT=60 # Esperar hasta 60 segundos por la URL

for i in $(seq 1 $TIMEOUT); do
  # El NPM_OUTPUT_LOG ahora debería ser escrito por npm run dev en la nueva Terminal.
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
  echo "❌ No se encontró la URL local después de $TIMEOUT segundos."
  echo "Por favor, revisa la nueva ventana de Terminal para la salida de 'npm run dev' y la URL."
  echo "Si la Terminal no se abrió, revisa el log de Automator para ver errores de AppleScript."
fi

echo "Script finalizado. El servidor de desarrollo Vue debería estar ejecutándose en la nueva Terminal."
# Es CRÍTICO que el script principal termine aquí.
# Si se sigue colgando la aplicación de Automator, el problema no es el script de shell,
# sino la configuración del "Ejecutar script de Shell" en Automator o un bloqueo del SO.
exit 0 # Asegura que el script de shell termine explícitamente.