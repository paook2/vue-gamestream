#!/bin/bash
set -x

# --- Entrada de parámetros con fallback interactivo ---
MAIN_BRANCH_PARAM="${1:-}"
TARGET_BRANCH_PARAM="${2:-}"

if [ -z "$MAIN_BRANCH_PARAM" ]; then
  read -p "Ingresa el nombre de la rama principal...: " MAIN_BRANCH_PARAM
fi

if [ -z "$TARGET_BRANCH_PARAM" ]; then
  read -p "Ingresa el nombre de la rama secundaria a actualizar: " TARGET_BRANCH_PARAM
fi

echo "--- Automatización de Fusión y Push en Git ---"

current_branch_at_start=$(git rev-parse --abbrev-ref HEAD)

echo ""
echo "Preparando la rama principal: $MAIN_BRANCH_PARAM..."
git checkout "$MAIN_BRANCH_PARAM" || { echo "Error al cambiar a $MAIN_BRANCH_PARAM"; exit 1; }

if ! git diff-index --quiet HEAD -- || ! git diff-files --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Cambios pendientes en $MAIN_BRANCH_PARAM..."
  git status --short
  git add . || { echo "Error en git add"; exit 1; }
  git commit -m "chore: Automated pre-merge commit on $MAIN_BRANCH_PARAM" || { echo "Error en git commit"; exit 1; }
else
  echo "No hay cambios pendientes en $MAIN_BRANCH_PARAM"
fi

git pull origin "$MAIN_BRANCH_PARAM" || echo "Advertencia: git pull falló en $MAIN_BRANCH_PARAM"
git push origin "$MAIN_BRANCH_PARAM" || { echo "Error en git push $MAIN_BRANCH_PARAM"; exit 1; }

echo ""
echo "Preparando la rama objetivo: $TARGET_BRANCH_PARAM..."
git checkout "$TARGET_BRANCH_PARAM" || {
  echo "Error al cambiar a $TARGET_BRANCH_PARAM"
  [ "$current_branch_at_start" != "$MAIN_BRANCH_PARAM" ] && git checkout "$current_branch_at_start"
  exit 1
}

if ! git diff-index --quiet HEAD -- || ! git diff-files --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Cambios pendientes en $TARGET_BRANCH_PARAM..."
  git status --short
  git add . || { echo "Error en git add"; exit 1; }
  git commit -m "chore: Automated pre-merge commit on $TARGET_BRANCH_PARAM" || { echo "Error en git commit"; exit 1; }
else
  echo "No hay cambios pendientes en $TARGET_BRANCH_PARAM"
fi

git pull origin "$TARGET_BRANCH_PARAM" || echo "Advertencia: git pull falló en $TARGET_BRANCH_PARAM"

echo "Fusionando '$MAIN_BRANCH_PARAM' en '$TARGET_BRANCH_PARAM'..."
git merge "$MAIN_BRANCH_PARAM"
if [ $? -ne 0 ]; then
  echo ""
  echo "Conflictos de fusión detectados."
  echo "Resuélvelos manualmente y luego ejecuta 'git add .', 'git commit', y 'git push origin $TARGET_BRANCH_PARAM'"
  exit 1
fi

if git diff --cached --exit-code; then
  echo "No hay cambios pendientes de commit después del merge."
else
  git commit -m "Merge branch '$MAIN_BRANCH_PARAM' into '$TARGET_BRANCH_PARAM'" || { echo "Error en commit de fusión"; exit 1; }
fi

git push origin "$TARGET_BRANCH_PARAM" || { echo "Error al hacer push en $TARGET_BRANCH_PARAM"; exit 1; }

echo ""
echo "----------------------------------------------------"
echo "¡Proceso de actualización completado exitosamente!"
git checkout "$current_branch_at_start" || echo "Advertencia: No se pudo volver a '$current_branch_at_start'"
git status
echo "----------------------------------------------------"
