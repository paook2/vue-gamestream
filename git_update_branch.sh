#!/bin/bash
set -x # Activa el modo de depuración: imprime cada comando que se ejecuta.

# Este script automatiza el proceso de fusionar una rama principal en otra rama,
# hacer commit y push, dejando la rama limpia sin cambios pendientes.

echo "--- Automatización de Fusión y Push en Git ---"

# --- Sección para manejar archivos no rastreados y cambios locales al inicio ---
echo ""
echo "Verificando estado del directorio de trabajo..."

# Guarda la rama actual antes de cualquier operación de stash/commit
current_branch_at_start=$(git rev-parse --abbrev-ref HEAD)
SHOULD_POP_STASH="false" # Inicializa la bandera del stash

# 1. Manejar archivos sin seguimiento (untracked files)
untracked_files=$(git ls-files --others --exclude-standard)
if [ -n "$untracked_files" ]; then
    echo "Se encontraron los siguientes archivos sin seguimiento:"
    echo "$untracked_files"
    read -p "¿Deseas añadir y commitear estos archivos ahora? (s/n): " confirm_add_untracked
    if [[ "$confirm_add_untracked" =~ ^[Ss]$ ]]; then
        echo "Añadiendo archivos sin seguimiento..."
        git add .
        if [ $? -ne 0 ]; then
            echo "Error: No se pudieron añadir los archivos. Abortando."
            exit 1
        fi
        read -p "Ingresa un mensaje para el commit de estos archivos (por defecto: 'feat: Added untracked files'): " untracked_commit_message
        if [ -z "$untracked_commit_message" ]; then
            untracked_commit_message="feat: Added untracked files"
        fi
        echo "Realizando commit de los archivos sin seguimiento..."
        git commit -m "$untracked_commit_message"
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo realizar el commit de los archivos. Abortando."
            exit 1
        fi
        echo "Archivos sin seguimiento commiteados exitosamente."
        # Empujar estos cambios iniciales si estás en una rama existente
        if [ "$current_branch_at_start" != "HEAD" ]; then # No es HEAD si estás en una rama
            read -p "¿Deseas empujar estos cambios iniciales a 'origin/$current_branch_at_start'? (s/n): " confirm_push_initial
            if [[ "$confirm_push_initial" =~ ^[Ss]$ ]]; then
                echo "Empujando cambios iniciales..."
                git push origin "$current_branch_at_start"
                if [ $? -ne 0 ]; then
                    echo "Advertencia: No se pudieron empujar los cambios iniciales. Puedes hacerlo manualmente después."
                fi
            fi
        fi
    else
        echo "Archivos sin seguimiento ignorados por ahora. El script continuará."
    fi
else
    echo "No se encontraron archivos sin seguimiento."
fi
echo "---"

# 2. Manejar cambios locales (modified/staged files)
# Verifica si hay cambios locales pendientes (modified o staged pero no committed)
if ! git diff-index --quiet HEAD -- || ! git diff-files --quiet; then
    echo "Se encontraron cambios locales pendientes (modificados o staged) en la rama '$current_branch_at_start'."
    echo "Estado de Git:"
    git status --short # Muestra un resumen conciso del estado

    # Ofrecer commit o stash
    read -p "¿Deseas commitear estos cambios antes de la fusión? (s/n, por defecto: n para stash): " confirm_commit_local
    if [[ "$confirm_commit_local" =~ ^[Ss]$ ]]; then
        echo "Añadiendo todos los cambios locales para commit..."
        git add .
        if [ $? -ne 0 ]; then
            echo "Error: No se pudieron añadir los cambios locales. Abortando."
            exit 1
        fi
        read -p "Ingresa un mensaje para el commit de estos cambios (por defecto: 'feat: (WIP) cambios locales antes de fusionar main'): " local_commit_message
        if [ -z "$local_commit_message" ]; then
            local_commit_message="feat: (WIP) cambios locales antes de fusionar main"
        fi
        echo "Realizando commit de los cambios locales..."
        git commit -m "$local_commit_message"
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo realizar el commit de los cambios locales. Abortando."
            exit 1
        fi
        echo "Cambios locales commiteados exitosamente."
        SHOULD_POP_STASH="false" # No hay stash que hacer pop
    else
        read -p "¿Deseas hacer stash de estos cambios antes de la fusión? (s/n): " confirm_stash
        if [[ "$confirm_stash" =~ ^[Ss]$ ]]; then
            echo "Guardando cambios locales con git stash..."
            git stash push -m "Automated stash before merge from main into $current_branch_at_start"
            if [ $? -ne 0 ]; then
                echo "Error: No se pudo realizar el stash. Abortando fusión."
                exit 1
            fi
            echo "Cambios guardados en stash. Continuar con la fusión."
            SHOULD_POP_STASH="true"
        else
            echo "Advertencia: Cambios locales no manejados. Si hay conflictos, la fusión podría fallar o dejar cambios pendientes."
            SHOULD_POP_STASH="false"
            # Continuar bajo el riesgo del usuario. Considera `exit 1` aquí si prefieres ser estricto.
        fi
    fi
