#!/bin/zsh

# 1. Configurar un PATH completo para asegurar que todos los comandos se encuentren.
# Se prioriza la ruta de Homebrew para Git para sistemas Apple Silicon.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_PATH="/Users/paolazapatagonzalez/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
PROJECT_NAME="vue-gamestream"

# Asegúrate de que el script cambie al directorio del proyecto antes de ejecutar cualquier comando Git
cd "$PROJECT_PATH" || { echo "❌ No se pudo entrar a la carpeta del proyecto. Abortando." >&2; exit 1 }

echo "🚀 Iniciando proyecto $PROJECT_NAME..."

if [[ "$PROJECT_PATH" == *"/Downloads/"* ]]; then
  echo "⚠ Estás trabajando desde la carpeta Downloads. Puede que Sublime solicite permisos."
fi

# --- Flujo de Git ---

# Preguntar si el usuario quiere verificar la sincronización de ramas
SHOULD_CHECK_SYNC=$(osascript -e 'display dialog "Quieres verificar la sincronización de ramas de Git?" buttons {"No", "Sí"} default button "Sí" with icon caution' -e 'button returned of result')

if [[ "$SHOULD_CHECK_SYNC" == "Sí" ]]; then
  # Solicitar la primera rama
  RAMA1=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Ingresa el nombre de la PRIMERA rama para verificar:" default answer "main")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  # Solicitar la segunda rama
  RAMA2=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Ingresa el nombre de la SEGUNDA rama para verificar:" default answer "dev")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  # Comprobar si el usuario canceló alguno de los diálogos (o dejó vacío)
  if [ -z "$RAMA1" ] || [ -z "$RAMA2" ]; then
    echo "❌ Nombres de ramas no proporcionados para la verificación. Saltando la verificación de Git."
  else
    # Verifica si git-check-sync existe antes de intentar usarlo
    if command -v git-check-sync &> /dev/null; then
      echo "🔍 Verificando sincronización de ramas ($RAMA1 vs $RAMA2)..."
      git-check-sync "$RAMA1" "$RAMA2"
      echo "✅ Verificación de Git completada."
    else
      echo "❌ La función 'git-check-sync' no está disponible. Saltando la verificación de Git."
    fi
  fi
else
  echo "⏩ Saltando la verificación de sincronización de ramas."
fi

---

# Preguntar si el usuario quiere actualizar una rama desde la principal
SHOULD_UPDATE_BRANCH=$(osascript -e 'display dialog "Quieres actualizar una rama desde la principal (merge, commit y push)?" buttons {"No", "Sí"} default button "No" with icon caution' -e 'button returned of result')

if [[ "$SHOULD_UPDATE_BRANCH" == "Sí" ]]; then
  # >>> MODIFICACIÓN CLAVE AQUÍ: Solicitar los parámetros para git_update.sh con osascript <<<
  MAIN_BRANCH_FOR_UPDATE=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Ingresa la rama principal para la actualización (ej: main):" default answer "main")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  TARGET_BRANCH_FOR_UPDATE=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Ingresa la rama a actualizar (ej: develop):" default answer "dev")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  UNTRACKED_COMMIT_MSG=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Mensaje para commit de archivos nuevos/sin seguimiento (si aplica):" default answer "feat: (automated) Add untracked files")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  LOCAL_COMMIT_MSG=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Mensaje para commit de cambios locales (si aplica):" default answer "feat: (automated) WIP changes before merge")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  # Asegúrate de que los parámetros obligatorios no estén vacíos si el usuario canceló
  if [ -z "$MAIN_BRANCH_FOR_UPDATE" ] || [ -z "$TARGET_BRANCH_FOR_UPDATE" ]; then
      echo "❌ Nombres de ramas no proporcionados para la actualización. Saltando la actualización de Git."
  else
      # Ruta al script git_update.sh
      GIT_UPDATE_SCRIPT="$PROJECT_PATH/git_update.sh"

      if [ -f "$GIT_UPDATE_SCRIPT" ]; then
        echo "🔄 Ejecutando script de actualización de rama: '$GIT_UPDATE_SCRIPT'..."
        # Pasa los parámetros como argumentos al script
        # Redirige la salida estándar y de error a un archivo log temporal para depuración
        "$GIT_UPDATE_SCRIPT" "$MAIN_BRANCH_FOR_UPDATE" "$TARGET_BRANCH_FOR_UPDATE" "$UNTRACKED_COMMIT_MSG" "$LOCAL_COMMIT_MSG" > "/tmp/git_update_debug_$(date +%Y%m%d_%H%M%S).log" 2>&1
        # Muestra el contenido del log en la salida de Automator
        cat "/tmp/git_update_debug_$(date +%Y%m%d_%H%M%S).log"

        if [ $? -eq 0 ]; then
          echo "✅ Actualización de rama completada. Revisa la salida del script y el log para detalles."
        else
          echo "❌ El script de actualización de rama terminó con errores. Revisa la salida de Automator y el archivo de log."
        fi
      else
        echo "❌ Error: El script 'git_update.sh' no se encontró en '$GIT_UPDATE_SCRIPT'."
        echo "Asegúrate de que el archivo exista y esté en la ubicación correcta."
      fi
  fi
