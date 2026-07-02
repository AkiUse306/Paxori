#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Paxori"
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_INSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global|-g)
      GLOBAL_INSTALL=true
      shift
      ;;
    --user)
      GLOBAL_INSTALL=false
      shift
      ;;
    --help|-h)
      cat <<EOF
Usage: bash install.sh [--global]

Options:
  --global    Install Paxori system-wide to /usr/local
  --user      Install Paxori for the current user (default)
  --help      Show this help message
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ "$GLOBAL_INSTALL" == true ]]; then
  INSTALL_DIR="${INSTALL_DIR:-/usr/local/share/paxori}"
  BIN_DIR="${BIN_DIR:-/usr/local/bin}"
else
  INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/paxori}"
  BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
fi

DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
  printf '%b[%s]%b %s\n' "$BLUE" "$1" "$NC" "$2"
}

success() {
  printf '%b[%s]%b %s\n' "$GREEN" "OK" "$NC" "$1"
}

warn() {
  printf '%b[%s]%b %s\n' "$YELLOW" "WARN" "$NC" "$1"
}

fail() {
  printf '%b[%s]%b %s\n' "$RED" "ERR" "$NC" "$1" >&2
  exit 1
}

show_banner() {
  cat <<EOF
${CYAN}
  ██████╗  ██████╗ ██╗  ██╗██╗███████╗
  ██╔══██╗██╔═══██╗██║  ██║██║██╔════╝
  ██████╔╝██║   ██║███████║██║███████╗
  ██╔═══╝ ██║   ██║██╔══██║██║██╔══╝
  ██║     ╚██████╔╝██║  ██║██║███████╗
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝
${NC}
EOF
}

check_prereqs() {
  log "STEP 1" "Checking required tools"
  command -v node >/dev/null 2>&1 || fail "Node.js is required. Install it from https://nodejs.org"
  command -v npm >/dev/null 2>&1 || fail "npm is required. Install Node.js first"
  success "Node.js and npm are available"
}

prepare_paths() {
  log "STEP 2" "Preparing install directories"
  mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR"
  success "Install target: $INSTALL_DIR"
}

install_app() {
  log "STEP 3" "Installing Paxori files"
  rm -rf "$INSTALL_DIR"/* "$INSTALL_DIR"/.[!.]* "$INSTALL_DIR"/..?* 2>/dev/null || true
  cp -R "$APP_ROOT"/. "$INSTALL_DIR"/
  pushd "$INSTALL_DIR" >/dev/null
  npm install --silent
  popd >/dev/null
  success "Application files copied and dependencies installed"
}

create_launcher() {
  log "STEP 4" "Creating launcher"
  cat > "$BIN_DIR/paxori" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$INSTALL_DIR"
exec npm start "$@"
EOF
  chmod +x "$BIN_DIR/paxori"

  cat > "$DESKTOP_DIR/paxori.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Paxori
Comment=Fast, secure, cross-platform file transfers
Exec=$BIN_DIR/paxori
Terminal=true
Categories=Utility;Network;
EOF

  success "Launcher created at $BIN_DIR/paxori"
}

finish() {
  printf '\n%sPaxori installation complete!%s\n' "$WHITE" "$NC"
  printf '%sRun it anytime with:%s\n' "$CYAN" "$NC"
  printf '  %spaxori%s\n' "$WHITE" "$NC"
  printf '%sOpen http://127.0.0.1:3000 after launch.%s\n' "$CYAN" "$NC"
  if [[ "$GLOBAL_INSTALL" == true ]]; then
    printf '%sGlobal installation path:%s %s\n' "$CYAN" "$NC" "$INSTALL_DIR"
  fi
}

show_banner
check_prereqs
if [[ "$GLOBAL_INSTALL" == true && "$EUID" -ne 0 ]]; then
  fail "Global installation requires root privileges. Run with sudo: sudo bash install.sh --global"
fi
prepare_paths
install_app
create_launcher
finish
