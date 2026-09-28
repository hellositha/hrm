#!/usr/bin/env bash
# ==============================================================================
# PulseHR / Cambodia HRMS - Server Setup & Deployment Automation Script
# ==============================================================================
# This script prepares and runs all dependencies, database data, and systemd
# service requirements when deploying this project to a new Linux server.
#
# Usage:
#   sudo ./setup.sh [OPTIONS]
#
# Options:
#   -p, --port <PORT>     Set application port (default: 80, or from .env)
#   --apply-db            Apply database data from data/init_data.sql (creates backup)
#   --db-only             Only initialize/apply the database data and exit
#   --service-only        Only configure, enable, and restart the systemd service
#   --skip-deps           Skip OS-level package installation (apt-get, etc.)
#   --skip-build          Skip "npm run build"
#   --skip-service        Skip systemd service setup
#   -y, --yes             Non-interactive mode (auto-accept prompts)
#   -h, --help            Show this help message
# ==============================================================================

set -e

# --- Terminal Styling ---
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[1;32m"
C_BLUE="\033[1;34m"
C_CYAN="\033[1;36m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"

log_info() {
  echo -e "${C_BLUE}[INFO]${C_RESET} $*"
}

log_success() {
  echo -e "${C_GREEN}[SUCCESS]${C_RESET} $*"
}

log_warn() {
  echo -e "${C_YELLOW}[WARN]${C_RESET} $*"
}

log_error() {
  echo -e "${C_RED}[ERROR]${C_RESET} $*"
}

log_step() {
  echo -e "\n${C_CYAN}${C_BOLD}==> Step: $*${C_RESET}"
}

# --- Resolve Project Directory ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"

# --- Default Options ---
TARGET_PORT=""
FORCE_APPLY_DB=false
DB_ONLY=false
SERVICE_ONLY=false
SKIP_DEPS=false
SKIP_BUILD=false
SKIP_SERVICE=false
AUTO_YES=false
SERVICE_NAME="hr"

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--port)
      TARGET_PORT="$2"
      shift 2
      ;;
    --apply-db)
      FORCE_APPLY_DB=true
      shift
      ;;
    --db-only)
      DB_ONLY=true
      shift
      ;;
    --service-only)
      SERVICE_ONLY=true
      shift
      ;;
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-service)
      SKIP_SERVICE=true
      shift
      ;;
    -y|--yes)
      AUTO_YES=true
      shift
      ;;
    -h|--help)
      cat << 'EOF'
PulseHR - Server Setup & Deployment Script

USAGE:
  sudo ./setup.sh [OPTIONS]

OPTIONS:
  -p, --port <PORT>     Set application port (default: 80, or from .env)
  --apply-db            Apply database data from data/init_data.sql (creates backup)
  --db-only             Only initialize/apply the database data and exit
  --service-only        Only configure, enable, and restart the systemd service
  --skip-deps           Skip OS-level package installation (apt-get, etc.)
  --skip-build          Skip "npm run build"
  --skip-service        Skip systemd service setup
  -y, --yes             Non-interactive mode (auto-accept prompts)
  -h, --help            Show this help message

EXAMPLES:
  # 1. Full automated setup on a fresh server (port 80):
  sudo ./setup.sh

  # 2. Run on custom port (e.g., 3000):
  sudo ./setup.sh --port 3000

  # 3. Apply database data only:
  sudo ./setup.sh --db-only

  # 4. Force apply initial database data during full setup:
  sudo ./setup.sh --apply-db -y
EOF
      exit 0
      ;;
    *)
      log_error "Unknown option: $1. Run with --help for usage details."
      exit 1
      ;;
  esac
done

echo -e "${C_CYAN}${C_BOLD}"
echo "=================================================================="
echo "    PulseHR - Automated Server Setup & Service Deployment         "
echo "=================================================================="
echo -e "${C_RESET}"
log_info "Project Directory: ${PROJECT_DIR}"

# --- Privilege Check ---
IS_ROOT=false
if [ "$EUID" -eq 0 ]; then
  IS_ROOT=true
fi

