# Sistema de Gestión de Usuarios con HWID - SSHPLUS

## 📋 Descripción

Sistema de gestión de usuarios con validación de **Hardware ID (HWID)** integrado en los proxies de SSHPLUS. Preserva toda la funcionalidad existente y agrega:

- ✅ Creación de usuarios con contraseña hasheada
- ✅ Validación de HWID (Hardware ID) por usuario
- ✅ Sistema de conexiones y logs
- ✅ Activación/desactivación de usuarios
- ✅ CLI para gestión de usuarios
- ✅ Soporte backward-compatible con sistema antiguo

## 🏗️ Arquitectura

```
Modulos/
├── user_manager.py      # Core del sistema de usuarios
├── user_cli.py          # Interfaz CLI para gestión
├── wsproxy.py           # Proxy WebSocket con autenticación integrada
├── open.py              # Proxy SOCKS (sin cambios)
├── proxy.py             # Proxy HTTP (sin cambios)
└── users.json           # Base de datos de usuarios (generado)
```

## 🚀 Uso

### 1. Crear Usuarios

```bash
# Usuario sin HWID
python3 user_cli.py create admin password123

# Usuario con HWID
python3 user_cli.py create user1 pass456 --hwid "ABC123DEF456"
```

### 2. Listar Usuarios

```bash
python3 user_cli.py list
```

**Output:**
```
[+] USUARIOS REGISTRADOS:

Usuario               HWID                 Conexiones      Último Login
─────────────────────────────────────────────────────────────────────────
✓ admin               NO REGISTRADO        0               Nunca
✓ user1               REGISTRADO           5               2024-01-15T10:30:45
```

### 3. Registrar HWID para Usuario

```bash
python3 user_cli.py register-hwid user1 "NEW_HWID_VALUE"
```

### 4. Información de Usuario

```bash
python3 user_cli.py info user1
```

### 5. Desactivar Usuario

```bash
python3 user_cli.py toggle deactivate user1
python3 user_cli.py toggle activate user1
```

### 6. Eliminar Usuario

```bash
# Con confirmación
python3 user_cli.py delete user1

# Sin confirmación
python3 user_cli.py delete user1 -f
```

## 🔐 Autenticación en el Proxy

### Headers HTTP para Autenticación

| Header | Descripción | Ejemplo | Requerido |
|--------|-------------|---------|----------|
| `X-User` | Nombre de usuario | `admin` | ✅ |
| `X-Pass` | Contraseña | `password123` | ✅ |
| `X-HWID` | Hardware ID | `ABC123DEF456` | ❓ Depende del usuario |
| `X-Real-Host` | Host destino | `127.0.0.1:22` | ✅ |

### Ejemplo de Conexión

```bash
# Usuario sin HWID
curl -H "X-User: admin" \
     -H "X-Pass: password123" \
     -H "X-Real-Host: 127.0.0.1:22" \
     http://proxy:80

# Usuario con HWID
curl -H "X-User: user1" \
     -H "X-Pass: pass456" \
     -H "X-HWID: ABC123DEF456" \
     -H "X-Real-Host: 127.0.0.1:22" \
     http://proxy:80
```

## ⚙️ Configuración

### Habilitar/Deshabilitar Sistema de Usuarios

En `wsproxy.py`:

```python
USE_USER_SYSTEM = True   # Usar nuevo sistema de usuarios
USE_USER_SYSTEM = False  # Usar sistema antiguo (PASS global)
```

### Cambiar Archivo de Base de Datos

En `user_manager.py`:

```python
user_manager = UserManager(db_file='users.json')  # Archivo custom
```

## 📊 Estructura de Datos (users.json)

```json
{
  "admin": {
    "username": "admin",
    "password_hash": "5e884898da28047151d0e56f8dc62927...",
    "hwid": "ABC123DEF456",
    "created_at": "2024-01-15T09:00:00.000000",
    "last_login": "2024-01-15T10:30:45.000000",
    "active": true,
    "connections": 5
  }
}
```

## 🔒 Seguridad

- **Contraseñas**: Almacenadas como hash SHA256 (no reversible)
- **HWID**: Validación exacta de coincidencia
- **Concurrencia**: Thread-safe con locks
- **Logging**: Registro de intentos de autenticación

## 📝 Logs del Proxy

```
Connection: 192.168.1.100:12345 - USER:admin HWID:OK - CONNECT 127.0.0.1:22
Connection: 192.168.1.101:12346 - AUTH_FAILED:HWID no coincide
Connection: 192.168.1.102:12347 - AUTH_FAILED:Usuario no existe
```

## ✨ Características Principales

1. **Backward Compatible**: El sistema antiguo sigue funcionando
2. **No Invasivo**: Los proxies `open.py` y `proxy.py` sin cambios
3. **Thread-Safe**: Soporte para múltiples conexiones simultáneas
4. **Auditable**: Registro completo de conexiones y eventos
5. **Flexible**: Usuarios pueden tener o no HWID registrado

## 🔧 Próximas Mejoras (Opcional)

- [ ] Soporte para múltiples HWID por usuario
- [ ] Historial de conexiones detallado
- [ ] Límites de tasa de conexión por usuario
- [ ] Expiración de sesiones
- [ ] Encriptación de base de datos
- [ ] API REST para gestión remota

---

**Sistema diseñado y desarrollado para SSHPLUS - 2024**
