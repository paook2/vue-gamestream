#!/bin/zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

PROJECT_PATH="$HOME/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
LOG_DIR="$PROJECT_PATH/logs"
NPM_OUTPUT_LOG="$LOG_DIR/npm_output.log"
TEMP_EXEC_SCRIPT="$LOG_DIR/run_npm_dev_temp.sh"

cd "$PROJECT_PATH" || { echo "❌ No se pudo acceder al directorio del proyecto."; exit 1; }

mkdir -p "$LOG_DIR" || { echo "❌ No se pudo crear la carpeta de logs en '$LOG_DIR'."; exit 1; }
: > "$NPM_OUTPUT_LOG"

# 🟡 NUEVO: Preguntar si se debe ejecutar git.sh
SHOULD_RUN_GIT=$(osascript -e 'display dialog "¿Quieres ejecutar el script \"git.sh\"?" buttons {"No", "Sí"} default button "Sí" with icon caution' -e 'button returned of result')

if [[ "$SHOULD_RUN_GIT" == "Sí" ]]; then
  GIT_SCRIPT="$PROJECT_PATH/git.sh"

  if [ -f "$GIT_SCRIPT" ]; then
    echo "🔄 Ejecutando script: '$GIT_SCRIPT'..."
    "$GIT_SCRIPT"
    if [ $? -eq 0 ]; then
      echo "✅ Script 'git.sh' completado."
    else
      echo "❌ El script 'git.sh' terminó con errores."
    fi
  else
    echo "❌ No se encontró 'git.sh' en: $GIT_SCRIPT"
  fi
else
  echo "⏩ Saltando ejecución de 'git.sh'."
fi

# Continuar con npm run dev
echo "📦 Ejecutando 'npm run dev' en nueva ventana de Terminal..."

NPM_BIN_PATH="$(which npm)"
if [ -z "$NPM_BIN_PATH" ]; then
  echo "❌ No se encontró 'npm'. Instala Node.js para continuar."
  exit 1
fi

cat > "$TEMP_EXEC_SCRIPT" <<EOF
#!/bin/zsh
cd "${PROJECT_PATH}" || exit 1
"${NPM_BIN_PATH}" run dev > "${NPM_OUTPUT_LOG}" 2>&1
exit
EOF

chmod +x "$TEMP_EXEC_SCRIPT"

osascript <<EOF
tell application "Terminal"
    activate
    do script "${TEMP_EXEC_SCRIPT}"
end tell
EOF

echo "⌛ Esperando URL local..."
URL_FOUND=false
TIMEOUT=60

for i in $(seq 1 $TIMEOUT); do
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
  echo "❌ No se encontró la URL después de $TIMEOUT segundos."
  echo "📄 Revisa el log: $NPM_OUTPUT_LOG"
fi

echo "✅ Script finalizado."
exit 0
