#!/bin/zsh

# Este script automatiza el proceso de fusionar una rama principal en otra rama,
# hacer commit y push, dejando la rama limpia sin cambios pendientes.

osascript -e 'display dialog "Bienvenido a GIT" with title "Mensaje de git.sh" buttons {"OK"} default button 1'

echo "--- Automatización de Fusión y Push en Git ---"

---

## Manejo de Archivos sin Seguimiento al Inicio

echo ""
echo "Verificando archivos sin seguimiento (untracked files)..."

# Obtener archivos sin seguimiento de forma más robusta
untracked_files=$(git status --porcelain | grep "^??" | awk '{print $2}')

if [ -n "$untracked_files" ]; then
  echo "Se encontraron los siguientes archivos sin seguimiento:"
  echo "$untracked_files"

  SHOULD_ADD_UNTRACKED=$(osascript -e 'display dialog "¿Deseas añadir y commitear estos archivos ahora?" buttons {"No", "Sí"} default button "Sí" with icon caution' -e 'button returned of result')

  if [[ "$SHOULD_ADD_UNTRACKED" == "Sí" ]]; then
    echo "Añadiendo archivos sin seguimiento..."
    git add . || { echo "Error: No se pudieron añadir los archivos. Abortando." >&2; exit 1; }

    UNTRACKED_COMMIT_MSG=$(osascript -e 'try' -e '  set T to text returned of (display dialog "Ingresa un mensaje para el commit de estos archivos:" default answer "feat: Add new untracked files")' -e '  return T' -e 'on error number -128' -e '  return ""' -e 'end try')

    if [ -z "$UNTRACKED_COMMIT_MSG" ]; then
      UNTRACKED_COMMIT_MSG="feat: Add new untracked files (automated)"
    fi

    echo "Realizando commit de los archivos sin seguimiento..."
    git commit -m "$UNTRACKED_COMMIT_MSG" || { echo "Error: No se pudo realizar el commit de los archivos. Abortando." >&2; exit 1; }
    echo "Archivos sin seguimiento commiteados exitosamente."

    # Empujar estos cambios iniciales si estás en una rama existente
    current_branch_before_ops=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ "$current_branch_before_ops" != "HEAD" ] && [ -n "$current_branch_before_ops" ]; then # No es HEAD si estás en una rama
      SHOULD_PUSH_INITIAL=$(osascript -e "display dialog \"¿Deseas empujar estos cambios iniciales a 'origin/$current_branch_before_ops'?\" buttons {\"No\", \"Sí\"} default button \"Sí\" with icon caution" -e 'button returned of result')
      if [[ "$SHOULD_PUSH_INITIAL" == "Sí" ]]; then
        echo "Empujando cambios iniciales..."
        git push origin "$current_branch_before_ops" || echo "Advertencia: No se pudieron empujar los cambios iniciales. Puedes hacerlo manualmente después."
      fi
    fi
  else
    echo "Archivos sin seguimiento ignorados por ahora. El script continuará."
  fi
else
  echo "No se encontraron archivos sin seguimiento."
fi
echo "---"

---

## Proceso de Fusión de Ramas

# 1. Preguntar por el nombre de la rama principal
MAIN_BRANCH=$(osascript -e 'try' -e '  set T to text returned of (display dialog "Ingresa el nombre de tu rama principal (ej: main, master):" default answer "main")' -e '  return T' -e 'on error number -128' -e '  return ""' -e 'end try')

# Validar que la rama principal no esté vacía
if [ -z "$MAIN_BRANCH" ]; then
  osascript -e 'display alert "Error: El nombre de la rama principal no puede estar vacío." as warning'
  exit 1
fi

# 2. Preguntar por el nombre de la segunda rama a actualizar
TARGET_BRANCH=$(osascript -e 'try' -e '  set T to text returned of (display dialog "Ingresa el nombre de la rama que quieres actualizar desde la principal:" default answer "dev")' -e '  return T' -e 'on error number -128' -e '  return ""' -e 'end try')

# Validar que la rama objetivo no esté vacía
if [ -z "$TARGET_BRANCH" ]; then
  osascript -e 'display alert "Error: El nombre de la rama a actualizar no puede estar vacío." as warning'
  exit 1
