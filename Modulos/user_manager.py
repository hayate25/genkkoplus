#!/usr/bin/env python3
# encoding: utf-8
import json
import hashlib
import os
from datetime import datetime
import threading

class UserManager:
    def __init__(self, db_file='users.json'):
        self.db_file = db_file
        self.users = {}
        self.lock = threading.Lock()
        self.load_users()

    def load_users(self):
        """Carga usuarios desde archivo JSON"""
        try:
            if os.path.exists(self.db_file):
                with open(self.db_file, 'r') as f:
                    self.users = json.load(f)
        except Exception as e:
            print(f"[USER_MANAGER] Error loading users: {e}")
            self.users = {}

    def save_users(self):
        """Guarda usuarios en archivo JSON"""
        try:
            with open(self.db_file, 'w') as f:
                json.dump(self.users, f, indent=2)
        except Exception as e:
            print(f"[USER_MANAGER] Error saving users: {e}")

    def create_user(self, username, password, hwid=None):
        """Crea un nuevo usuario"""
        self.lock.acquire()
        try:
            if username in self.users:
                return False, "Usuario ya existe"

            user = {
                'username': username,
                'password_hash': self._hash_password(password),
                'hwid': hwid,
                'created_at': datetime.now().isoformat(),
                'last_login': None,
                'active': True,
                'connections': 0
            }

            self.users[username] = user
            self.save_users()
            return True, f"Usuario '{username}' creado exitosamente"
        finally:
            self.lock.release()

    def authenticate(self, username, password, hwid=None):
        """Autentica usuario por contraseña y opcionalmente HWID"""
        self.lock.acquire()
        try:
            if username not in self.users:
                return False, "Usuario no existe"

            user = self.users[username]

            if not user['active']:
                return False, "Usuario inactivo"

            # Verificar contraseña
            if not self._verify_password(password, user['password_hash']):
                return False, "Contraseña incorrecta"

            # Verificar HWID si está registrado
            if user['hwid'] is not None:
                if hwid is None:
                    return False, "HWID requerido"
                if hwid != user['hwid']:
                    return False, "HWID no coincide"

            # Actualizar último login
            user['last_login'] = datetime.now().isoformat()
            user['connections'] += 1
            self.save_users()

            return True, "Autenticación exitosa"
        finally:
            self.lock.release()

    def register_hwid(self, username, hwid):
        """Registra HWID para un usuario existente"""
        self.lock.acquire()
        try:
            if username not in self.users:
                return False, "Usuario no existe"

            self.users[username]['hwid'] = hwid
            self.save_users()
            return True, f"HWID registrado para '{username}'"
        finally:
            self.lock.release()

    def get_user_info(self, username):
        """Obtiene información del usuario"""
        self.lock.acquire()
        try:
            if username not in self.users:
                return None
            return self.users[username].copy()
        finally:
            self.lock.release()

    def delete_user(self, username):
        """Elimina un usuario"""
        self.lock.acquire()
        try:
            if username in self.users:
                del self.users[username]
                self.save_users()
                return True, f"Usuario '{username}' eliminado"
            return False, "Usuario no existe"
        finally:
            self.lock.release()

    def list_users(self):
        """Lista todos los usuarios (sin mostrar hashes)"""
        self.lock.acquire()
        try:
            users_list = []
            for username, user in self.users.items():
                info = {
                    'username': user['username'],
                    'hwid': 'REGISTRADO' if user['hwid'] else 'NO REGISTRADO',
                    'created_at': user['created_at'],
                    'last_login': user['last_login'],
                    'active': user['active'],
                    'connections': user['connections']
                }
                users_list.append(info)
            return users_list
        finally:
            self.lock.release()

    def toggle_user_active(self, username, active):
        """Activa o desactiva un usuario"""
        self.lock.acquire()
        try:
            if username not in self.users:
                return False, "Usuario no existe"

            self.users[username]['active'] = active
            status = "activado" if active else "desactivado"
            self.save_users()
            return True, f"Usuario '{username}' {status}"
        finally:
            self.lock.release()

    def _hash_password(self, password):
        """Genera hash SHA256 de la contraseña"""
        return hashlib.sha256(password.encode()).hexdigest()

    def _verify_password(self, password, password_hash):
        """Verifica contraseña contra su hash"""
        return self._hash_password(password) == password_hash

# Instancia global
user_manager = UserManager()

if __name__ == '__main__':
    # Test básico
    print("[+] Creando usuario de prueba...")
    success, msg = user_manager.create_user('admin', 'password123', hwid='ABC123DEF456')
    print(f"    {msg}")

    print("\n[+] Listando usuarios...")
    for user in user_manager.list_users():
        print(f"    {user}")

    print("\n[+] Autenticando usuario...")
    success, msg = user_manager.authenticate('admin', 'password123', hwid='ABC123DEF456')
    print(f"    {msg}")

    print("\n[+] Información del usuario...")
    info = user_manager.get_user_info('admin')
    print(f"    {info}")
