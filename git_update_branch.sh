#!/bin/bash
set -x # Activa el modo de depuración: imprime cada comando que se ejecuta.

# Este script automatiza la fusión de una rama principal en otra rama,
# incluyendo commit y push. También asegura que la rama principal
# esté actualizada y sus cambios locales se suban antes de la fusión.
# Recibe los siguientes argumentos:
# $1: main_branch (nombre de la rama principal)
# $2: target_branch (nombre de la rama a actualizar)

MAIN_BRANCH_PARAM="$1"
TARGET_BRANCH_PARAM="$2"

echo "--- Automatización de Fusión y Push en Git ---"

# Guarda la rama actual al inicio del script para volver a ella después
current_branch_at_start=$(git rev-parse --abbrev-ref HEAD)

# --- Paso 1: Asegurar que la rama principal esté actualizada y limpia ---
echo ""
echo "Preparando la rama principal: $MAIN_BRANCH_PARAM..."

# Cambiar a la rama principal
echo "Cambiando a la rama principal: $MAIN_BRANCH_PARAM"
git checkout "$MAIN_BRANCH_PARAM"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $MAIN_BRANCH_PARAM. Asegúrate de que existe."
    exit 1
fi

# Añadir y commitear todos los cambios pendientes en la rama principal
if ! git diff-index --quiet HEAD -- || ! git diff-files --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Se encontraron cambios pendientes en la rama principal."
    echo "Estado actual de Git en $MAIN_BRANCH_PARAM:"
    git status --short

    echo "Añadiendo todos los cambios al área de preparación en $MAIN_BRANCH_PARAM..."
    git add .
    if [ $? -ne 0 ]; then
        echo "Error: No se pudieron añadir los cambios en $MAIN_BRANCH_PARAM. Abortando."
        exit 1
    fi

    # Usamos un mensaje de commit genérico para estos cambios automáticos
    main_commit_message="chore: Automated pre-merge commit on $MAIN_BRANCH_PARAM"
    echo "Realizando commit de los cambios locales en $MAIN_BRANCH_PARAM con mensaje: '$main_commit_message'..."
    git commit -m "$main_commit_message"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo realizar el commit de los cambios en $MAIN_BRANCH_PARAM. Abortando."
        exit 1
    fi
    echo "Cambios locales commiteados exitosamente en $MAIN_BRANCH_PARAM."
else
    echo "No se encontraron cambios pendientes en la rama principal. El árbol de trabajo está limpio."
fi

# Traer y subir los últimos cambios de la rama principal
echo "Trayendo los últimos cambios de 'origin/$MAIN_BRANCH_PARAM' y subiendo los propios..."
git pull origin "$MAIN_BRANCH_PARAM"
if [ $? -ne 0 ]; then
    echo "Advertencia: No se pudieron traer los últimos cambios de 'origin/$MAIN_BRANCH_PARAM'. Puede que necesites resolver conflictos manualmente."
    # A pesar de la advertencia, intentamos seguir para que el usuario pueda resolverlo post-ejecución.
fi

# Asegurarse de que todos los cambios locales en main estén empujados
git push origin "$MAIN_BRANCH_PARAM"
if [ $? -ne 0 ]; then
    echo "Error: No se pudieron empujar los cambios de $MAIN_BRANCH_PARAM a su remoto. Abortando."
    exit 1
fi
echo "La rama '$MAIN_BRANCH_PARAM' está ahora actualizada y sincronizada con el remoto."
echo "---"

# --- Paso 2: Actualizar la rama objetivo desde la principal ---
echo ""
echo "Preparando la rama objetivo: $TARGET_BRANCH_PARAM para actualizar desde $MAIN_BRANCH_PARAM..."

# Cambiar a la rama objetivo
echo "Cambiando a la rama objetivo: $TARGET_BRANCH_PARAM"
git checkout "$TARGET_BRANCH_PARAM"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $TARGET_BRANCH_PARAM. Asegúrate de que existe."
    # Si la rama objetivo no existe y se estaba en otra rama al inicio, intentar volver a la original.
    if [ "$current_branch_at_start" != "$MAIN_BRANCH_PARAM" ]; then
        git checkout "$current_branch_at_start"
    fi
    exit 1
