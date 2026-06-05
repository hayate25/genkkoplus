#!/bin/bash

# =============================================================
#  MODULO: Speed Test - GENKKOSSH
#  Uso: speedtest
# =============================================================

BOLD='\033[1m'
RESET='\033[0m'
LINE="-----------------------------------------------------------"

# --- Instalar Ookla oficial ----------------------------------

instalar_speedtest() {
    echo ""
    echo "  Instalando Speedtest CLI oficial de Ookla..."
    echo ""

    # Remover version pip que causa 403
    pip3 uninstall -y speedtest-cli &>/dev/null
    apt-get remove -y speedtest-cli &>/dev/null

    if command -v apt-get &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash &>/dev/null
        apt-get install -y speedtest &>/dev/null
    elif command -v yum &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | bash &>/dev/null
        yum install -y speedtest &>/dev/null
    fi

    # Aceptar licencia automaticamente
    echo "y" | speedtest --accept-license &>/dev/null
    echo "y" | speedtest --accept-gdpr &>/dev/null

    if ! command -v speedtest &>/dev/null; then
        echo "  ERROR: Instalacion fallo. Instala manualmente:"
        echo "    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash"
        echo "    apt-get install speedtest"
        echo ""
        read -p "  Presiona Enter para salir..."
        exit 1
    fi

    echo "  Speedtest (Ookla oficial) instalado correctamente."
    echo ""
}

# --- Obtener IP publica --------------------------------------

obtener_ip_publica() {
    local ip=""
    ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
    if [[ -z "$ip" ]]; then
        ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
    fi
    if [[ -z "$ip" ]]; then
        ip=$(curl -s --max-time 5 https://icanhazip.com 2>/dev/null)
    fi
    echo "${ip:-No disponible}"
}

# --- Ejecutar prueba -----------------------------------------

ejecutar_speedtest() {
    echo ""
    echo "$LINE"
    printf "${BOLD}  SPEED TEST - VPS${RESET}\n"
    echo "$LINE"
    echo ""

    echo -n "  Obteniendo IP publica... "
    IP_PUBLICA=$(obtener_ip_publica)
    echo "$IP_PUBLICA"
    echo ""

    echo "  Ejecutando prueba de velocidad, por favor espere..."
    echo "  (Esto puede tardar entre 30 y 60 segundos)"
    echo ""

    RESULTADO=$(speedtest 2>&1)
    EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "  ERROR: La prueba fallo."
        echo ""
        echo "  Detalle:"
        echo "$RESULTADO" | sed 's/^/    /'
        echo ""
        read -p "  Presiona Enter para continuar..."
        return 1
    fi

    # Parsear salida del binario oficial Ookla
    # Formato ejemplo:
    #   Server:     Nombre ISP - Ciudad (id = XXXX)
    #   ISP:        NombreISP
    #   Latency:    X.XX ms   (X.XX ms jitter)
    #   Download:   XX.XX Mbps (data used: X.X GB)
    #   Upload:     XX.XX Mbps (data used: X.X GB)
    PING=$(echo "$RESULTADO"     | grep -i "Latency:"  | awk '{print $2, $3}')
    DOWNLOAD=$(echo "$RESULTADO" | grep -i "Download:" | awk '{print $2, $3}')
    UPLOAD=$(echo "$RESULTADO"   | grep -i "Upload:"   | awk '{print $2, $3}')
    SERVIDOR=$(echo "$RESULTADO" | grep -i "Server:"   | sed 's/[[:space:]]*Server:[[:space:]]*//' | cut -c1-55)

    echo "$LINE"
    printf "  %-22s %s\n" "IP Publica:"        "$IP_PUBLICA"
    printf "  %-22s %s\n" "Ping / Latencia:"   "${PING:-No disponible}"
    printf "  %-22s %s\n" "Velocidad Bajada:"  "${DOWNLOAD:-No disponible}"
    printf "  %-22s %s\n" "Velocidad Subida:"  "${UPLOAD:-No disponible}"
    printf "  %-22s %s\n" "Servidor:"          "${SERVIDOR:-No disponible}"
    echo "$LINE"
    echo ""
}

# --- Menu ----------------------------------------------------

mostrar_menu() {
    clear
    echo ""
    echo "$LINE"
    printf "${BOLD}  MODULO: SPEED TEST${RESET}\n"
    echo "$LINE"
    echo ""
    echo "  [1] Iniciar Speed Test"
    echo "  [2] Reinstalar Speedtest (Ookla oficial)"
    echo "  [3] Volver al Menu Principal"
    echo "  [4] Salir"
    echo ""
    echo "$LINE"
    echo ""
    read -p "  Selecciona una opcion: " OPCION
    echo ""

    case $OPCION in
        1)
            ejecutar_speedtest
            read -p "  Presiona Enter para continuar..."
            mostrar_menu
            ;;
        2)
            apt-get remove -y speedtest &>/dev/null
            instalar_speedtest
            read -p "  Presiona Enter para continuar..."
            mostrar_menu
            ;;
        3)
            if command -v menu &>/dev/null; then
                menu
            else
                echo "  Comando 'menu' no encontrado."
                read -p "  Presiona Enter para salir..."
                exit 0
            fi
            ;;
        4)
            exit 0
            ;;
        *)
            echo "  Opcion incorrecta."
            sleep 1
            mostrar_menu
            ;;
    esac
}

# =============================================================
#  INICIO
# =============================================================

if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# Si no esta instalado el binario oficial de Ookla, instalar
if ! command -v speedtest &>/dev/null; then
    instalar_speedtest
fi

mostrar_menu

