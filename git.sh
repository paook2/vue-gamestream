#!/bin/zsh

osascript -e 'display dialog "Bienvenido a GIT" with title "Mensaje de git.sh" buttons {"OK"} default button 1'

echo "--- Automatización de Fusión y Push en Git ---"

echo "---"

# --- Manejo de cambios pendientes
echo "Verificando estado del repositorio..."

untracked_files=$(git status --porcelain | grep "^??" | awk '{print $2}')
staged_changes=$(git diff --cached --name-only)
unstaged_changes=$(git diff --name-only)

if [ -n "$untracked_files" ] || [ -n "$staged_changes" ] || [ -n "$unstaged_changes" ]; then
  echo "Cambios pendientes detectados. Añadiendo todo..."
  git add . || { echo "Error: No se pudieron añadir cambios."; exit 1; }

  COMMIT_MSG=$(osascript -e 'try' -e 'set T to text returned of (display dialog "Ingresa mensaje para commit:" default answer "feat: (automated) WIP changes detected")' -e 'return T' -e 'on error number -128' -e 'return ""' -e 'end try')

  if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="feat: (automated) Committing detected changes"
  fi

  git commit -m "$COMMIT_MSG" || { echo "Error: No se pudo hacer commit."; exit 1; }

  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$current_branch" != "HEAD" ] && [ -n "$current_branch" ]; then
    echo "Empujando cambios pendientes a 'origin/$current_branch'..."
    git push origin "$current_branch" || echo "Advertencia: No se pudieron empujar los cambios pendientes."
  fi
else
  echo "No hay cambios pendientes."
fi

echo "---"

# --- Fusión principal -> secundaria con actualización local y remoto
MAIN_BRANCH=$(osascript -e 'try' -e 'set T to text returned of (display dialog "Nombre de rama principal (ej: main, master):" default answer "main")' -e 'return T' -e 'on error number -128' -e 'return ""' -e 'end try')

if [ -z "$MAIN_BRANCH" ]; then
  osascript -e 'display alert "Error: Nombre de la rama principal no puede estar vacío." as warning'
  exit 1
fi

TARGET_BRANCH=$(osascript -e 'try' -e 'set T to text returned of (display dialog "Nombre de la rama a actualizar:" default answer "dev")' -e 'return T' -e 'on error number -128' -e 'return ""' -e 'end try')

if [ -z "$TARGET_BRANCH" ]; then
  osascript -e 'display alert "Error: Nombre de la rama a actualizar no puede estar vacío." as warning'
  exit 1
fi

if [ "$MAIN_BRANCH" = "$TARGET_BRANCH" ]; then
  osascript -e 'display alert "Error: La rama principal y la rama destino no pueden ser iguales." as warning'
  exit 1
fi

echo "Cambiando a la rama principal: $MAIN_BRANCH"
git checkout "$MAIN_BRANCH" || { osascript -e "display alert \"Error: No se pudo cambiar a la rama $MAIN_BRANCH.\" as critical"; exit 1; }

echo "Actualizando $MAIN_BRANCH desde remoto..."
git pull origin "$MAIN_BRANCH" || osascript -e "display alert \"No se pudo actualizar $MAIN_BRANCH.\" as warning"

echo "Cambiando a la rama destino: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH" || { osascript -e "display alert \"Error: No se pudo cambiar a la rama $TARGET_BRANCH.\" as critical"; exit 1; }

echo "Actualizando $TARGET_BRANCH desde remoto..."
git pull origin "$TARGET_BRANCH" || osascript -e "display alert \"No se pudo actualizar $TARGET_BRANCH.\" as warning"

echo "Fusionando $MAIN_BRANCH en $TARGET_BRANCH..."
git merge "$MAIN_BRANCH"

if [ $? -ne 0 ]; then
  osascript -e 'display alert "Conflictos en la fusión, resuélvelos manualmente." as critical'
  exit 1
fi

if ! git diff --cached --exit-code; then
  echo "Comiteando cambios de la fusión..."
  git commit -m "Merge branch '$MAIN_BRANCH' into '$TARGET_BRANCH'" || { osascript -e "display alert \"No se pudo hacer commit de la fusión.\" as critical"; exit 1; }
fi

echo "Empujando $TARGET_BRANCH al remoto..."
git push origin "$TARGET_BRANCH" || osascript -e "display alert \"No se pudo empujar $TARGET_BRANCH.\" as critical"

echo "---"

# Volver a main y empujarla al remoto para asegurar que esté actualizada
echo "Cambiando a la rama principal: $MAIN_BRANCH (para push final de main si es necesario)"
git checkout "$MAIN_BRANCH" || { osascript -e "display alert \"Error: No se pudo volver a la rama $MAIN_BRANCH para el push final.\" as critical"; exit 1; }
echo "Fusionando $TARGET_BRANCH en $MAIN_BRANCH (si hay cambios de dev a main)..."
git merge "$TARGET_BRANCH" || { osascript -e 'display alert "Conflictos al fusionar DEV en MAIN, resuélvelos manualmente en MAIN." as critical'; exit 1; }
if ! git diff --cached --exit-code; then
  echo "Comiteando cambios de la fusión de DEV en MAIN..."
  git commit -m "Merge branch '$TARGET_BRANCH' into '$MAIN_BRANCH'" || { osascript -e "display alert \"No se pudo hacer commit de la fusión de DEV en MAIN.\" as critical"; exit 1; }
fi
echo "Empujando $MAIN_BRANCH al remoto..."
git push origin "$MAIN_BRANCH" || osascript -e "display alert \"No se pudo empujar $MAIN_BRANCH al remoto.\" as critical"

osascript -e 'display dialog "Proceso completado exitosamente." with title "Éxito" buttons {"OK"} default button 1'

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$current_branch" != "$MAIN_BRANCH" ] && [ -n "$current_branch" ]; then
  SHOULD_RETURN=$(osascript -e "display dialog \"¿Volver a la rama original '$current_branch'?\" buttons {\"No\", \"Sí\"} default button \"Sí\" with icon caution" -e 'button returned of result')
  if [[ "$SHOULD_RETURN" == "Sí" ]]; then
    echo "Volviendo a la rama original: $current_branch"
    git checkout "$current_branch" || osascript -e "display alert \"No se pudo volver a la rama original.\" as warning"
  fi
fi

echo "---"

# 🔹 Crear script temporal para mostrar git status en nueva ventana de Terminal
PROJECT_PATH="$HOME/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
TEMP_GIT_STATUS_SCRIPT="$PROJECT_PATH/zsh/git_status_temp.sh"

cat > "$TEMP_GIT_STATUS_SCRIPT" <<EOF
#!/bin/zsh
cd "${PROJECT_PATH}" || exit 1
git status
exec zsh
EOF

chmod +x "$TEMP_GIT_STATUS_SCRIPT"

# 🔹 Abrir nueva ventana de Terminal y ejecutar el script temporal
osascript <<EOF
tell application "Terminal"
    activate
    do script "${TEMP_GIT_STATUS_SCRIPT}"
end tell
EOF

exit 0
