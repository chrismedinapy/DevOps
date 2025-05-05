# DevOps - Proyecto de Pruebas y Automatización

Este repositorio contiene ejemplos prácticos organizados por carpetas, útiles para tareas comunes de DevOps: scripting, contenedores, automatización, monitoreo y despliegue.

---

## Bash Scripting

Contiene scripts en Bash para automatización de tareas:

- `alert_cpu.sh`: Monitorea el uso de CPU en Linux y macOS. Si el uso supera un umbral (por defecto 80%), envía un correo de alerta. Requiere `msmtp` y `mailutils`.
- `compress_logs.sh`: Comprime archivos `.log` si superan un tamaño límite (por defecto 100MB). Se renombran con sufijos `.1`, `.2`, etc.
- `monitor_cpu_ram.sh`: Muestra y registra en un log el uso actual de CPU y RAM.

---

## Docker

- Contiene un servicio de prueba llamado `hola-mundo`.
- Incluye un `Dockerfile` para dockerizar la app.
- El `docker-compose.yml` levanta el servicio `hola-mundo` junto con PostgreSQL y monta volúmenes necesarios.
- 🔐 Por seguridad, el archivo `.env` no está en el repositorio. Se debe **copiar y renombrar `.env_example` a `.env`** y completar con las variables correspondientes.

---

## Helm Charts

Incluye un Helm Chart para desplegar el servicio `hola-mundo`:

- `Chart.yaml`: Metadatos del chart.
- `values.yaml`: Configuración editable por el usuario.
- `templates/`: Plantillas para generar los manifiestos Kubernetes (Deployment, Service, ConfigMap, etc.).

---

## Jenkins

Incluye un pipeline en Groovy que:

- Instala dependencias.
- Construye la imagen Docker de `hola-mundo`.

### Variables externas requeridas

El pipeline utiliza variables que deben definirse como **parámetros externos en Jenkins**:

- `GIT_CREDENTIAL_ID_TOKEN`
- `pullRequestNumber`

---

## Kubernetes

Contiene los archivos YAML necesarios para desplegar la app `hola-mundo`:

- `deployment.yaml`: Crea un Deployment con recursos, probes y configuración.
- `service.yaml`: Expone el servicio vía NodePort.
- `configmap.yaml`: Define las variables de entorno necesarias.

---

## Nota

Este repositorio es solo para fines de laboratorio, pruebas y aprendizaje. No se recomienda su uso directo en entornos de producción.
