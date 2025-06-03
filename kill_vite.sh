#!/bin/zsh

# Mata todos los procesos de Node.js (incluyendo los de Vite y npm run dev)
# -9 es una señal de "KILL" que fuerza la terminación.
killall -9 node
echo "✅ Procesos de Node.js (Vite) finalizados."

# También puedes cerrar todas las ventanas de Terminal si quieres una limpieza total
# osascript -e 'tell application "Terminal" to quit'