else
  echo "⏩ Saltando la actualización de ramas."
fi

---

# Preguntar si el usuario quiere hacer un commit y push (el commit/push general del proyecto)
SHOULD_COMMIT=$(osascript -e 'display dialog "Quieres hacer un commit y push ahora?" buttons {"No", "Sí"} default button "No" with icon caution' -e 'button returned of result')

if [[ "$SHO_COMMIT" == "Sí" ]]; then
  # Solicitar el mensaje del commit
  COMMIT_MSG=$(osascript -e 'try' -e '    set T to text returned of (display dialog "Ingresa el mensaje para el commit:" default answer "feat: (automated) Initial setup")' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try')

  # Solicitar la rama para hacer push
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null) # Intenta obtener la rama actual
  if [ -z "$CURRENT_BRANCH" ]; then
      CURRENT_BRANCH="main" # Valor por defecto si no se puede obtener la rama actual
  fi
  # Manejo robusto de la rama por defecto para AppleScript
  PUSH_BRANCH=$(osascript -e 'on run argv' -e 'set defaultBranch to item 1 of argv' -e 'try' -e '    set T to text returned of (display dialog "Ingresa la rama a la que deseas hacer push:" default answer defaultBranch)' -e '    return T' -e 'on error number -128' -e '    return ""' -e 'end try' -- "$CURRENT_BRANCH")

  # Comprobar si el usuario canceló los diálogos
  if [ -z "$COMMIT_MSG" ] || [ -z "$PUSH_BRANCH" ]; then
    echo "❌ Mensaje de commit o rama de push no proporcionados. Saltando el commit y push."
  else
    # Verifica si git-commit-and-push existe antes de intentar usarlo
    if command -v git-commit-and-push &> /dev/null; then
      echo "📦 Realizando commit y push..."
      git-commit-and-push "$COMMIT_MSG" "$PUSH_BRANCH"
    else
      echo "❌ La función 'git-commit-and-push' no está disponible. Saltando el commit y push."
    fi
  fi
else
  echo "⏩ Saltando el commit y push de Git."
fi

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
npm run dev > "$PROJECT_PATH/npm_output.log" 2>&1 &
NPM_PID=$! # Guarda el PID de npm para poder matarlo si es necesario

echo "Esperando la URL local..."
URL_FOUND=false
TIMEOUT=60 # Esperar hasta 60 segundos por la URL

for i in $(seq 1 $TIMEOUT); do
  if grep -q "Local:" "$PROJECT_PATH/npm_output.log"; then
    url=$(grep "Local:" "$PROJECT_PATH/npm_output.log" | grep -o 'http://[^ ]*' | head -1)
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
  echo "❌ No se encontró la URL local después de $TIMEOUT segundos. Revisa $PROJECT_PATH/npm_output.log para errores."
fi

echo "Script finalizado. El servidor de desarrollo Vue debería estar ejecutándose."