#!/bin/bash
# Ejemplos de conexión al proxy desde diferentes clientes

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  EJEMPLOS DE CONEXIÓN AL PROXY CON VALIDACIÓN HWID           ║"
echo "╚════════════════════════════════════════════════════════════════╝"

# NOTA: Primero crea un usuario con el CLI
# python3 user_cli.py create testuser pass123 --hwid "ABC123DEF456"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EJEMPLO 1: CURL - Conexión básica"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "# Usuario sin HWID:"
echo "curl -v -H \"X-User: testuser\" \\"
echo "     -H \"X-Pass: pass123\" \\"
echo "     -H \"X-Real-Host: 127.0.0.1:22\" \\"
echo "     http://127.0.0.1:80"
echo ""
echo "# Usuario con HWID:"
echo "curl -v -H \"X-User: testuser\" \\"
echo "     -H \"X-Pass: pass123\" \\"
echo "     -H \"X-HWID: ABC123DEF456\" \\"
echo "     -H \"X-Real-Host: 127.0.0.1:22\" \\"
echo "     http://127.0.0.1:80"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EJEMPLO 2: Python - Script de conexión"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'PYTHON_EXAMPLE'
#!/usr/bin/env python3
import socket

# Configuración
PROXY_HOST = '127.0.0.1'
PROXY_PORT = 80
USERNAME = 'testuser'
PASSWORD = 'pass123'
HWID = 'ABC123DEF456'
TARGET_HOST = '127.0.0.1:22'

# Construir headers HTTP
headers = f"""GET / HTTP/1.1\r
Host: {PROXY_HOST}:{PROXY_PORT}\r
X-User: {USERNAME}\r
X-Pass: {PASSWORD}\r
X-HWID: {HWID}\r
X-Real-Host: {TARGET_HOST}\r
Connection: upgrade\r
\r
""".encode()

# Conectar al proxy
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((PROXY_HOST, PROXY_PORT))

# Enviar autenticación
sock.sendall(headers)

# Recibir respuesta
response = sock.recv(1024)
print("Respuesta del proxy:")
print(response.decode('utf-8', errors='ignore'))

sock.close()
PYTHON_EXAMPLE
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EJEMPLO 3: Bash - Usando /dev/tcp"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'BASH_EXAMPLE'
#!/bin/bash

PROXY_HOST='127.0.0.1'
PROXY_PORT='80'
USERNAME='testuser'
PASSWORD='pass123'
HWID='ABC123DEF456'
TARGET='127.0.0.1:22'

# Conectar usando /dev/tcp
exec 3<>/dev/tcp/$PROXY_HOST/$PROXY_PORT

# Enviar request HTTP con headers de autenticación
cat >&3 << EOF
GET / HTTP/1.1
Host: $PROXY_HOST:$PROXY_PORT
X-User: $USERNAME
X-Pass: $PASSWORD
X-HWID: $HWID
X-Real-Host: $TARGET
Connection: upgrade

EOF

# Recibir respuesta
cat <&3

exec 3>&-
BASH_EXAMPLE
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EJEMPLO 4: Telnet / NetCat"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "# Usando nc (netcat):"
echo "(printf 'GET / HTTP/1.1\\r\\n'"
echo "printf 'X-User: testuser\\r\\n'"
echo "printf 'X-Pass: pass123\\r\\n'"
echo "printf 'X-HWID: ABC123DEF456\\r\\n'"
echo "printf 'X-Real-Host: 127.0.0.1:22\\r\\n'"
echo "printf '\\r\\n') | nc 127.0.0.1 80"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EJEMPLO 5: PowerShell (Windows)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'POWERSHELL_EXAMPLE'
$ProxyHost = "127.0.0.1"
$ProxyPort = 80
$Username = "testuser"
$Password = "pass123"
$HWID = "ABC123DEF456"
$TargetHost = "127.0.0.1:22"

$Headers = @{
    "X-User" = $Username
    "X-Pass" = $Password
    "X-HWID" = $HWID
    "X-Real-Host" = $TargetHost
}

$Uri = "http://$($ProxyHost):$ProxyPort"

try {
    $Response = Invoke-WebRequest -Uri $Uri -Headers $Headers -Method GET
    Write-Host "Conectado exitosamente!"
    Write-Host $Response.StatusCode
} catch {
    Write-Host "Error: $_"
}
POWERSHELL_EXAMPLE
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EJEMPLO 6: Java"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'JAVA_EXAMPLE'
import java.io.*;
import java.net.Socket;

public class ProxyClient {
    public static void main(String[] args) throws Exception {
        String proxyHost = "127.0.0.1";
        int proxyPort = 80;
        String username = "testuser";
        String password = "pass123";
        String hwid = "ABC123DEF456";
        String targetHost = "127.0.0.1:22";

        Socket socket = new Socket(proxyHost, proxyPort);
        PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
        BufferedReader in = new BufferedReader(
            new InputStreamReader(socket.getInputStream())
        );

        // Enviar headers
        out.println("GET / HTTP/1.1");
        out.println("Host: " + proxyHost + ":" + proxyPort);
        out.println("X-User: " + username);
        out.println("X-Pass: " + password);
        out.println("X-HWID: " + hwid);
        out.println("X-Real-Host: " + targetHost);
        out.println("");

        // Leer respuesta
        String line;
        while ((line = in.readLine()) != null) {
            System.out.println(line);
            if (line.isEmpty()) break;
        }

        socket.close();
    }
}
JAVA_EXAMPLE
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DEBUGGING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Si la conexión falla, verifica:"
echo ""
echo "1. El usuario existe:"
echo "   python3 user_cli.py list"
echo ""
echo "2. El proxy está corriendo:"
echo "   ps aux | grep wsproxy.py"
echo ""
echo "3. El puerto está abierto:"
echo "   netstat -tlnp | grep 80"
echo ""
echo "4. Los logs del proxy (deberías ver intentos de autenticación)"
echo ""
echo "5. El HWID es exacto (sin espacios ni diferencias de mayúsculas)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
