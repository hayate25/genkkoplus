cat > /bin/bloquear << 'EOF'
#!/bin/bash
# bloquear - Bloquear/Desbloquear usuarios por ID
# SOLO SE MODIFICO: listar_usuarios y get_user_by_id (filtro por modo)
# TODO LO DEMAS ESTA IGUAL QUE CUANDO FUNCIONO

DB_SSH="/root/usuarios.db"
DB_HWID="/etc/SSHPlus/hwid.db"
DB_TOKEN="/etc/SSHPlus/token.db"
LOCKED_LIST="/etc/SSHPlus/locked_users.db"
SENHA_DIR="/etc/SSHPlus/senha"
MODO_ACTUAL="/etc/SSHPlus/modo_actual.cfg"
AUTH_LOG="/var/log/auth.log"

mkdir -p /etc/SSHPlus
mkdir -p "$SENHA_DIR"
touch "$LOCKED_LIST"

if [ -f "$MODO_ACTUAL" ]; then
    modo=$(cat "$MODO_ACTUAL")
else
    modo="SSH"
fi

# ================================================================
# MATAR CONEXIONES (INTACTO - FUNCIONA)
# ================================================================

matar_conexiones() {
    local user="$1"
    
    echo "    Buscando conexiones de $user en auth.log..."
    
    local pids=$(grep "Password auth succeeded for '$user'" "$AUTH_LOG" 2>/dev/null | grep -oP 'dropbear\[\K[0-9]+' | sort -u)
    
    if [[ -z "$pids" ]]; then
        echo "    No se encontraron PIDs en auth.log"
    else
        for pid in $pids; do
            if kill -0 "$pid" 2>/dev/null; then
                echo "    Matando dropbear PID $pid (activo)"
                kill -9 "$pid" 2>/dev/null
            else
                echo "    PID $pid ya no esta activo"
            fi
        done
    fi
    
    ps aux | grep "[d]ropbear" | grep "$user" | awk '{print $2}' | while read pid; do
        echo "    Matando dropbear extra PID $pid..."
        kill -9 "$pid" 2>/dev/null
    done
    
    pkill -9 -u "$user" 2>/dev/null
    skill -KILL -u "$user" 2>/dev/null
    sleep 1
    
    local remain=$(grep "Password auth succeeded for '$user'" "$AUTH_LOG" 2>/dev/null | grep -oP 'dropbear\[\K[0-9]+' | sort -u)
    for pid in $remain; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "    REINTENTANDO matar PID $pid..."
            kill -9 "$pid" 2>/dev/null
        fi
    done
    
    echo "    Conexiones cerradas"
}

# ================================================================
# LISTAR USUARIOS (MODIFICADO: filtro por modo)
# ================================================================

listar_usuarios() {
    echo "=========================================="
    echo "  USUARIOS - MODO: $modo"
    echo "=========================================="
    
    case "$modo" in
        SSH)
            echo "  ID | USUARIO | ESTADO"
            echo "  ---|---------|----------"
            local id=1
            while IFS=' ' read -r user limite; do
                [[ -z "$user" ]] && continue
                local estado="ACTIVO"
                grep -qxF "$user" "$LOCKED_LIST" 2>/dev/null && estado="BLOQUEADO"
                printf "  %2d | %-7s | %s\n" "$id" "$user" "$estado"
                id=$((id+1))
            done < "$DB_SSH" 2>/dev/null
            ;;
        HWID)
            echo "  ID | NOMBRE | HWID | ESTADO"
            echo "  ---|--------|------|----------"
            local id=1
            while IFS='|' read -r nombre hwid exp; do
                [[ -z "$nombre" ]] && continue
                local estado="ACTIVO"
                grep -qxF "$hwid" "$LOCKED_LIST" 2>/dev/null && estado="BLOQUEADO"
                printf "  %2d | %-7s | %-16s... | %s\n" "$id" "$nombre" "${hwid:0:16}" "$estado"
                id=$((id+1))
            done < "$DB_HWID" 2>/dev/null
            ;;
        TOKEN)
            echo "  ID | NOMBRE | TOKEN | ESTADO"
            echo "  ---|--------|-------|----------"
            local id=1
            while IFS='|' read -r nombre token pass exp; do
                [[ -z "$nombre" ]] && continue
                local estado="ACTIVO"
                grep -qxF "$nombre" "$LOCKED_LIST" 2>/dev/null && estado="BLOQUEADO"
                printf "  %2d | %-7s | %-16s... | %s\n" "$id" "$nombre" "${token:0:16}" "$estado"
                id=$((id+1))
            done < "$DB_TOKEN" 2>/dev/null
            ;;
    esac
    
    echo "=========================================="
}

# ================================================================
# OBTENER USUARIO POR ID (MODIFICADO: solo busca en modo actual)
# ================================================================

get_user_by_id() {
    local id="$1"
    local current=1
    
    case "$modo" in
        SSH)
            while IFS=' ' read -r user limite; do
                [[ -z "$user" ]] && continue
                [[ $current -eq $id ]] && echo "$user" && return
                current=$((current+1))
            done < "$DB_SSH" 2>/dev/null
            ;;
        HWID)
            while IFS='|' read -r nombre hwid exp; do
                [[ -z "$nombre" ]] && continue
                [[ $current -eq $id ]] && echo "$hwid" && return
                current=$((current+1))
            done < "$DB_HWID" 2>/dev/null
            ;;
        TOKEN)
            while IFS='|' read -r nombre token pass exp; do
                [[ -z "$nombre" ]] && continue
                [[ $current -eq $id ]] && echo "$nombre" && return
                current=$((current+1))
            done < "$DB_TOKEN" 2>/dev/null
            ;;
    esac
    
    echo ""
}

