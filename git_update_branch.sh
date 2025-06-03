#!/bin/bash
set -eo pipefail # Habilita el modo "exit on error" y "pipefail" para un manejo de errores robusto
# set -x # Descomentar para activar el modo de depuración: imprime cada comando que se ejecuta.

# Este script automatiza la fusión de una rama principal en otra rama,
# incluyendo commit y push. También asegura que la rama principal
# esté actualizada y sus cambios locales se suban antes de la fusión.
# Recibe los siguientes argumentos:
# $1: main_branch (nombre de la rama principal)
# $2: target_branch (nombre de la rama a actualizar)
# $3: untracked_commit_msg (mensaje para commit de archivos nuevos/sin seguimiento)
# $4: local_commit_msg (mensaje para commit de cambios locales)

MAIN_BRANCH_PARAM="$1"
TARGET_BRANCH_PARAM="$2"
UNTRACKED_COMMIT_MSG="${3:-"feat: (automated) Add untracked files"}" # Mensaje por defecto si no se proporciona
LOCAL_COMMIT_MSG="${4:-"feat: (automated) WIP changes before merge"}" # Mensaje por defecto si no se proporciona

echo "--- Automatización de Fusión y Push en Git ---"

# Guarda la rama actual al inicio del script para volver a ella después
current_branch_at_start=$(git rev-parse --abbrev-ref HEAD)

# Función para manejar errores y salir de forma limpia
handle_error() {
  local msg="$1"
  local branch_to_restore="$2"
  echo "❌ Error: $msg" >&2
  if [ -n "$branch_to_restore" ] && [ "$branch_to_restore" != "$(git rev-parse --abbrev-ref HEAD)" ]; then
    echo "Volviendo a la rama original: '$branch_to_restore'."
    git checkout "$branch_to_restore" || echo "Advertencia: No se pudo volver a la rama '$branch_to_restore'." >&2
  fi
  exit 1
}

# Función para commitear cambios pendientes, incluyendo untracked
commit_pending_changes() {
  local branch_name="$1"
  local commit_msg="$2"

  local untracked_files_exist=$(git ls-files --others --exclude-standard)
  local changes_exist=$(git diff-index --quiet HEAD -- || echo "changes") # Verifica cambios staged
  local unstaged_changes_exist=$(git diff-files --quiet || echo "unstaged_changes") # Verifica cambios unstaged

  if [ -n "$untracked_files_exist" ]; then
    echo "Se encontraron archivos sin seguimiento en la rama '$branch_name'. Añadiéndolos y commiteando..."
    git add . || handle_error "No se pudieron añadir archivos untracked en '$branch_name'." "$current_branch_at_start"
    git commit -m "$UNTRACKED_COMMIT_MSG" || handle_error "Fallo al commitear archivos sin seguimiento en '$branch_name'." "$current_branch_at_start"
    echo "Archivos sin seguimiento commiteados exitosamente en '$branch_name'."
  fi

  # Volver a verificar si quedan cambios después de manejar untracked
  if [ -n "$changes_exist" ] || [ -n "$unstaged_changes_exist" ]; then
    echo "Se encontraron cambios pendientes en la rama '$branch_name'."
    echo "Estado actual de Git en '$branch_name':"
    git status --short

    echo "Añadiendo todos los cambios al área de preparación en '$branch_name'..."
    git add . || handle_error "No se pudieron añadir los cambios en '$branch_name'." "$current_branch_at_start"

    echo "Realizando commit de los cambios locales en '$branch_name' con mensaje: '$commit_msg'..."
    git commit -m "$commit_msg" || handle_error "No se pudo realizar el commit de los cambios en '$branch_name'." "$current_branch_at_start"
    echo "Cambios locales commiteados exitosamente en '$branch_name'."
  else
    echo "No se encontraron cambios pendientes en la rama '$branch_name'. El árbol de trabajo está limpio."
  fi
}

# --- Verificación y Solicitud Interactiva de Argumentos si no se proporcionan ---
if [ -z "$MAIN_BRANCH_PARAM" ] || [ -z "$TARGET_BRANCH_PARAM" ]; then
  echo "Los nombres de las ramas no fueron proporcionados como argumentos."
  echo "Por favor, ingresa los nombres de las ramas interactivamente."

  read -p "Ingresa el nombre de la rama principal (ej: main): " MAIN_BRANCH_PARAM
  read -p "Ingresa el nombre de la rama a actualizar (ej: develop): " TARGET_BRANCH_PARAM

  if [ -z "$MAIN_BRANCH_PARAM" ] || [ -z "$TARGET_BRANCH_PARAM" ]; then
    handle_error "Nombres de ramas no proporcionados. Abortando." "$current_branch_at_start"
  fi
