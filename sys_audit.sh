#!/bin/bash

# ==========================================
# CONFIGURACIÓN
# ==========================================
HOSTNAME=$(hostname)
FECHA=$(date +%F_%H-%M)
# Intenta obtener el usuario real si se usa sudo, sino usa el actual
USER_CURRENT=${SUDO_USER:-$(whoami)}
OUTPUT_FILE="server_report_${HOSTNAME}_${FECHA}.md"
SEARCH_DIRS=("/home" "/opt" "/var/www" "/srv")

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Iniciando escaneo profundo del servidor: $HOSTNAME${NC}"

# ==========================================
# FUNCIONES
# ==========================================
write_header() {
    echo "" >> "$OUTPUT_FILE"
    echo "## $1" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
}

write_code() {
    echo "\`\`\`$1" >> "$OUTPUT_FILE"
}

end_code() {
    echo "\`\`\`" >> "$OUTPUT_FILE"
}

# ==========================================
# 1. CABECERA
# ==========================================
echo "# Reporte de Infraestructura: $HOSTNAME" > "$OUTPUT_FILE"
echo "**Fecha:** $(date)" >> "$OUTPUT_FILE"
echo "**Kernel:** $(uname -r)" >> "$OUTPUT_FILE"
echo "**Uptime:** $(uptime -p)" >> "$OUTPUT_FILE"

# ==========================================
# 2. HARDWARE
# ==========================================
write_header "1. Hardware y Recursos"
echo "**CPU:**" >> "$OUTPUT_FILE"
write_code "text"
lscpu | grep -E 'Model name|Architecture|CPUs' >> "$OUTPUT_FILE"
end_code

echo "**Memoria RAM:**" >> "$OUTPUT_FILE"
write_code "text"
free -h >> "$OUTPUT_FILE"
end_code

echo "**Discos y Particiones:**" >> "$OUTPUT_FILE"
write_code "text"
lsblk -d -o NAME,MODEL,SIZE,TYPE >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
df -hT | grep -v "tmpfs" | grep -v "loop" >> "$OUTPUT_FILE"
end_code

# ==========================================
# 3. RED Y SEGURIDAD
# ==========================================
write_header "2. Red y Seguridad"
echo "**Puertos Expuestos (Listening):**" >> "$OUTPUT_FILE"
write_code "text"
ss -tulnp | awk 'NR==1 || /LISTEN/' >> "$OUTPUT_FILE"
end_code

echo "**Estado del Firewall (UFW):**" >> "$OUTPUT_FILE"
write_code "text"
if command -v ufw &> /dev/null; then
    # Redirigimos stderr para evitar ruido si falta permiso
    ufw status verbose >> "$OUTPUT_FILE" 2>&1
else
    echo "UFW no instalado" >> "$OUTPUT_FILE"
fi
end_code

# ==========================================
# 4. SOFTWARE INSTALADO
# ==========================================
write_header "3. Software del Sistema"

echo "**APT (Paquetes manuales):**" >> "$OUTPUT_FILE"
write_code "text"
# Lógica corregida: Verificamos si existe el log antes de intentar leerlo
if [ -f /var/log/installer/initial-status.gz ]; then
    comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) 2>/dev/null >> "$OUTPUT_FILE"
else
    # Si no existe el log, listamos todo lo manual sin filtrar
    apt-mark showmanual >> "$OUTPUT_FILE"
fi
end_code

if command -v snap &> /dev/null; then
    echo "**Snap Packages:**" >> "$OUTPUT_FILE"
    write_code "text"
    snap list 2>/dev/null >> "$OUTPUT_FILE"
    end_code
fi

if command -v flatpak &> /dev/null; then
    echo "**Flatpak Packages:**" >> "$OUTPUT_FILE"
    write_code "text"
    flatpak list --columns=app,name,version,origin 2>/dev/null >> "$OUTPUT_FILE"
    end_code
fi

