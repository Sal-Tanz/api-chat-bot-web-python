#!/bin/bash

# BioLab AI Installer Script
# Script untuk menginstall aplikasi BioLab AI sebagai service systemd

set -e

# Konfigurasi
APP_NAME="biolab-ai"
APP_DIR="/opt/biolab-ai"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
USER="biolab"
PYTHON_VERSION="python3"

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

# Install dependencies sistem
install_system_dependencies() {
    log_info "Menginstall dependencies sistem..."
    
    # Update package list
    apt update
    
    # Install Python, pip, dan dependencies lainnya
    apt install -y python3 python3-pip python3-venv python3-dev build-essential curl
    
    log_info "Dependencies sistem berhasil diinstall"
}

# Buat user untuk aplikasi
create_app_user() {
    log_info "Membuat user aplikasi..."
    
    if id "$USER" &>/dev/null; then
        log_warn "User $USER sudah ada"
    else
        useradd --system --shell /bin/bash --home-dir $APP_DIR --create-home $USER
        log_info "User $USER berhasil dibuat"
    fi
}

# Setup direktori aplikasi
setup_app_directory() {
    log_info "Menyiapkan direktori aplikasi..."
    
    # Buat direktori jika belum ada
    mkdir -p $APP_DIR
    
    # Copy file aplikasi
    if [ -f "app.py" ]; then
        cp app.py $APP_DIR/
        log_info "File app.py berhasil dicopy"
    else
        log_error "File app.py tidak ditemukan di direktori saat ini"
        exit 1
    fi
    
    # Copy requirements.txt jika ada
    if [ -f "requirements.txt" ]; then
        cp requirements.txt $APP_DIR/
    else
        # Buat requirements.txt
        cat > $APP_DIR/requirements.txt << EOF
Flask==2.3.3
Flask-CORS==4.0.0
google-generativeai==0.3.2
EOF
    fi
    
    # Set ownership
    chown -R $USER:$USER $APP_DIR
    chmod 755 $APP_DIR
    
    log_info "Direktori aplikasi berhasil disiapkan"
}

# Setup Python virtual environment
setup_python_environment() {
    log_info "Menyiapkan Python virtual environment..."
    
    # Buat virtual environment
    sudo -u $USER python3 -m venv $APP_DIR/venv
    
    # Install Python dependencies
    sudo -u $USER $APP_DIR/venv/bin/pip install --upgrade pip
    sudo -u $USER $APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt
    
    log_info "Python environment berhasil disiapkan"
}

# Buat systemd service file
create_systemd_service() {
    log_info "Membuat systemd service..."
    
    cat > $SERVICE_FILE << EOF
[Unit]
Description=BioLab AI Flask Application
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
ExecStart=$APP_DIR/venv/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$APP_DIR
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF
    
    log_info "Service file berhasil dibuat"
}

# Setup firewall
setup_firewall() {
    log_info "Mengkonfigurasi firewall..."
    
    # Cek apakah ufw terinstall
    if command -v ufw &> /dev/null; then
        ufw allow 5000/tcp
        log_info "Port 5000 berhasil dibuka di firewall"
    else
        log_warn "UFW tidak terinstall, lewati konfigurasi firewall"
    fi
}

# Enable dan start service
enable_service() {
    log_info "Mengaktifkan service..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable $APP_NAME
    
    # Start service
    systemctl start $APP_NAME
    
    log_info "Service berhasil diaktifkan dan dijalankan"
}

# Cek status service
check_service_status() {
    log_info "Mengecek status service..."
    
    sleep 2
    
    if systemctl is-active --quiet $APP_NAME; then
        log_info "✅ Service $APP_NAME berhasil berjalan"
        log_info "Status: $(systemctl is-active $APP_NAME)"
        log_info "Aplikasi dapat diakses di: http://localhost:5000"
    else
        log_error "❌ Service $APP_NAME gagal berjalan"
        log_error "Cek log dengan: sudo journalctl -u $APP_NAME -f"
        exit 1
    fi
}

# Fungsi utama
main() {
    log_info "=== BioLab AI Installer ==="
    log_info "Memulai instalasi..."
    
    check_root
    install_system_dependencies
    create_app_user
    setup_app_directory
    setup_python_environment
    create_systemd_service
    setup_firewall
    enable_service
    check_service_status
    
    log_info "=== Instalasi Selesai ==="
    echo
    log_info "Perintah berguna:"
    log_info "  Status service: sudo systemctl status $APP_NAME"
    log_info "  Stop service: sudo systemctl stop $APP_NAME"
    log_info "  Start service: sudo systemctl start $APP_NAME"
    log_info "  Restart service: sudo systemctl restart $APP_NAME"
    log_info "  Lihat log: sudo journalctl -u $APP_NAME -f"
    log_info "  Uninstall: sudo ./uninstall.sh"
    echo
    log_info "Aplikasi BioLab AI berhasil diinstall dan berjalan di port 5000"
}

# Jalankan fungsi utama
main "$@"
