#!/bin/bash

# BioLab AI Uninstaller Script
# Script untuk menghapus aplikasi BioLab AI dan semua komponennya

set -e

# Konfigurasi
APP_NAME="biolab-ai"
APP_DIR="/opt/biolab-ai"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
USER="biolab"

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan pesan
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cek apakah script dijalankan sebagai root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script ini harus dijalankan sebagai root (gunakan sudo)"
        exit 1
    fi
}

# Konfirmasi uninstall
confirm_uninstall() {
    echo
    log_warn "PERINGATAN: Script ini akan menghapus semua komponen BioLab AI"
    log_warn "Termasuk:"
    log_warn "  - Service systemd"
    log_warn "  - Direktori aplikasi ($APP_DIR)"
    log_warn "  - User sistem ($USER)"
    log_warn "  - Konfigurasi firewall"
    echo
    
    read -p "Apakah Anda yakin ingin melanjutkan? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall dibatalkan"
        exit 0
    fi
}

# Stop dan disable service
stop_service() {
    log_info "Menghentikan service..."
    
    if systemctl is-active --quiet $APP_NAME 2>/dev/null; then
        systemctl stop $APP_NAME
        log_info "Service $APP_NAME berhasil dihentikan"
    else
        log_warn "Service $APP_NAME tidak berjalan"
    fi
    
    if systemctl is-enabled --quiet $APP_NAME 2>/dev/null; then
        systemctl disable $APP_NAME
        log_info "Service $APP_NAME berhasil di-disable"
    else
        log_warn "Service $APP_NAME tidak di-enable"
    fi
}

# Hapus service file
remove_service_file() {
    log_info "Menghapus service file..."
    
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
        log_info "Service file berhasil dihapus"
    else
        log_warn "Service file tidak ditemukan"
    fi
}

# Hapus direktori aplikasi
remove_app_directory() {
    log_info "Menghapus direktori aplikasi..."
    
    if [ -d "$APP_DIR" ]; then
        rm -rf "$APP_DIR"
        log_info "Direktori $APP_DIR berhasil dihapus"
    else
        log_warn "Direktori $APP_DIR tidak ditemukan"
    fi
}

# Hapus user aplikasi
remove_app_user() {
    log_info "Menghapus user aplikasi..."
    
    if id "$USER" &>/dev/null; then
        # Hapus user beserta home directory
        userdel -r "$USER" 2>/dev/null || userdel "$USER" 2>/dev/null
        log_info "User $USER berhasil dihapus"
    else
        log_warn "User $USER tidak ditemukan"
    fi
}

# Hapus konfigurasi firewall
remove_firewall_config() {
    log_info "Menghapus konfigurasi firewall..."
    
    if command -v ufw &> /dev/null; then
        # Hapus rule untuk port 5000
        ufw delete allow 5000/tcp 2>/dev/null || true
        log_info "Konfigurasi firewall berhasil dihapus"
    else
        log_warn "UFW tidak terinstall, lewati penghapusan firewall"
    fi
}

# Cleanup log files
cleanup_logs() {
    log_info "Membersihkan log files..."
    
    # Hapus log journal untuk service
    journalctl --vacuum-time=1s --unit=$APP_NAME 2>/dev/null || true
    
    log_info "Log files berhasil dibersihkan"
}

# Fungsi utama
main() {
    log_info "=== BioLab AI Uninstaller ==="
    
    check_root
    confirm_uninstall
    
    log_info "Memulai proses uninstall..."
    
    stop_service
    remove_service_file
    remove_app_directory
    remove_app_user
    remove_firewall_config
    cleanup_logs
    
    log_info "=== Uninstall Selesai ==="
    echo
    log_info "✅ BioLab AI berhasil dihapus dari sistem"
    log_info "Jika Anda ingin menghapus dependencies Python sistem, jalankan:"
    log_info "  sudo apt remove python3-pip python3-venv python3-dev build-essential"
    log_info "  sudo apt autoremove"
    echo
    log_info "Terima kasih telah menggunakan BioLab AI!"
}

# Jalankan fungsi utama
main "$@"