fi

# --- Paso 1: Asegurar que la rama principal esté actualizada y limpia ---
echo ""
echo "Preparando la rama principal: $MAIN_BRANCH_PARAM..."

# Cambiar a la rama principal
echo "Cambiando a la rama principal: $MAIN_BRANCH_PARAM"
git checkout "$MAIN_BRANCH_PARAM" || handle_error "No se pudo cambiar a la rama '$MAIN_BRANCH_PARAM'. Asegúrate de que existe." "$current_branch_at_start"

# Commitear cualquier cambio pendiente en la rama principal
commit_pending_changes "$MAIN_BRANCH_PARAM" "$LOCAL_COMMIT_MSG"

# Traer y subir los últimos cambios de la rama principal
echo "Trayendo los últimos cambios de 'origin/$MAIN_BRANCH_PARAM' y subiendo los propios..."
# Usar '|| true' para que el script no falle inmediatamente si pull tiene advertencias (ej. no fast-forward)
git pull origin "$MAIN_BRANCH_PARAM" || echo "Advertencia: 'git pull' en '$MAIN_BRANCH_PARAM' tuvo advertencias o conflictos. Continúa, pero revisa manualmente."

echo "Asegurando que todos los cambios locales en '$MAIN_BRANCH_PARAM' estén empujados..."
git push origin "$MAIN_BRANCH_PARAM" || handle_error "No se pudieron empujar los cambios de '$MAIN_BRANCH_PARAM' a su remoto." "$current_branch_at_start"
echo "La rama '$MAIN_BRANCH_PARAM' está ahora actualizada y sincronizada con el remoto."
echo "---"

# --- Paso 2: Actualizar la rama objetivo desde la principal ---
echo ""
echo "Preparando la rama objetivo: $TARGET_BRANCH_PARAM para actualizar desde $MAIN_BRANCH_PARAM..."

# Cambiar a la rama objetivo
echo "Cambiando a la rama objetivo: $TARGET_BRANCH_PARAM"
git checkout "$TARGET_BRANCH_PARAM" || handle_error "No se pudo cambiar a la rama '$TARGET_BRANCH_PARAM'. Asegúrate de que existe." "$current_branch_at_start"

# Commitear cualquier cambio pendiente en la rama objetivo
commit_pending_changes "$TARGET_BRANCH_PARAM" "$LOCAL_COMMIT_MSG"

# Traer los últimos cambios de la rama objetivo (por si acaso alguien más subió algo)
echo "Trayendo los últimos cambios de 'origin/$TARGET_BRANCH_PARAM'..."
git pull origin "$TARGET_BRANCH_PARAM" || echo "Advertencia: 'git pull' en '$TARGET_BRANCH_PARAM' tuvo advertencias o conflictos. Continúa, pero revisa manualmente."

# Fusionar la rama principal en la rama objetivo
echo "Fusionando '$MAIN_BRANCH_PARAM' en '$TARGET_BRANCH_PARAM'..."
if ! git merge "$MAIN_BRANCH_PARAM"; then
  echo ""
  echo "¡ATENCIÓN: Se produjeron conflictos de fusión!"
  echo "Por favor, resuelve los conflictos manualmente en tu editor de código."
  echo "Después de resolverlos, guarda los cambios, añade los archivos con 'git add .',"
  echo "y luego ejecuta 'git commit' para completar la fusión."
  echo "Una vez resueltos y commiteados, puedes ejecutar 'git push origin $TARGET_BRANCH_PARAM' manualmente."
  handle_error "Conflictos de fusión detectados." "$current_branch_at_start"
fi

# Empujar los cambios de la rama objetivo a su remoto
echo "Empujando los cambios de '$TARGET_BRANCH_PARAM' a 'origin/$TARGET_BRANCH_PARAM'..."
git push origin "$TARGET_BRANCH_PARAM" || handle_error "No se pudo empujar los cambios a 'origin/$TARGET_BRANCH_PARAM'." "$current_branch_at_start"

echo ""
echo "----------------------------------------------------"
echo "¡Proceso de actualización de ramas completado exitosamente!"

# --- Paso 3: Volver a la rama original y verificar estado final ---
echo "Volviendo a tu rama original: $current_branch_at_start"
git checkout "$current_branch_at_start" || echo "Advertencia: No se pudo volver a la rama '$current_branch_at_start'. Estás en '$(git rev-parse --abbrev-ref HEAD)'." >&2

echo "Estado final de Git en la rama '$current_branch_at_start':"
git status # Muestra el estado para confirmar un directorio limpio.

echo "----------------------------------------------------"