#!/bin/bash
set -x # Activa el modo de depuración: imprime cada comando que se ejecuta.

# Este script automatiza la fusión de una rama principal en otra rama,
# incluyendo commit y push.
# Recibe los siguientes argumentos:
# $1: main_branch (nombre de la rama principal)
# $2: target_branch (nombre de la rama a actualizar)

MAIN_BRANCH_PARAM="$1"
TARGET_BRANCH_PARAM="$2"

echo "--- Automatización de Fusión y Push en Git ---"

# --- Sección para manejar archivos no rastreados y cambios locales al inicio ---
echo ""
echo "Verificando estado del directorio de trabajo..."

# Guarda la rama actual antes de cualquier operación
current_branch_at_start=$(git rev-parse --abbrev-ref HEAD)
SHOULD_POP_STASH="false"

# 1. Añadir y commitear todos los cambios pendientes (sin seguimiento y modificados/staged)
if ! git diff-index --quiet HEAD -- || ! git diff-files --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Se encontraron cambios pendientes (archivos sin seguimiento, modificados o staged)."
    echo "Estado actual de Git:"
    git status --short

    echo "Añadiendo todos los cambios al área de preparación..."
    git add .
    if [ $? -ne 0 ]; then
        echo "Error: No se pudieron añadir los cambios. Abortando."
        exit 1
    fi

    # Usamos un mensaje de commit genérico para estos cambios automáticos
    local_commit_message="chore: Automated pre-merge commit (WIP)"
    echo "Realizando commit de los cambios locales con mensaje: '$local_commit_message'..."
    git commit -m "$local_commit_message"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo realizar el commit de los cambios locales. Abortando."
        exit 1
    fi
    echo "Cambios locales commiteados exitosamente."

    # Si la rama actual es la rama objetivo (la que vamos a actualizar), empujamos estos cambios.
    # Si no, no los empujamos aún, solo el commit local.
    if [ "$current_branch_at_start" == "$TARGET_BRANCH_PARAM" ]; then
        echo "Empujando el commit local a 'origin/$current_branch_at_start'..."
        git push origin "$current_branch_at_start"
        if [ $? -ne 0 ]; then
            echo "Advertencia: No se pudieron empujar los cambios iniciales. Puedes hacerlo manualmente después."
        fi
    else
        echo "Cambios locales commiteados. No empujados aún, ya que no estamos en la rama objetivo."
    fi

else
    echo "No se encontraron cambios pendientes. El árbol de trabajo está limpio."
fi
echo "---"

# --- Resto del script de fusión de ramas ---

# Usar los parámetros recibidos
main_branch="$MAIN_BRANCH_PARAM"
target_branch="$TARGET_BRANCH_PARAM"

# Validar que las ramas no estén vacías
if [ -z "$main_branch" ]; then
    echo "Error: El nombre de la rama principal no puede estar vacío. Abortando."
    exit 1
fi

if [ -z "$target_branch" ]; then
    echo "Error: El nombre de la rama a actualizar no puede estar vacío. Abortando."
    exit 1
fi

# Validar que las ramas no sean las mismas
if [ "$main_branch" == "$target_branch" ]; then
    echo "Error: Las ramas principal y objetivo no pueden ser la misma. Abortando."
    exit 1
fi

echo ""
echo "Iniciando proceso de Git..."
echo "--------------------------"

echo "Estás actualmente en la rama: $current_branch_at_start"

# 1. Cambiar a la rama principal y actualizarla
echo "Cambiando a la rama principal: $main_branch"
git checkout "$main_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $main_branch. Asegúrate de que existe."
    exit 1
fi

echo "Trayendo los últimos cambios de la rama principal..."
git pull origin "$main_branch"
if [ $? -ne 0 ]; then
    echo "Advertencia: No se pudieron traer los últimos cambios de la rama $main_branch. Puede que necesites resolver conflictos manualmente."
fi

# 2. Cambiar a la rama objetivo
echo "Cambiando a la rama objetivo: $target_branch"
git checkout "$target_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $target_branch. Asegúrate de que existe."
    exit 1
fi

# 3. Fusionar la rama principal en la rama objetivo
echo "Fusionando '$main_branch' en '$target_branch'..."
git merge "$main_branch"

# Verificar si hubo conflictos de fusión
if [ $? -ne 0 ]; then
    echo ""
    echo "¡ATENCIÓN: Se produjeron conflictos de fusión!"
    echo "Por favor, resuelve los conflictos manualmente en tu editor de código."
    echo "Después de resolverlos, guarda los cambios, añade los archivos con 'git add .'"
    echo "y luego ejecuta 'git commit' para completar la fusión."
    echo "Una vez resueltos y con commit, puedes volver a ejecutar este script si lo deseas,"
    echo "o simplemente haz 'git push' manualmente."
    exit 1
fi

# 4. Empujar los cambios a la rama remota
echo "Empujando los cambios a 'origin/$target_branch'..."
git push origin "$target_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo empujar los cambios a 'origin/$target_branch'."
    exit 1
fi

echo ""
echo "----------------------------------------------------"
echo "¡Proceso completado exitosamente!"

# 5. Volver a la rama original si el usuario no estaba en la rama objetivo
if [ "$current_branch_at_start" != "$target_branch" ]; then
    echo "Volviendo a tu rama original: $current_branch_at_start"
    git checkout "$current_branch_at_start"
fi

echo "Estado final de Git:"
git status # Muestra el estado para confirmar un directorio limpio.

echo "----------------------------------------------------"