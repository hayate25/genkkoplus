#!/usr/bin/env python3
# GUÍA RÁPIDA - Sistema de Usuarios con HWID

"""
╔════════════════════════════════════════════════════════════════╗
║         GUÍA RÁPIDA - Sistema de Gestión de Usuarios          ║
║                    con Validación HWID                        ║
╚════════════════════════════════════════════════════════════════╝

📦 ARCHIVOS NUEVOS AGREGADOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. user_manager.py      → Core del sistema (gestión de usuarios)
2. user_cli.py          → Interfaz de línea de comandos
3. test_user_system.py  → Script de prueba/demostración
4. README.md            → Documentación completa
5. QUICKSTART.txt       → Este archivo


🚀 INICIO RÁPIDO (3 PASOS):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PASO 1: CREAR TU PRIMER USUARIO
───────────────────────────────
$ python3 user_cli.py create miusuario micontraseña --hwid "MI-HWID-001"

Ejemplo:
$ python3 user_cli.py create admin admin123 --hwid "ABC123DEF456"


PASO 2: VERIFICAR QUE EL USUARIO FUE CREADO
─────────────────────────────────────────────
$ python3 user_cli.py list

Deberías ver algo como:
    ✓ admin               REGISTRADO           0               Nunca


PASO 3: USAR EL PROXY CON AUTENTICACIÓN
─────────────────────────────────────────
$ python3 wsproxy.py -b 0.0.0.0 -p 80

Luego conectarte desde cliente:
    curl -H "X-User: admin" \
         -H "X-Pass: admin123" \
         -H "X-HWID: ABC123DEF456" \
         -H "X-Real-Host: 127.0.0.1:22" \
         http://localhost:80


📋 COMANDOS DISPONIBLES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Crear usuario:
  $ python3 user_cli.py create <usuario> <contraseña> [--hwid <hwid>]

Listar usuarios:
  $ python3 user_cli.py list

Ver info de usuario:
  $ python3 user_cli.py info <usuario>

Registrar HWID:
  $ python3 user_cli.py register-hwid <usuario> <hwid>

Desactivar usuario:
  $ python3 user_cli.py toggle deactivate <usuario>

Activar usuario:
  $ python3 user_cli.py toggle activate <usuario>

Eliminar usuario:
  $ python3 user_cli.py delete <usuario> [-f]


🔐 FLUJO DE AUTENTICACIÓN:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cliente envía headers HTTP:
    ┌─────────────────────────────────────────┐
    │ X-User: <nombre_usuario>                │ ← Requerido
    │ X-Pass: <contraseña>                    │ ← Requerido
    │ X-HWID: <hardware_id>                   │ ← Depende si usuario tiene HWID
    │ X-Real-Host: <destino:puerto>           │ ← Requerido
    └─────────────────────────────────────────┘
            ↓
    Proxy valida usuario y contraseña
            ↓
    ¿Tiene HWID registrado? → SÍ: Validar HWID
                          → NO: Conectar
            ↓
    ✓ Autenticado → Conectar a destino
    ✗ Rechazado → Error 401/403


💡 EJEMPLOS DE USO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ejemplo 1: Usuario sin HWID
──────────────────────────
$ python3 user_cli.py create user1 password123
$ python3 user_cli.py list

Conexión:
    curl -H "X-User: user1" \
         -H "X-Pass: password123" \
         -H "X-Real-Host: 127.0.0.1:22" \
         http://localhost:80


Ejemplo 2: Usuario con HWID obligatorio
────────────────────────────────────────
$ python3 user_cli.py create user2 pass456 --hwid "LAPTOP-XYZ789"
$ python3 user_cli.py list

Conexión (correcta):
    curl -H "X-User: user2" \
         -H "X-Pass: pass456" \
         -H "X-HWID: LAPTOP-XYZ789" \
         -H "X-Real-Host: 127.0.0.1:22" \
         http://localhost:80

Conexión (rechazada - HWID incorrecto):
    curl -H "X-User: user2" \
         -H "X-Pass: pass456" \
         -H "X-HWID: WRONG-HWID" \
         -H "X-Real-Host: 127.0.0.1:22" \
         http://localhost:80
    → 401 Unauthorized


Ejemplo 3: Agregar HWID a usuario existente
────────────────────────────────────────────
$ python3 user_cli.py register-hwid user1 "DESKTOP-ABC123"

Ahora user1 necesitará ese HWID para conectar.


⚙️ CONFIGURACIÓN IMPORTANTE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

En wsproxy.py, línea 16:

USE_USER_SYSTEM = True   # ← Activar nuevo sistema (recomendado)
# USE_USER_SYSTEM = False  # ← Desactivar y volver a sistema antiguo

Para cambiar puerto del proxy:
    $ python3 wsproxy.py -p 8080

Para cambiar IP de escucha:
    $ python3 wsproxy.py -b 192.168.1.10 -p 80


🧪 PROBAR EL SISTEMA:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ejecutar pruebas completas:
    $ python3 test_user_system.py

Esto hará pruebas de:
    ✓ Creación de usuarios
    ✓ Autenticación correcta/incorrecta
    ✓ Validación de HWID
    ✓ Usuarios sin HWID
    ✓ Desactivación de usuarios
    Y más...


📁 BASE DE DATOS (users.json):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Se genera automáticamente en el mismo directorio.

Estructura:
{
  "usuario1": {
    "username": "usuario1",
    "password_hash": "abc123...",  ← SHA256 (no reversible)
    "hwid": "HWID-001",             ← Validación obligatoria si existe
    "created_at": "2024-01-15...",
    "last_login": "2024-01-15...",
    "active": true,
    "connections": 5
  }
}


✅ VERIFICACIÓN CHECKLIST:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] user_manager.py existe y funciona
[ ] user_cli.py se ejecuta sin errores
[ ] Puedo crear usuarios: user_cli.py create test pass123
[ ] Puedo listar usuarios: user_cli.py list
[ ] wsproxy.py importa user_manager correctamente
[ ] Puedo iniciar proxy: python3 wsproxy.py
[ ] users.json se crea automáticamente
[ ] Pruebas pasan: python3 test_user_system.py


⚠️ NOTAS IMPORTANTES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Las contraseñas se almacenan como SHA256 (no reversibles)
2. Los HWID se almacenan en texto plano (para validación exacta)
3. El sistema es thread-safe para múltiples conexiones
4. Los logs se imprimen en consola cuando conectan usuarios
5. La funcionalidad antigua (PASS global) se puede activar si es necesario
6. No requiere base de datos externa (usa JSON)


🆘 SOLUCIÓN DE PROBLEMAS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Problema: "ImportError: No module named 'user_manager'"
Solución: Asegurate que user_manager.py está en el mismo directorio

Problema: "Permission denied" al crear users.json
Solución: Verifica permisos: chmod 755 Modulos/

Problema: El proxy no se inicia
Solución: Verifica que el puerto no esté en uso: netstat -an | grep :80

Problema: Conexión rechazada con "401 Unauthorized"
Solución: Verifica que el usuario existe: user_cli.py list


📞 PRÓXIMOS PASOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Crear tus usuarios
2. Iniciar el proxy
3. Conectarte desde tu cliente con los headers correctos
4. Monitorear logs de conexión
5. Ajustar HWID según sea necesario


═══════════════════════════════════════════════════════════════════

Documentación completa disponible en: README.md

═══════════════════════════════════════════════════════════════════
"""

print(__doc__)
