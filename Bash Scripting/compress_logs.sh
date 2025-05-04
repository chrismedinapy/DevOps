#!/bin/bash

# Parametros opcionales
MAX_SIZE_MB=${1:-100}
LOG_DIR=${2:-/var/log/nginx}

# Convertimos MB a bytes
MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))

echo "Comienza la compresion de logs en '$LOG_DIR'"
echo "Tamanho tope del log antes de comprimir: '$MAX_SIZE_MB' MB"

# Verificamos si la carpeta existe
if [ ! -d "$LOG_DIR" ]; then
    echo "Carpeta no encontrada: $LOG_DIR"
    exit 1
fi

# Buscamos si los logs sobrepasan el tamano max.

find "$LOG_DIR" -type f -name "*.log" | while read -r log_file; do
    # Linux
    #file_size = $(stat -c %s "$log_file")
    # MAC
    file_size=$(stat -f%z "$log_file")
    base_name=$(basename "$log_file" .log)
    dir_name=$(dirname "$log_file")
    if [ "$file_size" -ge "$MAX_SIZE_BYTES" ]; then
        i=1
        while [ -e "$dir_name/${base_name}.log.$i.gz" ]; do
            i=$((i+1))
        done
        new_name="$dir_name/${base_name}.log.${i}"
        echo " $log_file supera el limite ($(($file_size / 1024 / 1024)) MB ) ... Comprimiendo y renombrando a $new_name "
        mv "$log_file" "$new_name"
        gzip "$new_name"
    else
        echo " $log_file dentro del limite ($(($file_size / 1024 /1024 )) MB)"
    fi
done

echo "Finalizado."