fi

# Validar que las ramas no sean las mismas
if [ "$MAIN_BRANCH" == "$TARGET_BRANCH" ]; then
  osascript -e 'display alert "Error: Las ramas principal y objetivo no pueden ser la misma." as warning'
  exit 1
fi

echo ""
echo "Iniciando proceso de Git..."
echo "--------------------------"

# 3. Guardar la rama actual en caso de que necesitemos volver
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
echo "Estás actualmente en la rama: $current_branch"

# 4. Cambiar a la rama principal para asegurarnos de que esté actualizada
echo "Cambiando a la rama principal: $MAIN_BRANCH"
git checkout "$MAIN_BRANCH" || { osascript -e "display alert \"Error: No se pudo cambiar a la rama $MAIN_BRANCH. Asegúrate de que existe.\" as critical"; exit 1; }

echo "Trayendo los últimos cambios de la rama principal..."
git pull origin "$MAIN_BRANCH" || osascript -e "display alert \"Advertencia: No se pudieron traer los últimos cambios de la rama $MAIN_BRANCH. Puede que necesites resolver conflictos manualmente si hay.\" as warning"

# 5. Cambiar a la rama objetivo para actualizarla
echo "Cambiando a la rama objetivo: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH" || { osascript -e "display alert \"Error: No se pudo cambiar a la rama $TARGET_BRANCH. Asegúrate de que existe.\" as critical"; exit 1; }

# 6. Fusionar la rama principal en la rama objetivo
echo "Fusionando '$MAIN_BRANCH' en '$TARGET_BRANCH'..."
git merge "$MAIN_BRANCH"

# Verificar si hubo conflictos de fusión
if [ $? -ne 0 ]; then
  echo ""
  osascript -e 'display alert "¡ATENCIÓN: Se produjeron conflictos de fusión! Por favor, resuelve los conflictos manualmente en tu editor de código. Después de resolverlos, guarda los cambios, añade los archivos con \'git add .\' y luego ejecuta \'git commit\' para completar la fusión. Una vez resueltos y con commit, puedes volver a ejecutar este script si lo deseas, o simplemente haz \'git push\' manualmente." as critical'
  exit 1
fi

# 7. Realizar el commit si hay cambios (en caso de que la fusión haya sido "fast-forward" o resuelta automáticamente)
# Primero, verificamos si hay cambios pendientes de commit después del merge
if git diff --cached --exit-code; then
  echo "No hay cambios pendientes de commit después de la fusión. Continuar..."
else
  echo "Realizando commit de la fusión..."
  git commit -m "Merge branch '$MAIN_BRANCH' into '$TARGET_BRANCH'" || { osascript -e "display alert \"Error: No se pudo realizar el commit de la fusión.\" as critical"; exit 1; }
fi

# 8. Empujar los cambios a la rama remota
echo "Empujando los cambios a 'origin/$TARGET_BRANCH'..."
git push origin "$TARGET_BRANCH" || { osascript -e "display alert \"Error: No se pudo empujar los cambios a 'origin/$TARGET_BRANCH'.\" as critical"; exit 1; }

echo ""
echo "----------------------------------------------------"
osascript -e 'display dialog "¡Proceso completado exitosamente! Ahora, al ejecutar \'git status\', debería decir que no hay cambios por hacer." with title "Éxito" buttons {"OK"} default button 1'
git status

# Opcional: Volver a la rama original si el usuario no estaba en la rama objetivo
if [ "$current_branch" != "$TARGET_BRANCH" ] && [ -n "$current_branch" ]; then
  SHOULD_RETURN_TO_ORIGINAL=$(osascript -e "display dialog \"¿Deseas volver a tu rama original: '$current_branch'?\" buttons {\"No\", \"Sí\"} default button \"Sí\" with icon caution" -e 'button returned of result')
  if [[ "$SHOULD_RETURN_TO_ORIGINAL" == "Sí" ]]; then
    echo "Volviendo a tu rama original: $current_branch"
    git checkout "$current_branch" || osascript -e "display alert \"Advertencia: No se pudo volver a la rama original '$current_branch'.\" as warning"
  fi
fi

echo "----------------------------------------------------"