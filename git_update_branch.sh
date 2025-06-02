#!/bin/bash

# Este script automatiza el proceso de fusionar una rama principal en otra rama,
# hacer commit y push, dejando la rama limpia sin cambios pendientes.

echo "--- Automatización de Fusión y Push en Git ---"

# --- Sección para manejar archivos no rastreados al inicio ---
echo ""
echo "Verificando archivos sin seguimiento (untracked files)..."
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
        read -p "Ingresa un mensaje para el commit de estos archivos: " untracked_commit_message
        if [ -z "$untracked_commit_message" ]; then
            untracked_commit_message="Add new untracked files"
        fi
        echo "Realizando commit de los archivos sin seguimiento..."
        git commit -m "$untracked_commit_message"
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo realizar el commit de los archivos. Abortando."
            exit 1
        fi
        echo "Archivos sin seguimiento commiteados exitosamente."
        # Empujar estos cambios iniciales si estás en una rama existente
        current_branch_before_ops=$(git rev-parse --abbrev-ref HEAD)
        if [ "$current_branch_before_ops" != "HEAD" ]; then # No es HEAD si estás en una rama
            read -p "¿Deseas empujar estos cambios iniciales a 'origin/$current_branch_before_ops'? (s/n): " confirm_push_initial
            if [[ "$confirm_push_initial" =~ ^[Ss]$ ]]; then
                echo "Empujando cambios iniciales..."
                git push origin "$current_branch_before_ops"
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

# --- Resto del script de fusión de ramas ---

# 1. Preguntar por el nombre de la rama principal
read -p "¿Cuál es el nombre de tu rama principal (ej: main, master)? " main_branch

# Validar que la rama principal no esté vacía
if [ -z "$main_branch" ]; then
    echo "Error: El nombre de la rama principal no puede estar vacío."
    exit 1
fi

# 2. Preguntar por el nombre de la segunda rama a actualizar
read -p "¿Cuál es el nombre de la rama que quieres actualizar desde la principal? " target_branch

# Validar que la rama objetivo no esté vacía
if [ -z "$target_branch" ]; then
    echo "Error: El nombre de la rama a actualizar no puede estar vacío."
    exit 1
fi

# Validar que las ramas no sean las mismas
if [ "$main_branch" == "$target_branch" ]; then
    echo "Error: Las ramas principal y objetivo no pueden ser la misma."
    exit 1
fi

echo ""
echo "Iniciando proceso de Git..."
echo "--------------------------"

# 3. Guardar la rama actual en caso de que necesitemos volver
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Estás actualmente en la rama: $current_branch"

# 4. Cambiar a la rama principal para asegurarnos de que esté actualizada
echo "Cambiando a la rama principal: $main_branch"
git checkout "$main_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo cambiar a la rama $main_branch. Asegúrate de que existe."
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
        exit 1
    fi
fi

# 8. Empujar los cambios a la rama remota
echo "Empujando los cambios a 'origin/$target_branch'..."
git push origin "$target_branch"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo empujar los cambios a 'origin/$target_branch'."
    exit 1
fi

echo ""
echo "----------------------------------------------------"
echo "¡Proceso completado exitosamente!"
echo "Ahora, al ejecutar 'git status', debería decir que no hay cambios por hacer."
git status

# Opcional: Volver a la rama original si el usuario no estaba en la rama objetivo
if [ "$current_branch" != "$target_branch" ]; then
    echo "Volviendo a tu rama original: $current_branch"
    git checkout "$current_branch"
fi

echo "----------------------------------------------------"