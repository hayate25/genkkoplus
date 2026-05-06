#!/usr/bin/env python3
# encoding: utf-8
import sys
import argparse
from user_manager import user_manager

def print_banner():
    print("""
    ╔═══════════════════════════════════════╗
    ║   SSHPLUS - User Management System    ║
    ║           with HWID Support           ║
    ╚═══════════════════════════════════════╝
    """)

def cmd_create(args):
    """Crea un nuevo usuario"""
    success, msg = user_manager.create_user(args.username, args.password, args.hwid)
    status = "[+]" if success else "[-]"
    print(f"{status} {msg}")
    return success

def cmd_list(args):
    """Lista todos los usuarios"""
    users = user_manager.list_users()
    if not users:
        print("[-] No hay usuarios registrados")
        return False

    print("\n[+] USUARIOS REGISTRADOS:\n")
    print(f"{'Usuario':<20} {'HWID':<20} {'Conexiones':<15} {'Último Login':<25}")
    print("-" * 80)

    for user in users:
        hwid_status = user['hwid']
        last_login = user['last_login'] if user['last_login'] else 'Nunca'
        status_marker = "✓" if user['active'] else "✗"

        print(f"{status_marker} {user['username']:<18} {hwid_status:<20} {user['connections']:<15} {last_login:<25}")

    print()
    return True

def cmd_register_hwid(args):
    """Registra un HWID para un usuario"""
    success, msg = user_manager.register_hwid(args.username, args.hwid)
    status = "[+]" if success else "[-]"
    print(f"{status} {msg}")
    return success

def cmd_info(args):
    """Muestra información de un usuario"""
    user = user_manager.get_user_info(args.username)
    if not user:
        print(f"[-] Usuario '{args.username}' no existe")
        return False

    print(f"\n[+] INFORMACIÓN DEL USUARIO:\n")
    print(f"    Usuario:        {user['username']}")
    print(f"    HWID:           {user['hwid'] if user['hwid'] else 'No registrado'}")
    print(f"    Estado:         {'Activo' if user['active'] else 'Inactivo'}")
    print(f"    Conexiones:     {user['connections']}")
    print(f"    Creado:         {user['created_at']}")
    print(f"    Último Login:   {user['last_login'] if user['last_login'] else 'Nunca'}")
    print()
    return True

def cmd_delete(args):
    """Elimina un usuario"""
    if not args.force:
        confirm = input(f"¿Estás seguro de que quieres eliminar a '{args.username}'? (s/n): ")
        if confirm.lower() != 's':
            print("[-] Operación cancelada")
            return False

    success, msg = user_manager.delete_user(args.username)
    status = "[+]" if success else "[-]"
    print(f"{status} {msg}")
    return success

def cmd_toggle(args):
    """Activa o desactiva un usuario"""
    active = args.action == 'activate'
    success, msg = user_manager.toggle_user_active(args.username, active)
    status = "[+]" if success else "[-]"
    print(f"{status} {msg}")
    return success

def main():
    print_banner()

    parser = argparse.ArgumentParser(description='SSHPLUS User Management System with HWID Support')
    subparsers = parser.add_subparsers(dest='command', help='Comandos disponibles')

    # Comando: create
    parser_create = subparsers.add_parser('create', help='Crea un nuevo usuario')
    parser_create.add_argument('username', help='Nombre de usuario')
    parser_create.add_argument('password', help='Contraseña')
    parser_create.add_argument('--hwid', help='Hardware ID (opcional)', default=None)
    parser_create.set_defaults(func=cmd_create)

    # Comando: list
    parser_list = subparsers.add_parser('list', help='Lista todos los usuarios')
    parser_list.set_defaults(func=cmd_list)

    # Comando: register-hwid
    parser_hwid = subparsers.add_parser('register-hwid', help='Registra HWID para un usuario')
    parser_hwid.add_argument('username', help='Nombre de usuario')
    parser_hwid.add_argument('hwid', help='Hardware ID')
    parser_hwid.set_defaults(func=cmd_register_hwid)

    # Comando: info
    parser_info = subparsers.add_parser('info', help='Muestra información del usuario')
    parser_info.add_argument('username', help='Nombre de usuario')
    parser_info.set_defaults(func=cmd_info)

    # Comando: delete
    parser_delete = subparsers.add_parser('delete', help='Elimina un usuario')
    parser_delete.add_argument('username', help='Nombre de usuario')
    parser_delete.add_argument('-f', '--force', action='store_true', help='Elimina sin confirmar')
    parser_delete.set_defaults(func=cmd_delete)

    # Comando: toggle
    parser_toggle = subparsers.add_parser('toggle', help='Activa/desactiva usuario')
    parser_toggle.add_argument('action', choices=['activate', 'deactivate'], help='Acción a realizar')
    parser_toggle.add_argument('username', help='Nombre de usuario')
    parser_toggle.set_defaults(func=cmd_toggle)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    if hasattr(args, 'func'):
        args.func(args)

if __name__ == '__main__':
    main()