else
    echo "No se encontraron cambios locales pendientes. El árbol de trabajo está limpio."
    SHOULD_POP_STASH="false"
fi
echo "---"

# --- Resto del script de fusión de ramas ---

# 1. Preguntar por el nombre de la rama principal
read -p "¿Cuál es el nombre de tu rama principal (ej: main, master)? " main_branch

# Validar que la rama principal no esté vacía
if [ -z "$main_branch" ]; then
    echo "Error: El nombre de la rama principal no puede estar vacío."
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
    exit 1
fi

# 2. Preguntar por el nombre de la segunda rama a actualizar
read -p "¿Cuál es el nombre de la rama que quieres actualizar desde la principal? " target_branch

# Validar que la rama objetivo no esté vacía
if [ -z "$target_branch" ]; then
    echo "Error: El nombre de la rama a actualizar no puede estar vacío."
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
    exit 1
fi

# Validar que las ramas no sean las mismas
if [ "$main_branch" == "$target_branch" ]; then
    echo "Error: Las ramas principal y objetivo no pueden ser la misma."
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
    exit 1
fi

echo ""
echo "Iniciando proceso de Git..."
echo "--------------------------"

# 3. La rama actual al inicio ya la tenemos en current_branch_at_start
echo "Estás actualmente en la rama: $current_branch_at_start"

# 4. Cambiar a la rama principal para asegurarnos de que esté actualizada
echo "Cambiando a la rama principal: $main_branch"
git checkout "$main_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $main_branch. Asegúrate de que existe."
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
    exit 1
fi

echo "Trayendo los últimos cambios de la rama principal..."
git pull origin "$main_branch"
if [ $? -ne 0 ]; then
    echo "Advertencia: No se pudieron traer los últimos cambios de la rama $main_branch. Puede que necesites resolver conflictos manualmente si hay."
fi

# 5. Cambiar a la rama objetivo para actualizarla
echo "Cambiando a la rama objetivo: $target_branch"
git checkout "$target_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $target_branch. Asegúrate de que existe."
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
    exit 1
fi

# 6. Fusionar la rama principal en la rama objetivo
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
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi # Intenta hacer pop del stash aunque haya conflicto
    exit 1
fi

# 7. Realizar el commit si hay cambios (en caso de que la fusión haya sido "fast-forward" o resuelta automáticamente)
# Primero, verificamos si hay cambios pendientes de commit después del merge
if git diff --cached --exit-code; then
    echo "No hay cambios pendientes de commit después de la fusión. Continuar..."
else
    echo "Realizando commit de la fusión..."
    git commit -m "Merge branch '$main_branch' into '$target_branch'"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo realizar el commit de la fusión."
        if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
        exit 1
    fi
fi

# 8. Empujar los cambios a la rama remota
echo "Empujando los cambios a 'origin/$target_branch'..."
git push origin "$target_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo empujar los cambios a 'origin/$target_branch'."
    if [ "$SHOULD_POP_STASH" == "true" ]; then git stash pop; fi
    exit 1
fi

echo ""
echo "----------------------------------------------------"
echo "¡Proceso completado exitosamente!"
echo "Ahora, al ejecutar 'git status', debería decir que no hay cambios por hacer."
git status

# Opcional: Volver a la rama original si el usuario no estaba en la rama objetivo
if [ "$current_branch_at_start" != "$target_branch" ]; then
    echo "Volviendo a tu rama original: $current_branch_at_start"
    git checkout "$current_branch_at_start"
fi

# Hacer pop del stash si se hizo uno al inicio
if [ "$SHOULD_POP_STASH" == "true" ]; then
    echo "Aplicando cambios guardados con git stash pop..."
    git stash pop
    # Verificar el estado del stash pop
    if [ $? -ne 0 ]; then
        echo "Advertencia: Hubo problemas al aplicar el stash. Puede que necesites resolver conflictos."
        echo "Puedes usar 'git stash list' para ver tus stashes y 'git stash apply' para aplicarlos manualmente."
        # No se sale aquí, para que el script termine, pero se notifica el problema.
    else
        echo "Stash aplicado exitosamente."
    fi
    # Volver a verificar el estado después del pop para ver si quedó limpio
    echo "Estado de Git después de aplicar stash:"
    git status
fi

echo "----------------------------------------------------"