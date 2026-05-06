#!/usr/bin/env python3
# encoding: utf-8
"""
Script de demostración del sistema de gestión de usuarios con HWID
Muestra cómo funciona la autenticación y validación de HWID
"""

from user_manager import user_manager
import json

def print_header(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def demo():
    # Limpiar usuarios previos
    for user in list(user_manager.users.keys()):
        user_manager.delete_user(user)

    print_header("1. CREAR USUARIOS DE PRUEBA")

    # Crear usuarios
    print("[+] Creando usuario 'admin' sin HWID...")
    success, msg = user_manager.create_user('admin', 'admin123')
    print(f"    Resultado: {msg}\n")

    print("[+] Creando usuario 'user1' con HWID...")
    success, msg = user_manager.create_user('user1', 'pass123', hwid='HWID-LAPTOP-001')
    print(f"    Resultado: {msg}\n")

    print("[+] Creando usuario 'user2' con HWID diferente...")
    success, msg = user_manager.create_user('user2', 'pass456', hwid='HWID-LAPTOP-002')
    print(f"    Resultado: {msg}\n")

    # Mostrar usuarios
    print_header("2. LISTAR USUARIOS")

    users = user_manager.list_users()
    print(f"Total de usuarios: {len(users)}\n")
    for user in users:
        print(f"  • {user['username']:<15} HWID: {user['hwid']:<20} Activo: {user['active']}")
    print()

    # Pruebas de autenticación
    print_header("3. PRUEBAS DE AUTENTICACIÓN")

    print("[TEST 1] Autenticar 'admin' con contraseña correcta (sin HWID)")
    success, msg = user_manager.authenticate('admin', 'admin123')
    print(f"  Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    print("[TEST 2] Autenticar 'admin' con contraseña incorrecta")
    success, msg = user_manager.authenticate('admin', 'wrongpass')
    print(f"  Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    print("[TEST 3] Autenticar 'user1' con contraseña correcta y HWID correcto")
    success, msg = user_manager.authenticate('user1', 'pass123', hwid='HWID-LAPTOP-001')
    print(f"  Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    print("[TEST 4] Autenticar 'user1' con contraseña correcta pero HWID incorrecto")
    success, msg = user_manager.authenticate('user1', 'pass123', hwid='HWID-WRONG')
    print(f"  Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    print("[TEST 5] Autenticar 'user1' sin proporcionar HWID (requerido)")
    success, msg = user_manager.authenticate('user1', 'pass123')
    print(f"  Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    print("[TEST 6] Autenticar usuario inexistente")
    success, msg = user_manager.authenticate('nonexistent', 'pass')
    print(f"  Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    # Registrar HWID
    print_header("4. REGISTRAR HWID PARA USUARIO")

    print("[+] Registrando HWID para 'admin'...")
    success, msg = user_manager.register_hwid('admin', 'HWID-DESKTOP-001')
    print(f"    Resultado: {msg}\n")

    print("[+] Intentando autenticar 'admin' con HWID correcto...")
    success, msg = user_manager.authenticate('admin', 'admin123', hwid='HWID-DESKTOP-001')
    print(f"    Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    # Información de usuario
    print_header("5. INFORMACIÓN DETALLADA DE USUARIO")

    info = user_manager.get_user_info('user1')
    if info:
        print(f"Usuario: {info['username']}")
        print(f"  - HWID: {info['hwid']}")
        print(f"  - Estado: {'Activo' if info['active'] else 'Inactivo'}")
        print(f"  - Conexiones: {info['connections']}")
        print(f"  - Creado: {info['created_at']}")
        print(f"  - Último Login: {info['last_login']}")
        print()

    # Desactivar usuario
    print_header("6. DESACTIVAR USUARIO")

    print("[+] Desactivando usuario 'user2'...")
    success, msg = user_manager.toggle_user_active('user2', False)
    print(f"    {msg}\n")

    print("[+] Intentando autenticar usuario desactivo 'user2'...")
    success, msg = user_manager.authenticate('user2', 'pass456', hwid='HWID-LAPTOP-002')
    print(f"    Resultado: {'✓ EXITOSO' if success else '✗ FALLIDO'} - {msg}\n")

    # Mostrar base de datos
    print_header("7. CONTENIDO DE LA BASE DE DATOS (users.json)")

    try:
        with open('users.json', 'r') as f:
            data = json.load(f)
            print(json.dumps(data, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"[-] Error al leer base de datos: {e}")

    print("\n" + "="*60)
    print("  DEMOSTRACIÓN COMPLETADA")
    print("="*60 + "\n")

if __name__ == '__main__':
    demo()
