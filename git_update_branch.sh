#!/bin/bash
set -x

# ... (resto de tu script hasta la sección de "Verificando estado del directorio de trabajo...")

# --- Sección de Normalización de Finales de Línea para Archivos Específicos ---
echo ""
echo "Verificando y normalizando finales de línea para archivos específicos (git_update_branch.sh, index.html)..."

# Define los archivos que quieres normalizar
FILES_TO_NORMALIZE="git_update_branch.sh index.html"
NORMALIZATION_NEEDED=false

for file in $FILES_TO_NORMALIZE; do
    # Verifica si el archivo existe y si Git lo reporta como modificado (posiblemente por EOL)
    if [ -f "$file" ] && git status --porcelain | grep -q " M $file"; then
        echo "  - Se encontró '$file' modificado. Intentando normalizar finales de línea..."
        # Remover del índice y añadir de nuevo para que Git reprocese EOL
        git rm --cached "$file"
        if [ $? -ne 0 ]; then
            echo "    Error: No se pudo remover '$file' del índice. Continuar, pero puede haber problemas."
            continue
        fi
        git add "$file"
        if [ $? -ne 0 ]; then
            echo "    Error: No se pudo añadir '$file' al índice. Continuar, pero puede haber problemas."
            continue
        fi
        NORMALIZATION_NEEDED=true
        echo "    '$file' normalizado en el índice."
    else
        echo "  - '$file' no necesita normalización en este momento o no está modificado."
    fi
done

if [ "$NORMALIZATION_NEEDED" == "true" ]; then
    echo "Se detectaron y normalizaron finales de línea en algunos archivos."
    # Haz un commit si se normalizaron archivos. Esto generará un commit extra.
    echo "Realizando commit de normalización de finales de línea..."
    git commit -m "Chore: Normalize line endings for script and index files"
    if [ $? -ne 0 ]; then
        echo "Advertencia: No se pudo realizar el commit de normalización. Puede que necesites resolverlo manualmente."
    else
        echo "Commit de normalización completado."
        # Puedes añadir un `git push origin "$current_branch_at_start"` si quieres subirlo inmediatamente.
    fi
else
    echo "No se encontraron archivos que necesitaran normalización de finales de línea."
fi
echo "---"

# ... (el resto del script git_update_branch.sh, incluyendo las secciones de untracked files y local changes)