fi

# Añadir y commitear todos los cambios pendientes en la rama objetivo antes de la fusión
if ! git diff-index --quiet HEAD -- || ! git diff-files --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Se encontraron cambios pendientes en la rama objetivo."
    echo "Estado actual de Git en $TARGET_BRANCH_PARAM:"
    git status --short

    echo "Añadiendo todos los cambios al área de preparación en $TARGET_BRANCH_PARAM..."
    git add .
    if [ $? -ne 0 ]; then
        echo "Error: No se pudieron añadir los cambios en $TARGET_BRANCH_PARAM. Abortando."
        exit 1
    fi

    target_commit_message="chore: Automated pre-merge commit on $TARGET_BRANCH_PARAM"
    echo "Realizando commit de los cambios locales en $TARGET_BRANCH_PARAM con mensaje: '$target_commit_message'..."
    git commit -m "$target_commit_message"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo realizar el commit de los cambios en $TARGET_BRANCH_PARAM. Abortando."
        exit 1
    fi
    echo "Cambios locales commiteados exitosamente en $TARGET_BRANCH_PARAM."
else
    echo "No se encontraron cambios pendientes en la rama objetivo. El árbol de trabajo está limpio."
fi

# Traer los últimos cambios de la rama objetivo (por si acaso alguien más subió algo)
echo "Trayendo los últimos cambios de 'origin/$TARGET_BRANCH_PARAM'..."
git pull origin "$TARGET_BRANCH_PARAM"
if [ $? -ne 0 ]; then
    echo "Advertencia: No se pudieron traer los últimos cambios de 'origin/$TARGET_BRANCH_PARAM'. Puede que necesites resolver conflictos manualmente."
fi


# Fusionar la rama principal en la rama objetivo
echo "Fusionando '$MAIN_BRANCH_PARAM' en '$TARGET_BRANCH_PARAM'..."
git merge "$MAIN_BRANCH_PARAM"

# Verificar si hubo conflictos de fusión
if [ $? -ne 0 ]; then
    echo ""
    echo "¡ATENCIÓN: Se produjeron conflictos de fusión!"
    echo "Por favor, resuelve los conflictos manualmente en tu editor de código."
    echo "Después de resolverlos, guarda los cambios, añade los archivos con 'git add .',"
    echo "y luego ejecuta 'git commit' para completar la fusión."
    echo "Una vez resueltos y commiteados, puedes ejecutar 'git push origin $TARGET_BRANCH_PARAM' manualmente."
    exit 1
fi

# Realizar el commit si la fusión generó uno (ej. no fue fast-forward)
# O si ya se resolvió un conflicto previamente y queda pendiente de commit.
if git diff --cached --exit-code; then
    echo "No hay cambios pendientes de commit después de la fusión. Continuar..."
else
    echo "Realizando commit de la fusión..."
    git commit -m "Merge branch '$MAIN_BRANCH_PARAM' into '$TARGET_BRANCH_PARAM'"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo realizar el commit de la fusión. Abortando."
        exit 1
    fi
fi


# Empujar los cambios de la rama objetivo a su remoto
echo "Empujando los cambios de '$TARGET_BRANCH_PARAM' a 'origin/$TARGET_BRANCH_PARAM'..."
git push origin "$TARGET_BRANCH_PARAM"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo empujar los cambios a 'origin/$TARGET_BRANCH_PARAM'. Abortando."
    exit 1
fi

echo ""
echo "----------------------------------------------------"
echo "¡Proceso de actualización de ramas completado exitosamente!"

# --- Paso 3: Volver a la rama original y verificar estado final ---
echo "Volviendo a tu rama original: $current_branch_at_start"
git checkout "$current_branch_at_start"
if [ $? -ne 0 ]; then
    echo "Advertencia: No se pudo volver a la rama '$current_branch_at_start'. Estás en '$TARGET_BRANCH_PARAM'."
fi

echo "Estado final de Git en la rama '$current_branch_at_start':"
git status # Muestra el estado para confirmar un directorio limpio.

echo "----------------------------------------------------"