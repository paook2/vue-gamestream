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
    # Ejecuta el script git.sh directamente para ver su salida en la consola
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
# Ejecuta npm run dev directamente. Su salida se mostrará en la consola del Automator.
# No redirijas a un archivo si quieres ver la salida en vivo.
npm run dev &
NPM_PID=$! # Guarda el PID de npm para poder matarlo si es necesario

# NOTA: Sin la redirección a un archivo, el script ya no puede "leer"
# la URL automáticamente de un log. Necesitarás abrir el navegador manualmente
# o usar otro método para capturar la URL (por ejemplo, esperar un tiempo fijo).

# Como ya no se lee de un log, las siguientes líneas para esperar y abrir la URL
# basándose en el log ya no funcionarán con este cambio.
# Las dejaremos comentadas o las quitaremos, ya que el objetivo es ver la salida en vivo.

# Si aún necesitas abrir la URL automáticamente y ver la consola,
# la forma más robusta es ejecutar 'npm run dev' en una nueva ventana de terminal
# y que el script principal siga un flujo diferente.

echo "El servidor de desarrollo Vue se está iniciando en segundo plano. La salida se mostrará aquí."
echo "Busca manualmente la URL local en la salida de la consola."
echo "Script finalizado. El servidor de desarrollo Vue debería estar ejecutándose."