#!/bin/bash

# Script de instalação automática do VPS Reinstaller
# Detecta arquitetura e baixa o binário correto do GitHub

set -e

# Configurações
GITHUB_USER="nandoslayer"  # ⚠️ ALTERE AQUI
GITHUB_REPO="vps-reinstaller"  # ⚠️ ALTERE AQUI
VERSION="latest"  # ou específica como "v1.0.0"

clear
echo "════════════════════════════════════"
echo "   🚀 VPS Reinstaller - Instalacion Automática"
echo "═════════════════════════════"
echo ""

# Detectar arquitetura
echo "🔍 Detectando arquitetura de sistema..."
ARCH=$(uname -m)
echo "   Arquitetura detectada: $ARCH"

case $ARCH in
    x86_64)
        BINARY_NAME="vps-reinstaller-x86_64"
        echo "   ✅ Compatível: Intel/AMD 64-bit"
        ;;
    aarch64|arm64)
        BINARY_NAME="vps-reinstaller-aarch64"
        echo "   ✅ Compatível: ARM 64-bit"
        ;;
    *)
        echo "   ❌ Arquitetura não suportada: $ARCH"
        echo ""
        echo "Arquiteturas suportadas:"
        echo "  • x86_64 (Intel/AMD 64-bit)"
        echo "  • aarch64 (ARM 64-bit)"
        exit 1
        ;;
esac

echo ""

# Verificar se wget ou curl está disponível
if command -v wget &> /dev/null; then
    DOWNLOADER="wget"
    DOWNLOAD_CMD="wget -q --show-progress"
elif command -v curl &> /dev/null; then
    DOWNLOADER="curl"
    DOWNLOAD_CMD="curl -L -o"
else
    echo "❌ Erro: wget ou curl no encontrado!"
    echo "Instale um dos dois:"
    echo "  • Debian/Ubuntu: apt install wget"
    exit 1
fi

echo "📥 Usando: $DOWNLOADER"
echo ""

# Construir URL do GitHub
if [ "$VERSION" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/latest/download/$BINARY_NAME"
else
    DOWNLOAD_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/download/$VERSION/$BINARY_NAME"
fi

echo "📦 Baixando binário do GitHub..."
echo "   URL: $DOWNLOAD_URL"
echo ""

# Baixar arquivo
if [ "$DOWNLOADER" = "wget" ]; then
    wget -q --show-progress -O vps-reinstaller "$DOWNLOAD_URL"
else
    curl -L --progress-bar -o vps-reinstaller "$DOWNLOAD_URL"
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error al bajar o binário!"
    echo ""
    echo "Verifique se:"
    echo "  • A release existe no GitHub"
    echo "  • O arquivo $BINARY_NAME foi enviado"
    echo "  • Você tem acesso à internet"
    exit 1
fi

echo ""
echo "✅ Download concluído!"

# Dar permissão de execucion
echo "🔧 Configurando permissões..."
chmod +x vps-reinstaller

# Verificar tamanho do arquivo
SIZE=$(ls -lh vps-reinstaller | awk '{print $5}')
echo "   Tamanho do binário: $SIZE"

echo ""
echo "══════════════════════════════"
echo "✅ Instalação concluída com sucesso!"
echo "══════════════════════════════════"
echo ""
echo "🚀 Para ejecutar, digite:"
echo "   ./vps-reinstaller"
echo ""
echo "⚠️  ATENCION:"
echo "   • Este programa va BORRAR TODOS LOS DATOS DE TU VPS"
echo "   • HAGA BACKUP antes de Continuar"
echo "   • Vos perderá axeso SSH temporarmente"
echo ""

# Perguntar se quer ejecutar agora
if [ -t 1 ] && [ -e /dev/tty ]; then
    echo ""
    read -r -p "Desea ejecutar ahora? (s/N): " REPLY < /dev/tty
    echo ""
else
    REPLY="n"
fi

if [[ "$REPLY" =~ ^[Ss]$ ]]; then
    echo ""
    ./vps-reinstaller
else
    echo ""
    echo "👍 Execute quando estiver pronto: ./vps-reinstaller"
fi