# ==========================================
# 5. DOCKER
# ==========================================
write_header "4. Docker y Contenedores"
if command -v docker &> /dev/null; then
    echo "**Versión:** $(docker --version)" >> "$OUTPUT_FILE"
    echo -e "\n**Contenedores:**" >> "$OUTPUT_FILE"
    write_code "text"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" >> "$OUTPUT_FILE"
    end_code
    
    echo "**Proyectos Compose (Ruta del docker-compose.yml):**" >> "$OUTPUT_FILE"
    write_code "text"
    docker ps --format "{{.Label \"com.docker.compose.project.working_dir\"}}" | sort -u | grep -v "^$" >> "$OUTPUT_FILE"
    end_code
else
    echo "Docker no detectado." >> "$OUTPUT_FILE"
fi

# ==========================================
# 6. DESARROLLO (Git, Python, Node)
# ==========================================
write_header "5. Entorno de Desarrollo"

echo "**Repositorios GIT:**" >> "$OUTPUT_FILE"
write_code "text"
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 3 -name ".git" -type d -prune 2>/dev/null | while read gitdir; do
            repo_root=$(dirname "$gitdir")
            remote=$(git -C "$repo_root" remote get-url origin 2>/dev/null)
            echo "$repo_root  ->  $remote"
        done
    fi
done >> "$OUTPUT_FILE"
end_code

if command -v pipx &> /dev/null; then
    echo "**PIPX (Apps Python aisladas):**" >> "$OUTPUT_FILE"
    write_code "text"
    # El 2>/dev/null elimina el emoji de sueño si está vacío
    pipx list --short 2>/dev/null >> "$OUTPUT_FILE" || echo "Pipx instalado pero vacío." >> "$OUTPUT_FILE"
    end_code
fi

if command -v npm &> /dev/null; then
    echo "**NPM Global (-g):**" >> "$OUTPUT_FILE"
    write_code "text"
    npm list -g --depth=0 2>/dev/null >> "$OUTPUT_FILE"
    end_code
fi

# ==========================================
# 7. CRON Y SERVICIOS
# ==========================================
write_header "6. Cron y Servicios"
echo "**Crontab de $USER_CURRENT:**" >> "$OUTPUT_FILE"
write_code "bash"
crontab -u $USER_CURRENT -l 2>/dev/null >> "$OUTPUT_FILE"
end_code

echo "**Servicios Systemd Personalizados:**" >> "$OUTPUT_FILE"
write_code "text"
find /etc/systemd/system -name "*.service" -type f ! -type l | xargs basename -a 2>/dev/null >> "$OUTPUT_FILE"
end_code

# ==========================================
# 8. GENERADOR DE RESTAURACIÓN
# ==========================================
write_header "7. COMANDOS DE RECUPERACIÓN (Cheat Sheet)"
echo "> Copia estos bloques para reinstalar en otro servidor." >> "$OUTPUT_FILE"

echo "### APT Install" >> "$OUTPUT_FILE"
write_code "bash"
echo "sudo apt update && sudo apt install -y \\" >> "$OUTPUT_FILE"

# Lógica robusta para la lista de recuperación
if [ -f /var/log/installer/initial-status.gz ]; then
    comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) 2>/dev/null | tr '\n' ' ' >> "$OUTPUT_FILE"
else
    # Fallback si no hay log de instalador
    apt-mark showmanual | tr '\n' ' ' >> "$OUTPUT_FILE"
fi
end_code

if command -v snap &> /dev/null; then
    echo "### Snap Install" >> "$OUTPUT_FILE"
    write_code "bash"
    snap list 2>/dev/null | awk 'NR>1 {print "sudo snap install " $1 " " ($3=="classic"?"--classic":"")}' >> "$OUTPUT_FILE"
    end_code
fi

echo -e "${GREEN}¡Hecho! Reporte generado correctamente: ${YELLOW}$OUTPUT_FILE${NC}"
