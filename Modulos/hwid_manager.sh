cat > /bin/hwid_manager << 'EOF'
#!/bin/bash
# hwid_manager - Gestion de usuarios HWID (identificador unico)
# Sin colores - Usa misma logica de desconexion que SSH

DB_HWID="/etc/SSHPlus/hwid.db"
AUTH_LOG="/var/log/auth.log"

mkdir -p /etc/SSHPlus
mkdir -p /etc/SSHPlus/senha
touch "$DB_HWID"

# ================================================================
# DETECTAR CONEXION ACTIVA DE UN USUARIO (UNIVERSAL)
# ================================================================

detectar_pid_usuario() {
    local user="$1"
    
    # METODO 1: Buscar en dropbear por logs
    local pid=$(grep "Password auth succeeded for '$user'" "$AUTH_LOG" 2>/dev/null | tail -1 | grep -oP 'dropbear\[\K[0-9]+')
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "$pid"
        return
    fi
    
    # METODO 2: Buscar en sshd
    pid=$(ps aux | grep "[s]shd" | grep "$user" | grep -v "priv" | awk '{print $2}' | head -1)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        echo "$pid"
        return
    fi
    
    # METODO 3: Buscar por procesos del usuario
    pid=$(pgrep -u "$user" 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
        echo "$pid"
        return
    fi
    
    echo ""
}

# ================================================================
# DESCONECTAR USUARIO (UNIVERSAL - misma logica que SSH)
# ================================================================

desconectar_usuario() {
    local user="$1"
    
    # Obtener PID de la conexion activa
    local target_pid=$(detectar_pid_usuario "$user")
    
    if [[ -n "$target_pid" ]]; then
        echo "  Proceso encontrado: PID $target_pid"
        kill -9 "$target_pid" 2>/dev/null
        
        # Matar procesos hijos
        local children=$(pgrep -P "$target_pid" 2>/dev/null)
        for child in $children; do
            kill -9 "$child" 2>/dev/null
        done
        
        sleep 1
    fi
    
    # Limpiar cualquier proceso remanente del usuario
    pkill -9 -u "$user" 2>/dev/null
    skill -KILL -u "$user" 2>/dev/null
    
    # Buscar y matar PIDs en logs de auth
    local pids=$(grep "Password auth succeeded for '$user'" "$AUTH_LOG" 2>/dev/null | grep -oP 'dropbear\[\K[0-9]+' | sort -u)
    for pid in $pids; do
        kill -9 "$pid" 2>/dev/null
    done
    
    sleep 1
}

# ================================================================
# LISTAR USUARIOS HWID CON ESTADO DE CONEXION
# ================================================================

listar() {
    echo "=========================================="
    echo "  USUARIOS HWID"
    echo "=========================================="
    if [[ ! -s "$DB_HWID" ]]; then
        echo "  No hay usuarios HWID"
        return
    fi
    echo "  ID | NOMBRE | HWID | EXPIRA | CONECTADO"
    echo "  ---|--------|------|-------|----------"
    local i=1
    while IFS='|' read -r nombre hwid exp; do
        [[ -z "$nombre" ]] && continue
        local estado="NO"
        local pid=$(detectar_pid_usuario "$hwid")
        if [[ -n "$pid" ]]; then
            estado="SI (PID $pid)"
        fi
        local exp_sec=$(date +%s -d "$exp" 2>/dev/null)
        local now_sec=$(date +%s)
        local dias=$(( (exp_sec - now_sec) / 86400 ))
        [[ $dias -lt 0 ]] && dias=0
        printf "  %-3s| %-7s| %-33s| %-10s| %s\n" "$i" "$nombre" "$hwid" "$exp" "$estado"
        i=$((i+1))
    done < "$DB_HWID"
    echo "=========================================="
}

# ================================================================
# CREAR USUARIO HWID
# ================================================================

crear() {
    echo "=========================================="
    echo "  CREAR USUARIO HWID"
    echo "=========================================="
    
    read -p "  Nombre identificador: " nombre
    [[ -z "$nombre" ]] && echo "  Cancelado" && return
    
    # Verificar si ya existe
    if grep -q "^$nombre|" "$DB_HWID" 2>/dev/null; then
        echo "  ERROR: El nombre '$nombre' ya existe"
        return
    fi
    
    read -p "  HWID del dispositivo: " hwid
    hwid=$(echo "$hwid" | tr -d ' ')
    [[ -z "$hwid" ]] && echo "  Cancelado" && return
    
    # Verificar HWID duplicado
    if grep -q "|$hwid|" "$DB_HWID" 2>/dev/null; then
        echo "  ERROR: El HWID '$hwid' ya esta registrado"
        return
    fi
    
    # Verificar si ya existe como usuario Linux y limpiar
    if grep -q "^$hwid:" /etc/passwd 2>/dev/null; then
        echo "  ADVERTENCIA: El HWID ya existe como usuario, limpiando..."
        userdel -f "$hwid" 2>/dev/null
        sed -i "/^$hwid:/d" /etc/passwd 2>/dev/null
        sed -i "/^$hwid:/d" /etc/shadow 2>/dev/null
    fi
    
    read -p "  Dias expiracion (1-365): " dias
    [[ ! "$dias" =~ ^[0-9]+$ ]] && dias=30
    
    local final=$(date "+%Y-%m-%d" -d "+$dias days")
    
    # Crear usuario Linux con el HWID como login Y como contraseña (igual que demo)
    local pass_crypt=$(perl -e 'print crypt($ARGV[0], "salt")' "$hwid" 2>/dev/null)
    
    if [ -n "$pass_crypt" ]; then
        useradd -e "$final" -M -s /bin/false -p "$pass_crypt" "$hwid" 2>/dev/null
    else
        # Fallback si perl falla
        useradd -e "$final" -M -s /bin/false "$hwid" 2>/dev/null
        echo "$hwid:$hwid" | chpasswd 2>/dev/null
    fi
    
    if [ $? -eq 0 ] || grep -q "^$hwid:" /etc/passwd 2>/dev/null; then
        # Guardar contraseña (el HWID mismo)
        echo "$hwid" > "/etc/SSHPlus/senha/$hwid"
        
        # Guardar en base de datos
        echo "$nombre|$hwid|$final" >> "$DB_HWID"
        
        echo ""
        echo "  OK: Usuario HWID creado exitosamente"
        echo "  Nombre: $nombre"
        echo "  HWID (usuario): $hwid"
        echo "  Password: $hwid"
        echo "  Expira: $final"
    else
        echo ""
        echo "  ERROR: No se pudo crear el usuario en el sistema"
        echo "  Guardando solo en base de datos..."
        echo "$nombre|$hwid|$final" >> "$DB_HWID"
    fi
    
    echo ""
    read -p "  ENTER para continuar..."
}

# ================================================================
# BORRAR USUARIO HWID (CON DESCONEXION - misma logica que SSH)
# ================================================================

borrar() {
    listar
    echo ""
    read -p "  ID a borrar (0=cancelar): " id
    [[ -z "$id" || "$id" == "0" ]] && echo "  Cancelado" && return
    
    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
        echo "  ERROR: ID invalido"
        return
    fi
    
    local linea=$(sed -n "${id}p" "$DB_HWID")
    local nombre=$(echo "$linea" | cut -d'|' -f1)
    local hwid=$(echo "$linea" | cut -d'|' -f2)
    
    if [[ -z "$hwid" ]]; then
        echo "  ERROR: ID invalido"
        return
    fi
    
    echo ""
    echo "  Usuario: $nombre"
    echo "  HWID: $hwid"
    read -p "  Confirmar borrado (s/N): " confirm
    [[ ! "$confirm" =~ ^[sS]$ ]] && echo "  Cancelado" && return
    
    echo ""
    echo "  =========================================="
    
    # PASO 1: Desconectar al usuario
    echo "  Desconectando $hwid..."
    desconectar_usuario "$hwid"
    
    # PASO 2: Bloquear cuenta
    echo "  Bloqueando cuenta..."
    usermod -L "$hwid" 2>/dev/null
    passwd -l "$hwid" 2>/dev/null
    chage -E 0 "$hwid" 2>/dev/null
    
    # PASO 3: Eliminar usuario del sistema
    echo "  Eliminando usuario del sistema..."
    userdel -f "$hwid" 2>/dev/null
    userdel -rf "$hwid" 2>/dev/null
    
    # Limpieza manual
    sed -i "/^$hwid:/d" /etc/passwd 2>/dev/null
    sed -i "/^$hwid:/d" /etc/shadow 2>/dev/null
    sed -i "/^$hwid:/d" /etc/group 2>/dev/null
    sed -i "/^$hwid:/d" /etc/gshadow 2>/dev/null
    rm -rf "/home/$hwid" 2>/dev/null
    rm -f "/etc/SSHPlus/senha/$hwid"
    
    # PASO 4: Borrar de la base de datos
    echo "  Limpiando base de datos..."
    sed -i "${id}d" "$DB_HWID"
    
    echo "  =========================================="
    echo ""
    echo "  OK: $nombre ($hwid) eliminado"
    echo ""
    read -p "  ENTER para continuar..."
}

# ================================================================
# RENOVAR EXPIRACION HWID
# ================================================================

renovar() {
    listar
    echo ""
    read -p "  ID a renovar: " id
    
    if [[ -z "$id" ]] || [[ ! "$id" =~ ^[0-9]+$ ]]; then
        echo "  ERROR: ID invalido"
        return
    fi
    
    local linea=$(sed -n "${id}p" "$DB_HWID")
    local nombre=$(echo "$linea" | cut -d'|' -f1)
    local hwid=$(echo "$linea" | cut -d'|' -f2)
    
    if [[ -z "$hwid" ]]; then
        echo "  ERROR: ID invalido"
        return
    fi
    
    echo ""
    echo "  Usuario: $nombre"
    echo "  HWID: $hwid"
    echo ""
    echo "  FORMATOS ACEPTADOS:"
    echo "    - Dias: 30 (30 dias a partir de hoy)"
    echo "    - Fecha: DD/MM/AAAA"
    echo ""
    read -p "  Nueva fecha o dias: " inputdate
    
    if [[ -z "$inputdate" ]]; then
        echo "  Cancelado"
        return
    fi
    
    if [[ "$inputdate" =~ "/" ]]; then
        sysdate="$(echo "$inputdate" | awk -v FS=/ -v OFS=- '{print $3,$2,$1}')"
        udata="$inputdate"
    else
        if ! [[ "$inputdate" =~ ^[0-9]+$ ]]; then
            echo "  ERROR: Numero de dias invalido"
            return
        fi
        udata=$(date "+%d/%m/%Y" -d "+$inputdate days")
        sysdate="$(echo "$udata" | awk -v FS=/ -v OFS=- '{print $3,$2,$1}')"
    fi
    
    if ! date "+%Y-%m-%d" -d "$sysdate" > /dev/null 2>&1; then
        echo "  ERROR: Fecha invalida"
        return
    fi
    
    # Actualizar en DB
    sed -i "${id}s|[^|]*$|${sysdate}|" "$DB_HWID"
    
    # Actualizar expiracion del usuario Linux
    usermod -e "$sysdate" "$hwid" 2>/dev/null
    chage -E "$sysdate" "$hwid" 2>/dev/null
    usermod -U "$hwid" 2>/dev/null
    passwd -u "$hwid" 2>/dev/null
    
    echo ""
    echo "  OK: Expiracion de $nombre actualizada a $udata"
    echo ""
    read -p "  ENTER para continuar..."
}

# ================================================================
# LIMPIAR USUARIOS HWID EXPIRADOS
# ================================================================

limpiar() {
    echo "=========================================="
    echo "  LIMPIAR USUARIOS HWID EXPIRADOS"
    echo "=========================================="
    
    local hoy=$(date +%Y%m%d)
    local expirados=0
    local temp_file="/tmp/hwid_clean.tmp"
    > "$temp_file"
    
    while IFS='|' read -r nombre hwid exp; do
        [[ -z "$nombre" ]] && continue
        
        local exp_br=$(date -d "$exp" +"%Y%m%d" 2>/dev/null)
        
        if [[ -n "$exp_br" ]] && [[ "$hoy" -ge "$exp_br" ]]; then
            echo "  Borrando: $nombre (HWID: $hwid) - Expirado: $exp"
            
            # Desconectar
            desconectar_usuario "$hwid"
            
            # Bloquear
            usermod -L "$hwid" 2>/dev/null
            passwd -l "$hwid" 2>/dev/null
            
            # Borrar
            userdel -f "$hwid" 2>/dev/null
            sed -i "/^$hwid:/d" /etc/passwd 2>/dev/null
            sed -i "/^$hwid:/d" /etc/shadow 2>/dev/null
            rm -f "/etc/SSHPlus/senha/$hwid"
            
            expirados=$((expirados + 1))
        else
            echo "$nombre|$hwid|$exp" >> "$temp_file"
        fi
    done < "$DB_HWID"
    
    mv "$temp_file" "$DB_HWID"
    
    if [[ $expirados -eq 0 ]]; then
        echo "  No hay usuarios expirados"
    else
        echo "  OK: $expirados usuarios expirados borrados"
    fi
    echo "=========================================="
    echo ""
    read -p "  ENTER para continuar..."
}

# ================================================================
# INFORMACION USUARIOS HWID
# ================================================================

info() {
    echo "=========================================="
    echo "  INFORMACION USUARIOS HWID"
    echo "=========================================="
    if [[ ! -s "$DB_HWID" ]]; then
        echo "  No hay usuarios HWID registrados"
        echo "=========================================="
        return
    fi
    
    printf "%-5s %-15s %-35s %-12s %-10s\n" "ID" "Nombre" "HWID" "Expira" "Estado"
    echo "-------------------------------------------------------------------------------------"
    
    local i=1
    local total=0
    local activos=0
    local vencidos=0
    
    while IFS='|' read -r nombre hwid exp; do
        [[ -z "$nombre" ]] && continue
        
        total=$((total + 1))
        
        if [[ -z "$exp" ]] || [[ "$exp" == "never" ]]; then
            estado="Activo"
            activos=$((activos + 1))
        else
            local exp_br=$(date -d "$exp" +"%Y%m%d" 2>/dev/null)
            local hoy=$(date +%Y%m%d)
            
            if [[ "$hoy" -gt "$exp_br" ]]; then
                estado="VENCIDO"
                vencidos=$((vencidos + 1))
            else
                dias=$(( ($(date -d "$exp" +%s) - $(date +%s)) / 86400 ))
                estado="${dias}d restantes"
                activos=$((activos + 1))
            fi
        fi
        
        printf "[%02d]  %-15s %-35s %-12s %-10s\n" "$i" "$nombre" "$hwid" "$exp" "$estado"
        i=$((i + 1))
    done < "$DB_HWID"
    
    echo "-------------------------------------------------------------------------------------"
    echo "  Total: $total | Activos: $activos | Vencidos: $vencidos"
    echo "=========================================="
}

# ================================================================
# MENU PRINCIPAL
# ================================================================

case "$1" in
    list|ls)      listar ;;
    create|add)   crear ;;
    delete|del)   borrar ;;
    renew)        renovar ;;
    clean)        limpiar ;;
    info)         info ;;
    *)
        echo "hwid_manager - Gestion de usuarios HWID"
        echo "Uso: hwid_manager [list|create|delete|renew|clean|info]"
        ;;
esac
EOF

chmod +x /bin/hwid_manager

# Corregir usuarios existentes - asignar contraseña = HWID
echo "Corrigiendo usuarios HWID existentes..."
while IFS='|' read -r nombre hwid exp; do
    [[ -z "$nombre" ]] && continue
    if grep -q "^$hwid:" /etc/passwd 2>/dev/null; then
        echo "  Fijando contraseña para $nombre ($hwid)..."
        echo "$hwid:$hwid" | chpasswd 2>/dev/null
        echo "$hwid" > "/etc/SSHPlus/senha/$hwid"
    fi
done < /etc/SSHPlus/hwid.db

echo "✅ hwid_manager actualizado - Contraseña = HWID (igual que demo)"
echo "✅ Usuarios existentes corregidos"