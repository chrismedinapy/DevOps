#!/bin/bash

# ================================================================================================================
# Script: alert_cpu.sh
# Descripcion: Monitorea el uso de CPU en linux/macOS
#               y envia una alerta por correo si
#               supera un umbral definido.
# Uso:
#   ./alerta_cpu.sh [humbral] [email]
# Parametros:
#   umbral [opcional]:      numero entero positivo representando el porcentaje de uso permitido (default: 80)
#   email  [opcional]:      correo para enviar alerta (default: tu-correo@gmail.com)
# Requisitos:
#   1. Instalar `msmtp`:
#      - macOS: brew install msmtp
#      - Debian/Ubuntu: sudo apt install msmtp
#
#   2. Instalar `mailutils`:
#      - macOS: brew install mailutils (o usar `brew install heirloom-mailx`)
#      - Debian/Ubuntu: sudo apt install mailutils
#
#   3. Configurar el archivo ~/.msmtprc con:
#
#      defaults
#      auth           on
#      tls            on
#      tls_trust_file /etc/ssl/cert.pem
#      logfile        ~/.msmtp.log
#
#      account gmail
#      host smtp.gmail.com
#      port 587
#      from tu_correo@gmail.com
#      user tu_correo@gmail.com
#      passwordeval "cat /Users/chris/.gmail_pass"
#
#      account default : gmail
#
#   4. Crear el archivo ~/.gmail_pass con la contraseña de aplicación de Gmail:
#      - chmod 600 ~/.gmail_pass
#
#   5. Probar con:
#      echo "Hola" | mail -s "Test" tu_correo@gmail.com
# ================================================================================================================

CPU_LIMIT=${1:-80}
EMAIL_TO=${2:-"tu-correo@gmail.com"}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/alert_cpu.log"

{
    echo " ======= [$(date '+%Y-%m-%d %H:%M:%S')] ========"
    echo " Iniciando chequeo de CPU"
    OS_TYPE=$(uname)
    # Obtener el porcentaje de CPU usada en macOS
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        CPU_USAGE=$(top -l 1 | awk '/CPU usage/ {print $3}' | sed 's/%//')
    else
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    fi

    echo "Uso actual de CPU: ${CPU_USAGE}%"
    echo "Umbral configurado: ${CPU_LIMIT}%"

    if (( $(echo "$CPU_USAGE > $CPU_LIMIT" | bc -l) )); then
        echo "ALERTA: Uso de CPU elevado ($CPU_USAGE%) supera el umbral ($CPU_LIMIT%)"
        SUBJECT="[ALERTA] CPU sobrecargada en $(hostname)"
        BODY="Se detecto un uso elevado de CPU en el servidor:\n\n\
        Host: $(hostname)\n\
        Fecha: $(date)\n\
        Uso actual: ${CPU_USAGE}%\n\
        Umbral configurado: ${CPU_LIMIT}%\n"

        echo -e "$BODY" | mail -s "$SUBJECT" "$EMAIL_TO"
    else
        echo "CPU dentro del rango normal"
    fi
} | tee -a "$LOG_FILE"