if [ "$IS_ROOT" = false ] && [ "$SERVICE_ONLY" = true -o "$SKIP_DEPS" = false ]; then
  log_warn "This script performs system-level tasks (packages, systemd, ports < 1024)."
  log_warn "Running with sudo is highly recommended. Attempting to continue..."
fi

# Determine default port if not explicitly specified via CLI
if [ -z "${TARGET_PORT}" ]; then
  if [ "$IS_ROOT" = true ]; then
    TARGET_PORT="80"
  else
    TARGET_PORT="3000"
  fi
fi
log_info "Configured Port: ${TARGET_PORT}"

# ==============================================================================
# FUNCTION: Apply Database Data
# ==============================================================================
apply_database_data() {
  log_step "Database Configuration & Data Application"

  mkdir -p "${PROJECT_DIR}/data"
  local sql_file="${PROJECT_DIR}/data/init_data.sql"
  local db_file="${PROJECT_DIR}/data/hr.db"

  if [ ! -f "${sql_file}" ]; then
    log_error "Database SQL dump not found at ${sql_file}!"
    exit 1
  fi

  local need_apply=false

  if [ ! -f "${db_file}" ] || [ ! -s "${db_file}" ]; then
    log_info "No existing database detected at ${db_file}. Initializing fresh database with seed data..."
    need_apply=true
  elif [ "$FORCE_APPLY_DB" = true ]; then
    log_info "--apply-db flag provided. Preparing to apply database data..."
    need_apply=true
  else
    # Check if database has tables
    local has_tables=0
    if command -v node >/dev/null 2>&1 && [ -d "${PROJECT_DIR}/node_modules/better-sqlite3" ]; then
      has_tables=$(node -e "
        try {
          const db = require('better-sqlite3')('${db_file}', { readonly: true });
          const count = db.prepare(\"SELECT count(*) as c FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'\").get().c;
          db.close();
          console.log(count);
        } catch(e) { console.log(0); }
      " 2>/dev/null || echo 0)
    elif command -v sqlite3 >/dev/null 2>&1; then
      has_tables=$(sqlite3 "${db_file}" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';" 2>/dev/null || echo 0)
    fi

    if [ "$has_tables" -eq 0 ]; then
      log_info "Existing database is empty (0 tables). Applying initial database data..."
      need_apply=true
    else
      log_info "Database already exists with active tables (${db_file})."
      if [ "$AUTO_YES" = false ]; then
        echo -en "${C_YELLOW}[PROMPT] Do you want to overwrite and re-apply initial database data? (y/N): ${C_RESET}"
        read -r user_choice
        if [[ "$user_choice" =~ ^[Yy]$ ]]; then
          need_apply=true
        else
          log_info "Keeping existing database data intact."
        fi
      else
        log_info "Non-interactive mode: keeping existing database data intact."
      fi
    fi
  fi

  if [ "$need_apply" = true ]; then
    if [ -f "${PROJECT_DIR}/scripts/apply-db.js" ] && command -v node >/dev/null 2>&1 && [ -d "${PROJECT_DIR}/node_modules/better-sqlite3" ]; then
      node "${PROJECT_DIR}/scripts/apply-db.js" --force --sql "${sql_file}" --db "${db_file}"
    elif command -v sqlite3 >/dev/null 2>&1; then
      if [ -f "${db_file}" ] && [ -s "${db_file}" ]; then
        local ts
        ts="$(date +%Y%m%d_%H%M%S)"
        cp "${db_file}" "${db_file}.bak.${ts}"
        log_info "Created backup: ${db_file}.bak.${ts}"
        rm -f "${db_file}" "${db_file}-wal" "${db_file}-shm"
      fi
      sqlite3 "${db_file}" < "${sql_file}"
      sqlite3 "${db_file}" "PRAGMA journal_mode = WAL; PRAGMA wal_checkpoint(TRUNCATE);"
      log_success "Applied ${sql_file} to ${db_file} using sqlite3 CLI."
    else
      log_error "Neither better-sqlite3 nor sqlite3 CLI is available yet to apply database."
      log_error "Please ensure dependencies are installed first."
      exit 1
    fi
  fi

  # Ensure appropriate permissions
  chmod 755 "${PROJECT_DIR}/data" 2>/dev/null || true
  if [ -f "${db_file}" ]; then
    chmod 664 "${db_file}" 2>/dev/null || true
  fi
  log_success "Database is ready at ${db_file}"
}

# If --db-only was passed, apply db and exit
if [ "$DB_ONLY" = true ]; then
  apply_database_data
  exit 0
fi

# ==============================================================================
# FUNCTION: Configure Systemd Service
# ==============================================================================
configure_service() {
  log_step "Configuring and Starting systemd Service (${SERVICE_NAME}.service)"

  if ! command -v systemctl >/dev/null 2>&1; then
    log_warn "systemctl is not available on this system. Skipping systemd service configuration."
    log_info "You can start the app manually with: npm run start"
    return 0
  fi

  local npm_bin
  npm_bin="$(command -v npm || echo "/usr/bin/npm")"
  local node_bin
  node_bin="$(command -v node || echo "/usr/bin/node")"
  local node_dir
  node_dir="$(dirname "${node_bin}")"

  local port="${TARGET_PORT:-80}"

  # Check if port is in use by an external process
  if command -v ss >/dev/null 2>&1; then
    local conflicting_pid
    conflicting_pid=$(ss -tulpn 2>/dev/null | grep -E ":${port}\s" | awk '{print $NF}' | head -n 1 || true)
    if [ -n "$conflicting_pid" ]; then
      log_warn "Notice: Port ${port} is currently bound by: ${conflicting_pid}"
      log_warn "If this is not your service, ensure the port is freed or specify an alternate port with --port <PORT>."
    fi
  fi

  local service_user="root"
  if [ "$IS_ROOT" = false ]; then
    service_user="$(whoami)"
  fi

  local service_file="/etc/systemd/system/${SERVICE_NAME}.service"

  log_info "Creating service unit: ${service_file}"
  log_info " - Working Directory: ${PROJECT_DIR}"
  log_info " - Execution Binary : ${npm_bin} run start"
  log_info " - Service User     : ${service_user}"
  log_info " - Port             : ${port}"

  cat << EOF > "${service_file}"
[Unit]
Description=Cambodia HR Management System (PulseHR)
After=network.target

[Service]
Type=simple
User=${service_user}
WorkingDirectory=${PROJECT_DIR}
ExecStart=${npm_bin} run start
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=PORT=${port}
Environment=HOST=0.0.0.0
Environment=PATH=${node_dir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

  chmod 644 "${service_file}"
  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}.service"
  systemctl restart "${SERVICE_NAME}.service"

  log_info "Waiting for service to become active..."
  local is_running=false
  for i in {1..10}; do
    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
      is_running=true
      break
    fi
    sleep 1
  done

  if [ "$is_running" = true ]; then
    log_success "${SERVICE_NAME}.service is ACTIVE and RUNNING."
  else
    log_error "${SERVICE_NAME}.service failed to start. Checking journal logs:"
    journalctl -u "${SERVICE_NAME}.service" -n 25 --no-pager
    exit 1
  fi

  # Configure UFW firewall if enabled
  if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -qi "Status: active"; then
      log_info "Configuring UFW firewall to allow port ${port}/tcp..."
      ufw allow "${port}/tcp" >/dev/null 2>&1 || true
      log_success "Port ${port}/tcp opened in UFW firewall."
    fi
  fi
}

# If --service-only was passed, configure service and exit
if [ "$SERVICE_ONLY" = true ]; then
  configure_service
  exit 0
fi

# ==============================================================================
# STEP 1: OS Dependencies & System Tools
# ==============================================================================
if [ "$SKIP_DEPS" = false ]; then
  log_step "Installing System Dependencies & Native Build Tools"

  if command -v apt-get >/dev/null 2>&1; then
    log_info "Detected Debian/Ubuntu system. Updating apt package list..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y -qq

    log_info "Installing essential build dependencies (curl, build-essential, python3, make, g++, sqlite3)..."
    apt-get install -y -qq \
      curl \
      wget \
      git \
      build-essential \
      python3 \
      make \
      g++ \
      gcc \
      sqlite3 \
      ca-certificates
  elif command -v dnf >/dev/null 2>&1; then
    log_info "Detected RHEL/Fedora/Rocky/Alma system. Installing build tools..."
    dnf groupinstall -y "Development Tools" || true
    dnf install -y curl wget git python3 make gcc-c++ sqlite
  elif command -v apk >/dev/null 2>&1; then
    log_info "Detected Alpine Linux. Installing build tools..."
    apk add --no-cache curl wget git build-base python3 make g++ sqlite
  else
    log_warn "Unknown package manager. Please ensure curl, git, python3, make, and g++ are installed."
  fi

  # --- Node.js Check and Installation ---
  NEED_NODE_INSTALL=false
  if ! command -v node >/dev/null 2>&1; then
    log_warn "Node.js is not installed."
    NEED_NODE_INSTALL=true
  else
    NODE_MAJOR="$(node -v | cut -d'v' -f2 | cut -d'.' -f1)"
    if [ "$NODE_MAJOR" -lt 20 ]; then
      log_warn "Installed Node.js version $(node -v) is older than v20 (v20+ LTS required)."
      NEED_NODE_INSTALL=true
    else
      log_success "Node.js $(node -v) and npm $(npm -v) are already installed."
    fi
  fi

  if [ "$NEED_NODE_INSTALL" = true ]; then
    if command -v apt-get >/dev/null 2>&1; then
      log_info "Installing Node.js 20.x LTS from official NodeSource repository..."
      curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
      apt-get install -y -qq nodejs
      log_success "Installed Node.js $(node -v) and npm $(npm -v)."
    else
      log_error "Please install Node.js 20+ LTS manually for your distribution."
      exit 1
    fi
  fi
else
  log_info "Skipping system dependencies installation (--skip-deps)."
fi

# ==============================================================================
# STEP 2: Environment Variables (.env)
# ==============================================================================
log_step "Configuring Environment (.env)"

if [ ! -f "${PROJECT_DIR}/.env" ]; then
  if [ -f "${PROJECT_DIR}/.env.example" ]; then
    cp "${PROJECT_DIR}/.env.example" "${PROJECT_DIR}/.env"
    log_info "Created .env from .env.example"
  else
    cat << 'EOF' > "${PROJECT_DIR}/.env"
PORT=80
HOST=0.0.0.0
NODE_ENV=production
AUTH_SECRET=cambodia_hrms_super_secure_secret_token_2026_pulsehr
DATABASE_PATH=data/hr.db
SESSION_MAX_AGE_DAYS=7
DEFAULT_LANGUAGE=km
DEFAULT_TIMEZONE=Asia/Phnom_Penh
DEFAULT_KHR_USD_EXCHANGE_RATE=4100
DEFAULT_COMPANY_NAME="HESTRA HRM Technologies Inc."
EOF
    log_info "Generated default .env configuration file."
  fi
fi

# Override PORT in .env if specified via argument
if [ -n "${TARGET_PORT}" ]; then
  if grep -q "^PORT=" "${PROJECT_DIR}/.env"; then
    sed -i "s/^PORT=.*/PORT=${TARGET_PORT}/" "${PROJECT_DIR}/.env"
  else
    echo "PORT=${TARGET_PORT}" >> "${PROJECT_DIR}/.env"
  fi
  log_info "Configured PORT=${TARGET_PORT} in .env"
elif ! grep -q "^PORT=" "${PROJECT_DIR}/.env"; then
  echo "PORT=80" >> "${PROJECT_DIR}/.env"
  log_info "Configured default PORT=80 in .env"
fi

# ==============================================================================
# STEP 3: Node Packages & Native Addon Rebuild
# ==============================================================================
log_step "Installing Node Packages & Native SQLite Addons"

if [ -f "${PROJECT_DIR}/package-lock.json" ]; then
  log_info "Running npm install..."
  npm install
else
  log_info "Running npm install..."
  npm install
fi

log_info "Compiling / rebuilding native SQLite binary (better-sqlite3)..."
npm rebuild better-sqlite3

# Test that better-sqlite3 loads properly
node -e "require('better-sqlite3');" && log_success "better-sqlite3 native bindings verified successfully."

# ==============================================================================
# STEP 4: Database Setup & Data Application
# ==============================================================================
apply_database_data

# ==============================================================================
# STEP 5: Next.js Production Build
# ==============================================================================
if [ "$SKIP_BUILD" = false ]; then
  log_step "Building Next.js Production Bundle (next build)"
  log_info "Compiling TypeScript, App Router routes, and Tailwind CSS assets..."
  npm run build
  log_success "Production build completed successfully."
else
  log_info "Skipping Next.js build (--skip-build)."
fi

# ==============================================================================
# STEP 6: Service Requirement (systemd)
# ==============================================================================
if [ "$SKIP_SERVICE" = false ]; then
  configure_service
else
  log_info "Skipping systemd service configuration (--skip-service)."
fi

# ==============================================================================
# STEP 7: Health Check & Verification
# ==============================================================================
log_step "Performing Health Check"

APP_PORT="${TARGET_PORT}"
if [ -z "${APP_PORT}" ]; then
  APP_PORT=$(grep "^PORT=" "${PROJECT_DIR}/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "80")
fi
if [ -z "${APP_PORT}" ]; then
  APP_PORT="80"
fi

HEALTHY=false
if command -v curl >/dev/null 2>&1; then
  log_info "Testing connection to http://127.0.0.1:${APP_PORT}..."
  for i in {1..10}; do
    HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${APP_PORT}" || echo "000")"
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 302 ] || [ "$HTTP_CODE" -eq 307 ]; then
      HEALTHY=true
      break
    fi
    sleep 1
  done
fi

SERVER_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")"

echo -e "\n${C_GREEN}${C_BOLD}"
echo "=================================================================="
echo "    PulseHR System Setup & Deployment Completed Successfully!    "
echo "=================================================================="
echo -e "${C_RESET}"

if [ "$HEALTHY" = true ]; then
  echo -e "Service Status : ${C_GREEN}HEALTHY & RESPONDING${C_RESET} (HTTP ${HTTP_CODE})"
else
  echo -e "Service Status : ${C_YELLOW}INITIALIZING${C_RESET} (May take a few more seconds)"
fi

echo -e "Local URL      : ${C_CYAN}http://localhost:${APP_PORT}${C_RESET}"
echo -e "Network URL    : ${C_CYAN}http://${SERVER_IP}:${APP_PORT}${C_RESET}"
echo -e "Database File  : ${PROJECT_DIR}/data/hr.db"

echo -e "\n${C_BOLD}Default Login Personas / Accounts:${C_RESET}"
echo -e " - ${C_BOLD}Admin${C_RESET}       : Username: ${C_CYAN}admin${C_RESET}   | Password: ${C_CYAN}hestra123${C_RESET}"
echo -e " - ${C_BOLD}CEO${C_RESET}         : Username: ${C_CYAN}ceo${C_RESET}     | Password: ${C_CYAN}hestra123${C_RESET}"
echo -e " - ${C_BOLD}IT Support${C_RESET}  : Username: ${C_CYAN}sitha${C_RESET}   | Password: ${C_CYAN}online?${C_RESET}"
echo -e " - ${C_BOLD}Staff${C_RESET}       : Username: ${C_CYAN}vichet${C_RESET}  | Password: ${C_CYAN}hestra123${C_RESET}"

echo -e "\n${C_BOLD}Useful Service Commands:${C_RESET}"
echo -e " - View live logs    : ${C_CYAN}journalctl -u ${SERVICE_NAME}.service -f${C_RESET}"
echo -e " - Check status      : ${C_CYAN}systemctl status ${SERVICE_NAME}.service${C_RESET}"
echo -e " - Restart service   : ${C_CYAN}systemctl restart ${SERVICE_NAME}.service${C_RESET}"
echo -e " - Re-apply DB data  : ${C_CYAN}npm run db:apply${C_RESET}"
echo -e " - Dump latest DB    : ${C_CYAN}npm run db:dump${C_RESET}"
echo "=================================================================="
