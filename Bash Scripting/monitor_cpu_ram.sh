#!/bin/bash
# ======================================================================================================
# Script: monitor_cpu_ram.sh
# Descripción: Monitorea el uso de CPU y RAM en Linux/macOS e imprime los valores actuales.
#              También guarda un log detallado en el mismo directorio que el script.
#
# Uso:
#   ./monitor_cpu_ram.sh
#
# Requisitos:
#   - Comandos `top`, `awk`, `grep`, `free` (Linux) o `vm_stat` (macOS)
# ======================================================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/monitor_cpu_ram.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
OS_TYPE=$(uname)

# Inicializamos
CPU_USAGE="?"
RAM_USAGE="?"

# MONITOREO CPU
if [[ "$OS_TYPE" == "Darwin" ]]; then
  # macOS
  CPU_USAGE=$(top -l 1 | awk '/CPU usage/ {print $3 + $5}' | sed 's/%//')
else
  # Linux
  CPU_USAGE=$(top -bn1 | awk -F'id,' '/Cpu\(s\):/ {
    split($1, vs, ",");
    for (i in vs) {
      if (vs[i] ~ /[0-9.]+ us/) {
        usage += substr(vs[i], 1, length(vs[i])-3)
      }
      if (vs[i] ~ /[0-9.]+ sy/) {
        usage += substr(vs[i], 1, length(vs[i])-3)
      }
    }
  }
  END { print usage }')
fi

# MONITOREO RAM
if [[ "$OS_TYPE" == "Darwin" ]]; then
  # macOS usa `vm_stat` y `pagesize`
  PAGES_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
  PAGES_ACTIVE=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
  PAGES_INACTIVE=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
  PAGES_SPECULATIVE=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | sed 's/\.//')
  PAGE_SIZE=$(vm_stat | grep "page size of" | awk '{print $8}')

  TOTAL_PAGES=$((PAGES_FREE + PAGES_ACTIVE + PAGES_INACTIVE + PAGES_SPECULATIVE))
  USED_PAGES=$((PAGES_ACTIVE + PAGES_INACTIVE + PAGES_SPECULATIVE))
  RAM_USAGE=$(awk "BEGIN {printf \"%.2f\", (${USED_PAGES} / ${TOTAL_PAGES}) * 100}")
else
  # Linux usa `free`
  RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
  RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
  RAM_USAGE=$(awk "BEGIN {printf \"%.2f\", (${RAM_USED} / ${RAM_TOTAL}) * 100}")
fi

# Output
echo "[$TIMESTAMP] CPU: ${CPU_USAGE}% | RAM: ${RAM_USAGE}%" | tee -a "$LOG_FILE"
