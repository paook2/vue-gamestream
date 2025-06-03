#!/bin/zsh

# Este script automatiza el proceso de fusionar una rama principal en otra rama,
# hacer commit y push, dejando la rama limpia sin cambios pendientes.

osascript -e 'display dialog "Bienvenido a GIT" with title "Mensaje de git.sh" buttons {"OK"} default button 1'

echo "--- Automatización de Fusión y Push en Git ---"

---

## Limpieza de Archivos Trackeados que Deberían ser Ignorados

SHOULD_CLEAN_TRACKED=$(osascript -e 'display dialog "¿Quieres limpiar el repositorio de archivos como node_modules o .prettierrc.json que deberían estar ignorados?" buttons {"No", "Sí"} default button "No" with icon caution' -e 'button returned of result')

if [[ "$SHOULD_CLEAN_TRACKED" == "Sí" ]]; then
  echo "Iniciando proceso de limpieza de archivos trackeados ignorados..."

  declare -a FILES_TO_UNTRACK=(
    "node_modules/"
    ".prettierrc.json"
    "dist/"
    "build/"
    "*.log"
  )

  for item in "${FILES_TO_UNTRACK[@]}"; do
    if git ls-files --error-unmatch "$item" &>/dev/null; then
      echo "Des-trackeando '$item'..."
      git rm -r --cached "$item" || echo "Advertencia: No se pudo des-trackear '$item'. Puede que no estuviera trackeado o hubo un error."
    else
      echo "'$item' no está trackeado o ya ha sido des-trackeado. Saltando."
    fi
  done

  if ! git diff --cached --exit-code; then
    echo "Realizando commit de la limpieza de archivos ignorados..."
    git commit -m "chore: Stop tracking ignored files/folders" || { osascript -e "display alert \"Error: No se pudo realizar el commit de la limpieza.\" as critical"; exit 1; }
    echo "Archivos des-trackeados y commiteados exitosamente."
    
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ "$current_branch" != "HEAD" ] && [ -n "$current_branch" ]; then
      SHOULD_PUSH_CLEANUP=$(osascript -e "display dialog \"¿Deseas empujar estos cambios de limpieza a 'origin/$current_branch'?\" buttons {\"No\", \"Sí\"} default button \"Sí\" with icon caution" -e 'button returned of result')
      if [[ "$SHOULD_PUSH_CLEANUP" == "Sí" ]]; then
        echo "Empujando cambios de limpieza..."
        git push origin "$current_branch" || echo "Advertencia: No se pudieron empujar los cambios de limpieza. Puedes hacerlo manualmente."
      fi
    fi
  else
    echo "No se encontraron archivos trackeados que necesiten limpieza."
  fi
else
  echo "⏩ Saltando la limpieza de archivos trackeados ignorados."
fi

echo "---"

---

## Manejo de Archivos sin Seguimiento al Inicio

echo ""
echo "Verificando archivos sin seguimiento (untracked files)..."

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

    current_branch_before_ops=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ "$current_branch_before_ops" != "HEAD" ] && [ -n "$current_branch_before_ops" ]; then
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
echo "----------------------------------------------------"
osascript -e 'display dialog "¡Proceso completado exitosamente! Ahora, al ejecutar \'git status\', debería decir que no hay cambios por hacer." with title "Éxito" buttons {"OK"} default button 1'
git status

if [ "$current_branch" != "$TARGET_BRANCH" ] && [ -n "$current_branch" ]; then
  SHOULD_RETURN_TO_ORIGINAL=$(osascript -e "display dialog \"¿Deseas volver a tu rama original: '$current_branch'?\" buttons {\"No\", \"Sí\"} default button \"Sí\" with icon caution" -e 'button returned of result')
  if [[ "$SHOULD_RETURN_TO_ORIGINAL" == "Sí" ]]; then
    echo "Volviendo a tu rama original: $current_branch"
    git checkout "$current_branch" || osascript -e "display alert \"Advertencia: No se pudo volver a la rama original '$current_branch'.\" as warning"
  fi
fi

echo "----------------------------------------------------"