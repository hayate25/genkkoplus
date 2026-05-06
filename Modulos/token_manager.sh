#!/bin/bash
# token_manager - Gestion de usuarios TOKEN (token + contraseña)
# Sin colores - Sin OpenVPN - Sin HTTP Custom

DB_TOKEN="/etc/SSHPlus/token.db"
SENHA_DIR="/etc/SSHPlus/senha"

mkdir -p /etc/SSHPlus
mkdir -p "$SENHA_DIR"
touch "$DB_TOKEN"

# Funcion: Listar usuarios TOKEN
listar() {
    echo "=========================================="
    echo "  USUARIOS TOKEN"
    echo "=========================================="
    if [[ ! -s "$DB_TOKEN" ]]; then
        echo "  No hay usuarios TOKEN"
        return
    fi
    echo "  ID | NOMBRE | TOKEN | EXPIRA | DIAS"
    echo "  ---|--------|-------|----------|-----"
    local i=1
    while IFS='|' read -r nombre token pass exp; do
        local exp_sec=$(date +%s -d "$exp" 2>/dev/null)
        local now_sec=$(date +%s)
        local dias=$(( (exp_sec - now_sec) / 86400 ))
        [[ $dias -lt 0 ]] && dias=0
        echo "  $i | $nombre | $token | $exp | ${dias}d"
        i=$((i+1))
    done < "$DB_TOKEN"
    echo "=========================================="
}

# Funcion: Crear usuario TOKEN
crear() {
    echo "=========================================="
    echo "  CREAR USUARIO TOKEN"
    echo "=========================================="
    
    read -p "  Nombre identificador: " nombre
    [[ -z "$nombre" ]] && return
    
    read -p "  TOKEN: " token
    token=$(echo "$token" | tr -d ' ')
    [[ -z "$token" ]] && return
    
    if grep -q "|$token|" "$DB_TOKEN"; then
        echo "  ERROR: TOKEN ya existe"
        return
    fi
    
    read -p "  Contrasena SSH: " password
    [[ -z "$password" ]] && return
    
    read -p "  Dias expiracion (1-365): " dias
    [[ ! "$dias" =~ ^[0-9]+$ ]] && dias=30
    
    local final=$(date "+%Y-%m-%d" -d "+$dias days")
    local pass_crypt=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
    
    useradd -e "$final" -M -s /bin/false -p "$pass_crypt" "$token" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo "$nombre|$token|$password|$final" >> "$DB_TOKEN"
        echo "$password" > "$SENHA_DIR/$token"
        echo "  OK: TOKEN $nombre creado"
        echo "  Expira: $final"
    else
        echo "  ERROR: No se pudo crear"
    fi
}

# Funcion: Borrar usuario TOKEN
borrar() {
    listar
    read -p "  ID a borrar: " id
    
    local linea=$(sed -n "${id}p" "$DB_TOKEN")
    local nombre=$(echo "$linea" | cut -d'|' -f1)
    local token=$(echo "$linea" | cut -d'|' -f2)
    
    if [[ -z "$token" ]]; then
        echo "  ERROR: ID invalido"
        return
    fi
    
    read -p "  Borrar $nombre? (s/n): " conf
    [[ "$conf" != "s" ]] && return
    
    pkill -u "$token" 2>/dev/null
    userdel -f "$token" 2>/dev/null
    sed -i "${id}d" "$DB_TOKEN"
    rm -f "$SENHA_DIR/$token"
    echo "  OK: $nombre borrado"
}

# Menu principal
case "$1" in
    list|ls)    listar ;;
    create|add) crear ;;
    delete|del) borrar ;;
    *)
        echo "token_manager - Gestion de usuarios TOKEN"
        echo "Uso: token_manager [list|create|delete]"
        ;;
esac