# ================================================================
# BLOQUEAR (INTACTO - FUNCIONA)
# ================================================================

bloquear_usuario() {
    local user="$1"
    
    if grep -qxF "$user" "$LOCKED_LIST" 2>/dev/null; then
        echo "  $user YA ESTA BLOQUEADO"
        return
    fi
    
    echo "  =========================================="
    echo "  BLOQUEANDO: $user"
    
    # 1. MATAR CONEXIONES
    matar_conexiones "$user"
    
    # 2. Cambiar contraseña
    local orig_pass=""
    [[ -f "$SENHA_DIR/$user" ]] && orig_pass=$(cat "$SENHA_DIR/$user")
    [[ -z "$orig_pass" ]] && grep -q "|$user|" "$DB_HWID" 2>/dev/null && orig_pass="$user"
    
    local new_pass="BLK_$(date +%s | tail -c 5)"
    echo "$user:$new_pass" | chpasswd 2>/dev/null
    echo "$orig_pass" > "$SENHA_DIR/${user}_bloqueado"
    
    # 3. Bloquear cuenta
    passwd -l "$user" 2>/dev/null
    usermod -L "$user" 2>/dev/null
    chage -E 0 "$user" 2>/dev/null
    
    # 4. Marcar
    echo "$user" >> "$LOCKED_LIST"
    
    echo "  OK: $user BLOQUEADO"
    echo "  =========================================="
}

# ================================================================
# DESBLOQUEAR (INTACTO - FUNCIONA)
# ================================================================

desbloquear_usuario() {
    local user="$1"
    
    if ! grep -qxF "$user" "$LOCKED_LIST" 2>/dev/null; then
        echo "  $user NO ESTA BLOQUEADO"
        return
    fi
    
    echo "  =========================================="
    echo "  DESBLOQUEANDO: $user"
    
    # 1. Restaurar contraseña
    if [[ -f "$SENHA_DIR/${user}_bloqueado" ]]; then
        local orig=$(cat "$SENHA_DIR/${user}_bloqueado")
        echo "$user:$orig" | chpasswd 2>/dev/null
        rm -f "$SENHA_DIR/${user}_bloqueado"
        echo "    Contraseña restaurada"
    elif grep -q "|$user|" "$DB_HWID" 2>/dev/null; then
        echo "$user:$user" | chpasswd 2>/dev/null
        echo "    Contraseña restaurada (HWID)"
    elif [[ -f "$SENHA_DIR/$user" ]]; then
        local orig=$(cat "$SENHA_DIR/$user")
        echo "$user:$orig" | chpasswd 2>/dev/null
        echo "    Contraseña restaurada (original)"
    fi
    
    # 2. Desbloquear cuenta
    passwd -u "$user" 2>/dev/null
    usermod -U "$user" 2>/dev/null
    
    # 3. Restaurar fecha
    if grep -q "|$user|" "$DB_HWID" 2>/dev/null; then
        local h=$(grep "|$user|" "$DB_HWID" 2>/dev/null)
        local exp=$(echo "$h" | cut -d'|' -f3)
        [[ -n "$exp" && "$exp" != "never" ]] && chage -E "$exp" "$user" 2>/dev/null || chage -E -1 "$user" 2>/dev/null
    else
        chage -E -1 "$user" 2>/dev/null
    fi
    
    # 4. Quitar de lista
    sed -i "/^$user$/d" "$LOCKED_LIST" 2>/dev/null
    
    echo "  OK: $user DESBLOQUEADO"
    echo "  =========================================="
}

# ================================================================
# MENU (INTACTO)
# ================================================================

while true; do
    clear
    echo "=========================================="
    echo "  BLOQUEAR / DESBLOQUEAR USUARIOS"
    echo "=========================================="
    listar_usuarios
    echo ""
    echo "  [1] Bloquear usuario"
    echo "  [2] Desbloquear usuario"
    echo "  [0] Volver"
    echo "=========================================="
    echo -n "  Opcion: "; read opt
    
    case $opt in
        1)
            echo -n "  ID a BLOQUEAR: "; read id
            if [[ -n "$id" && "$id" =~ ^[0-9]+$ ]]; then
                user=$(get_user_by_id "$id")
                [[ -n "$user" ]] && bloquear_usuario "$user" || echo "  ERROR: ID invalido"
            fi
            echo ""; read -p "  ENTER para continuar..."
            ;;
        2)
            echo -n "  ID a DESBLOQUEAR: "; read id
            if [[ -n "$id" && "$id" =~ ^[0-9]+$ ]]; then
                user=$(get_user_by_id "$id")
                [[ -n "$user" ]] && desbloquear_usuario "$user" || echo "  ERROR: ID invalido"
            fi
            echo ""; read -p "  ENTER para continuar..."
            ;;
        0) exit 0 ;;
    esac
done
EOF

chmod +x /bin/bloquear
echo "✅ bloquear - solo cambia lista por modo, logica intacta"