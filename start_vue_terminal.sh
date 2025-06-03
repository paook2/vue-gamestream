#!/bin/zsh

PROJECT_PATH="/Users/paolazapatagonzalez/Downloads/Paola/LifeFile/Projects/vueJs/vue-gamestream"
PROJECT_NAME="vue-gamestream"

echo "🚀 Iniciando proyecto $PROJECT_NAME..."

# Verifica si estás en carpeta protegida como Downloads
if [[ "$PROJECT_PATH" == *"/Downloads/"* ]]; then
  echo "⚠ Estás trabajando desde la carpeta Downloads. Puede que Sublime solicite permisos."
fi

# Verifica subl
if ! command -v subl &> /dev/null; then
  echo "❌ 'subl' no está disponible."
  echo "Ejecuta: sudo ln -s \"/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl\" /usr/local/bin/subl"
else
  echo "📝 Abriendo en Sublime Text..."
  subl "$PROJECT_PATH"
fi

cd "$PROJECT_PATH" || { echo "❌ No se pudo entrar a la carpeta del proyecto"; exit 1 }

echo "📦 Iniciando servidor con npm run dev..."

# Ejecuta npm run dev y analiza la salida
npm run dev | while IFS= read -r line; do
  echo "$line"
  if [[ "$line" == *"Local:"*http* ]]; then
    url=$(echo "$line" | grep -o 'http://[^ ]*')
    echo "🌐 Abriendo navegador en $url"
    open "$url"
    break
  fi
done
