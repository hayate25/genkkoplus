cat > /bin/ssh_manager << 'EOF'
#!/bin/bash
# ssh_manager - Gestion de usuarios SSH (con desconexion forzada)

DB_SSH="/root/usuarios.db"
SENHA_DIR="/etc/SSHPlus/senha"
AUTH_LOG="/var/log/auth.log"

mkdir -p "$SENHA_DIR"
touch "$DB_SSH"

listar() {
    echo "=========================================="
    echo "  USUARIOS SSH"
    echo "=========================================="
    if [[ ! -s "$DB_SSH" ]]; then
        echo "  No hay usuarios SSH"
        return
    fi
    
    # Obtener conexiones activas
    local conexiones=$(ss -tnp 2>/dev/null | grep "dropbear" | grep ESTAB)
    
    echo "  ID | USUARIO | LIMITE | CONECTADO"
    echo "  ---|---------|--------|----------"
    local i=1
    while IFS=' ' read -r user limite; do
        local estado="NO"
        if echo "$conexiones" | while read line; do
            pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+')
            grep -q "dropbear\[$pid\].*Password auth succeeded for '$user'" "$AUTH_LOG" 2>/dev/null && echo "SI" && break
        done | grep -q "SI"; then
            estado="SI"
        fi
        echo "  $i | $user | $limite | $estado"
        i=$((i+1))
    done < "$DB_SSH"
    echo "=========================================="
}

crear() {
    echo "=========================================="
    echo "  CREAR USUARIO SSH"
    echo "=========================================="
    
    read -p "  Usuario (min 4): " username
    [[ -z "$username" ]] && return
    
    if grep -q "^$username " "$DB_SSH"; then
        echo "  ERROR: Usuario ya existe"
        return
    fi
    
    read -p "  Contrasena (min 4): " password
    [[ -z "$password" ]] && return
    
    read -p "  Limite conexiones (1-99): " limite
    [[ ! "$limite" =~ ^[0-9]+$ ]] && limite=1
    
    read -p "  Dias expiracion (1-365): " dias
    [[ ! "$dias" =~ ^[0-9]+$ ]] && dias=30
    
    local final=$(date "+%Y-%m-%d" -d "+$dias days")
    local pass_crypt=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
    
    useradd -e "$final" -M -s /bin/false -p "$pass_crypt" "$username" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo "$username $limite" >> "$DB_SSH"
        echo "$password" > "$SENHA_DIR/$username"
        echo "  OK: Usuario $username creado"
        echo "  Expira: $final"
    else
        echo "  ERROR: No se pudo crear"
    fi
}

borrar() {
    listar
    echo ""
    read -p "  ID a borrar: " id
    
    local user=$(sed -n "${id}p" "$DB_SSH" | cut -d' ' -f1)
    if [[ -z "$user" ]]; then
        echo "  ERROR: ID invalido"
        return
    fi
    
    echo ""
    echo "  Usuario: $user"
    read -p "  Confirmar borrado (s/N): " conf
    [[ "$conf" != "s" ]] && return
    
    echo ""
    echo "  Desconectando $user..."
    
    # Buscar el PID de dropbear para este usuario
    local target_pid=$(grep "Password auth succeeded for '$user'" "$AUTH_LOG" 2>/dev/null | tail -1 | grep -oP 'dropbear\[\K[0-9]+')
    
    if [[ -n "$target_pid" ]]; then
        echo "    Matando dropbear PID $target_pid"
        kill -9 "$target_pid" 2>/dev/null
        sleep 1
    fi
    
    # Matar cualquier proceso remanente
    pkill -9 -u "$user" 2>/dev/null
    
    # Eliminar del sistema
    userdel -f "$user" 2>/dev/null
    
    # Limpiar archivos
    sed -i "${id}d" "$DB_SSH" 2>/dev/null
    rm -f "$SENHA_DIR/$user" 2>/dev/null
    
    echo "  OK: Usuario $user eliminado"
}

case "$1" in
    list|ls)    listar ;;
    create|add) crear ;;
    delete|del) borrar ;;
    *)
        echo "ssh_manager - Gestion de usuarios SSH"
        echo "Uso: ssh_manager [list|create|delete]"
        ;;
esac
EOF

chmod +x /bin/ssh_manager