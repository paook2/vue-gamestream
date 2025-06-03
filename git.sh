#!/bin/zsh

osascript -e 'display dialog "Bienvenido a GIT" with title "Mensaje de git.sh" buttons {"OK"} default button 1'

echo "--- Automatización de Fusión y Push en Git ---"

# Limpieza automática de archivos trackeados que deberían estar ignorados según .gitignore
echo "Detectando archivos trackeados que deberían estar ignorados según .gitignore..."

ignored_tracked_files=$(git ls-files -i --exclude-standard)

if [[ -n "$ignored_tracked_files" ]]; then
  echo "Archivos a des-trackear:"
  echo "$ignored_tracked_files"

  git rm -r --cached $ignored_tracked_files || { osascript -e "display alert \"Error al des-trackear archivos ignorados.\" as critical"; exit 1; }

  echo "Realizando commit de la limpieza automática..."
  git commit -m "chore: Stop tracking files ignored by .gitignore" || { osascript -e "display alert \"No se pudo hacer commit de la limpieza automática.\" as critical"; exit 1; }

  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ "$current_branch" != "HEAD" && -n "$current_branch" ]]; then
    echo "Empujando cambios de limpieza a origin/$current_branch..."
    git push origin "$current_branch" || echo "Advertencia: No se pudo empujar cambios. Hazlo manualmente."
  fi
else
  echo "No se encontraron archivos trackeados que deban ser ignorados según .gitignore."
fi

echo "---"

# Manejo de archivos sin seguimiento y cambios locales (igual que antes)
echo ""
echo "Verificando estado del repositorio para cambios pendientes..."

untracked_files=$(git status --porcelain | grep "^??" | awk '{print $2}')
staged_changes=$(git diff --cached --name-only)
unstaged_changes=$(git diff --name-only)

if [ -n "$untracked_files" ] || [ -n "$staged_changes" ] || [ -n "$unstaged_changes" ]; then
  echo "Se detectaron cambios pendientes (archivos sin seguimiento o modificaciones locales)."
  echo "Añadiendo todos los archivos y cambios modificados al área de preparación..."
  git add . || { echo "Error: No se pudieron añadir los cambios. Abortando." >&2; exit 1; }

  COMMIT_MSG=$(osascript -e 'try' -e '  set T to text returned of (display dialog "Se han detectado cambios pendientes. Ingresa un mensaje para el commit:" default answer "feat: (automated) WIP changes detected")' -e '  return T' -e 'on error number -128' -e '  return ""' -e 'end try')

  if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="feat: (automated) Committing detected changes"
  fi

  echo "Realizando commit de los cambios pendientes..."
  git commit -m "$COMMIT_MSG" || { echo "Error: No se pudo realizar el commit de los cambios pendientes. Abortando." >&2; exit 1; }
  echo "Cambios pendientes commiteados exitosamente."

  current_branch_after_ops=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$current_branch_after_ops" != "HEAD" ] && [ -n "$current_branch_after_ops" ]; then
    echo "Empujando cambios pendientes a 'origin/$current_branch_after_ops'..."
    git push origin "$current_branch_after_ops" || echo "Advertencia: No se pudieron empujar los cambios pendientes. Puedes hacerlo manualmente después."
  fi
else
  echo "No se encontraron cambios pendientes (archivos sin seguimiento, cambios staged o unstaged)."
fi

echo "---"

# Proceso de fusión de ramas
MAIN_BRANCH=$(osascript -e 'try' -e '  set T to text returned of (display dialog "Ingresa el nombre de tu rama principal (ej: main, master):" default answer "main")' -e '  return T' -e 'on error number -128' -e '  return ""' -e 'end try')

if [ -z "$MAIN_BRANCH" ]; then
  osascript -e 'display alert "Error: El nombre de la rama principal no puede estar vacío." as warning'
  exit 1
fi

TARGET_BRANCH=$(osascript -e 'try' -e '  set T to text returned of (display dialog "Ingresa el nombre de la rama que quieres actualizar desde la principal:" default answer "dev")' -e '  return T' -e 'on error number -128' -e '  return ""' -e 'end try')

if [ -z "$TARGET_BRANCH" ]; then
  osascript -e 'display alert "Error: El nombre de la rama a actualizar no puede estar vacío." as warning'
  exit 1
fi

if [ "$MAIN_BRANCH" == "$TARGET_BRANCH" ]; then
  osascript -e 'display alert "Error: Las ramas principal y objetivo no pueden ser la misma." as warning'
  exit 1
fi

echo ""
echo "Iniciando proceso de Git..."
echo "--------------------------"

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
echo "Estás actualmente en la rama: $current_branch"

echo "Cambiando a la rama principal: $MAIN_BRANCH"
git checkout "$MAIN_BRANCH" || { osascript -e "display alert \"Error: No se pudo cambiar a la rama $MAIN_BRANCH. Asegúrate de que existe.\" as critical"; exit 1; }

echo "Trayendo los últimos cambios de la rama principal..."
git pull origin "$MAIN_BRANCH" || osascript -e "display alert \"Advertencia: No se pudieron traer los últimos cambios de la rama $MAIN_BRANCH. Puede que necesites resolver conflictos manualmente si hay.\" as warning"

echo "Cambiando a la rama objetivo: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH" || { osascript -e "display alert \"Error: No se pudo cambiar a la rama $TARGET_BRANCH. Asegúrate de que existe.\" as critical"; exit 1; }

echo "Fusionando '$MAIN_BRANCH' en '$TARGET_BRANCH'..."
git merge "$MAIN_BRANCH"

if [ $? -ne 0 ]; then
  echo ""
  osascript -e 'display alert "¡ATENCIÓN: Se produjeron conflictos de fusión! Por favor, resuelve los conflictos manualmente en tu editor de código. Después de resolverlos, guarda los cambios, añade los archivos con \'git add .\' y luego ejecuta \'git commit\' para completar la fusión. Una vez resueltos y con commit, puedes volver a ejecutar este script si lo deseas, o simplemente haz \'git push\' manualmente." as critical'
  exit 1
fi

if git diff --cached --exit-code; then
  echo "No hay cambios pendientes de commit después de la fusión. Continuar..."
else
  echo "Realizando commit de la fusión..."
  git commit -m "Merge branch '$MAIN_BRANCH' into '$TARGET_BRANCH'" || { osascript -e "display alert \"Error: No se pudo realizar el commit de la fusión.\" as critical"; exit 1; }
fi

echo "Empujando los cambios a 'origin/$TARGET_BRANCH'..."
git push origin "$TARGET_BRANCH" || { osascript -e "display alert \"Error: No se pudo empujar los cambios a 'origin/$TARGET_BRANCH'.\" as critical"; exit 1; }

echo ""
echo "---"
osascript -e 'display dialog "¡Proceso completado exitosamente! Ahora, al ejecutar \'git status\', debería decir que no hay cambios por hacer." with title "Éxito" buttons {"OK"} default button 1'
git status

if [ "$current_branch" != "$TARGET_BRANCH" ] && [ -n "$current_branch" ]; then
  SHOULD_RETURN_TO_ORIGINAL=$(osascript -e "display dialog \"¿Deseas volver a tu rama original: '$current_branch'?\" buttons {\"No\", \"Sí\"} default button \"Sí\" with icon caution" -e 'button returned of result')
  if [[ "$SHOULD_RETURN_TO_ORIGINAL" == "Sí" ]]; then
    echo "Volviendo a tu rama original: $current_branch"
    git checkout "$current_branch" || osascript -e "display alert \"Advertencia: No se pudo volver a la rama original '$current_branch'.\" as warning"
  fi
fi

echo "---"
