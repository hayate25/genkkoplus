cat > /bin/mudardata << 'EOF'
#!/bin/bash
# mudardata - Módulo para editar fecha de vencimiento de usuarios
# Compatible con sistema SSHPlus (IDs dinámicos)
# Versión sin colores para compatibilidad con bots

clear
echo "=============================================="
echo "         EDITAR FECHA DE VENCIMIENTO"
echo "=============================================="
echo ""

database="/root/usuarios.db"

if [ ! -f "$database" ]; then
    echo "ERROR: Archivo $database NO encontrado"
    echo ""
    exit 1
fi

# Función para obtener usuario por ID
get_user_by_id() {
    local id="$1"
    local current=1
    while IFS=' ' read -r user limite; do
        if [[ $current -eq $id ]]; then
            echo "$user"
            return
        fi
        current=$((current+1))
    done < "$database"
}

# Listar usuarios con IDs y sus fechas de vencimiento
echo "LISTA DE USUARIOS Y FECHAS DE VENCIMIENTO:"
echo "--------------------------------------------"
echo ""

id=0
while IFS=' ' read -r user limit; do
    [[ -z "$user" ]] && continue
    
    # Verificar que el usuario existe en el sistema
    if ! grep -q "^$user:" /etc/passwd; then
        continue
    fi
    
    id=$((id + 1))
    
    # Obtener fecha de expiración
    expire="$(chage -l "$user" 2>/dev/null | grep -E "Account expires" | cut -d ':' -f2- | sed 's/^[[:space:]]*//')"
    
    if [[ -z "$expire" ]] || [[ "$expire" == "never" ]]; then
        fecha="00/00/0000"
        estado="SIN FECHA"
    else
        fecha=$(date -d "$expire" '+%d/%m/%Y' 2>/dev/null)
        if [ $? -ne 0 ]; then
            fecha="ERROR"
            estado="ERROR"
        else
            databr=$(date -d "$expire" +"%Y%m%d" 2>/dev/null)
            hoje=$(date -d today +"%Y%m%d")
            
            if [ "$hoje" -ge "$databr" ]; then
                estado="VENCIDO"
            else
                estado="VALIDO"
            fi
        fi
    fi
    
    # Formato: [ID] - Usuario | Fecha | Estado
    printf "[%02d] - %-20s | %-10s | %s\n" "$id" "$user" "$fecha" "$estado"
done < "$database"

# Si no hay usuarios
if [[ $id -eq 0 ]]; then
    echo "No hay usuarios registrados en el sistema."
    exit 1
fi

echo ""
echo "--------------------------------------------"
echo "Total de usuarios: $id"
echo ""

# Seleccionar usuario por ID
echo -n "Seleccione un usuario por ID [1-$id]: "
read option

# Validar entrada
if [[ -z $option ]]; then
    echo ""
    echo "ERROR: Debe seleccionar un ID"
    echo ""
    exit 1
fi

# Validar que sea número
if ! [[ "$option" =~ ^[0-9]+$ ]]; then
    echo ""
    echo "ERROR: Debe ingresar un número válido"
    echo ""
    exit 1
fi

# Validar rango
if [[ $option -lt 1 ]] || [[ $option -gt $id ]]; then
    echo ""
    echo "ERROR: ID fuera de rango [1-$id]"
    echo ""
    exit 1
fi

# Obtener usuario por ID
usuario=$(get_user_by_id "$option")

if [[ -z $usuario ]]; then
    echo ""
    echo "ERROR: Usuario no encontrado"
    echo ""
    exit 1
fi

# Verificar que el usuario existe en el sistema
if ! grep -q "^$usuario:" /etc/passwd; then
    echo ""
    echo "ERROR: El usuario $usuario no existe en el sistema"
    echo ""
    exit 1
fi

# Mostrar fecha actual
expire_actual="$(chage -l "$usuario" 2>/dev/null | grep -E "Account expires" | cut -d ':' -f2- | sed 's/^[[:space:]]*//')"
if [[ "$expire_actual" == "never" ]] || [[ -z "$expire_actual" ]]; then
    fecha_actual="Sin fecha de vencimiento"
else
    fecha_actual=$(date -d "$expire_actual" '+%d/%m/%Y' 2>/dev/null)
fi

echo ""
echo "Usuario seleccionado: $usuario"
echo "Vencimiento actual: $fecha_actual"
echo ""

# Instrucciones
echo "FORMATOS ACEPTADOS:"
echo "  - Fecha: DD/MM/AAAA (Ejemplo: 21/04/2024)"
echo "  - Dias:  30 (30 dias a partir de hoy)"
echo ""

# Solicitar nueva fecha o días
echo -n "Nueva fecha o dias para el usuario $usuario: "
read inputdate

# Validar entrada
if [[ -z $inputdate ]]; then
    echo ""
    echo "ERROR: Debe ingresar una fecha o número de días"
    echo ""
    exit 1
fi

# Determinar si es fecha (contiene /) o días (solo números)
if [[ "$inputdate" =~ "/" ]]; then
    # Es una fecha en formato DD/MM/AAAA
    sysdate="$(echo "$inputdate" | awk -v FS=/ -v OFS=- '{print $3,$2,$1}')"
    udata="$inputdate"
else
    # Son días
    if ! [[ "$inputdate" =~ ^[0-9]+$ ]]; then
        echo ""
        echo "ERROR: Debe ingresar un número de días válido"
        echo ""
        exit 1
    fi
    
    if [[ $inputdate -lt 1 ]]; then
        echo ""
        echo "ERROR: Los días deben ser mayor que 0"
        echo ""
        exit 1
    fi
    
    # Calcular fecha sumando días
    udata=$(date "+%d/%m/%Y" -d "+$inputdate days")
    sysdate="$(echo "$udata" | awk -v FS=/ -v OFS=- '{print $3,$2,$1}')"
fi

# Validar que la fecha es válida
if ! date "+%Y-%m-%d" -d "$sysdate" > /dev/null 2>&1; then
    echo ""
    echo "ERROR: Fecha inválida o inexistente"
    echo "Use el formato DD/MM/AAAA (Ejemplo: 21/04/2024)"
    echo "O ingrese un número de días (Ejemplo: 30)"
    echo ""
    exit 1
fi

# Verificar que no sea fecha pasada
today="$(date -d today +"%Y%m%d")"
timemachine="$(date -d "$sysdate" +"%Y%m%d")"

if [ "$today" -gt "$timemachine" ]; then
    echo ""
    echo "ERROR: La fecha ingresada es anterior a hoy"
    echo "Debe ingresar una fecha futura"
    echo ""
    exit 1
fi

# Aplicar nueva fecha de vencimiento
chage -E "$sysdate" "$usuario" 2>/dev/null

if [ $? -eq 0 ]; then
    echo ""
    echo "=============================================="
    echo "  FECHA DE VENCIMIENTO ACTUALIZADA"
    echo "  Usuario: $usuario"
    echo "  Fecha anterior: $fecha_actual"
    echo "  Nueva fecha: $udata"
    if [[ "$inputdate" =~ ^[0-9]+$ ]]; then
        echo "  Días agregados: $inputdate"
    fi
    echo "=============================================="
    echo ""
else
    echo ""
    echo "ERROR: No se pudo actualizar la fecha de vencimiento"
    echo ""
    exit 1
fi

sleep 3
exit 0
EOF

chmod +x /bin/mudardata
echo "✅ mudardata regenerado correctamente"