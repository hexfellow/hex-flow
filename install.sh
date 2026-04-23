#!/bin/sh
# shellcheck shell=dash
# shellcheck disable=SC2039  # local is non-POSIX

# Installation script for hexflow.
# Downloads the latest release from GitHub and installs it to ~/.local/bin.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hexfellow/hex-flow/main/install.sh | sh

set -u

REPO="hexfellow/hex-flow"
INSTALL_DIR="${HEXFLOW_INSTALL_DIR:-$HOME/.local/bin}"
BINARY_NAME="hexflow"

# ---------------------------------------------------------------------------
# Utility helpers (modeled after rustup's install.sh)
# ---------------------------------------------------------------------------

has_local() {
    # shellcheck disable=SC2034
    local _has_local
}
has_local 2>/dev/null || alias local=typeset

_ansi_escapes_are_valid=false
if [ -t 2 ]; then
    if [ "${TERM+set}" = 'set' ]; then
        case "$TERM" in
            xterm*|rxvt*|urxvt*|linux*|vt*)
                _ansi_escapes_are_valid=true
            ;;
        esac
    fi
fi

__print() {
    if $_ansi_escapes_are_valid; then
        printf '\33[1m%s:\33[0m %s\n' "$1" "$2" >&2
    else
        printf '%s: %s\n' "$1" "$2" >&2
    fi
}

say() {
    __print 'info' "$1"
}

warn() {
    __print 'warn' "$1"
}

err() {
    __print 'error' "$1"
}

need_cmd() {
    if ! command -v "$1" > /dev/null 2>&1; then
        err "need '$1' (command not found)"
        exit 1
    fi
}

ensure() {
    if ! "$@"; then
        err "command failed: $*"
        exit 1
    fi
}

ignore() {
    "$@"
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

detect_platform() {
    local _ostype _cputype

    _ostype="$(uname -s)"
    _cputype="$(uname -m)"

    case "$_ostype" in
        Linux)
            ;;
        *)
            err "unsupported OS: $_ostype"
            err "hexflow currently only provides pre-built binaries for Linux."
            exit 1
            ;;
    esac

    case "$_cputype" in
        x86_64 | x86-64 | x64 | amd64)
            echo "amd64"
            ;;
        aarch64 | arm64)
            echo "arm64"
            ;;
        *)
            err "unsupported architecture: $_cputype"
            exit 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Downloader (curl preferred, wget as fallback)
# ---------------------------------------------------------------------------

download() {
    local _url="$1"
    local _output="$2"

    if command -v curl > /dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 --retry 3 -fsSL "$_url" -o "$_output"
    elif command -v wget > /dev/null 2>&1; then
        wget --https-only -q "$_url" -O "$_output"
    else
        err "need 'curl' or 'wget' (neither found)"
        exit 1
    fi
}

# Fetch a URL and print to stdout
download_to_stdout() {
    local _url="$1"

    if command -v curl > /dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 --retry 3 -fsSL "$_url"
    elif command -v wget > /dev/null 2>&1; then
        wget --https-only -q "$_url" -O -
    else
        err "need 'curl' or 'wget' (neither found)"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# PATH configuration
# ---------------------------------------------------------------------------

# Write the POSIX-compatible env snippet that can be sourced by sh/bash/zsh.
create_env_script() {
    local _install_dir="$1"
    local _env_file="${INSTALL_DIR}/../hexflow/env"
    ensure mkdir -p "$(dirname "$_env_file")"
    cat > "$_env_file" <<EOF
# hexflow PATH setup
# Sourced by shell profile files written by the hexflow installer.
case ":\${PATH}:" in
    *:"${_install_dir}":*)
        ;;
    *)
        export PATH="${_install_dir}:\$PATH"
        ;;
esac
EOF
    echo "$_env_file"
}

add_posix_line() {
    local _rc="$1"
    local _env_file="$2"
    local _install_dir="$3"

    if [ -f "$_rc" ] && grep -q "$_install_dir" "$_rc" 2>/dev/null; then
        return
    fi

    # Ensure the file exists (create if needed, like rustup does for .bash_profile)
    ensure touch "$_rc"
    printf '\n# Added by hexflow installer\n. "%s"\n' "$_env_file" >> "$_rc"
    say "modified PATH in $_rc"
}

add_fish_line() {
    local _install_dir="$1"
    local _fish_conf_dir="$HOME/.config/fish/conf.d"
    local _fish_file="${_fish_conf_dir}/hexflow.fish"

    if [ -f "$_fish_file" ] && grep -q "$_install_dir" "$_fish_file" 2>/dev/null; then
        return
    fi

    ensure mkdir -p "$_fish_conf_dir"
    cat > "$_fish_file" <<EOF
# Added by hexflow installer
if not contains "$_install_dir" \$PATH
    set -gx PATH "$_install_dir" \$PATH
end
EOF
    say "modified PATH in $_fish_file"
}

add_to_path() {
    local _install_dir="$1"
    local _env_file
    _env_file="$(create_env_script "$_install_dir")"

    # POSIX shells: write to the same set of files rustup uses
    add_posix_line "$HOME/.profile"      "$_env_file" "$_install_dir"
    add_posix_line "$HOME/.bashrc"       "$_env_file" "$_install_dir"
    add_posix_line "$HOME/.bash_profile" "$_env_file" "$_install_dir"

    # Fish
    add_fish_line "$_install_dir"
}

# ---------------------------------------------------------------------------
# Shell completions
# ---------------------------------------------------------------------------

add_zsh_fpath() {
    local _comp_dir="$1"
    local _zshrc="${HOME}/.zshrc"

    if [ -f "$_zshrc" ] && grep -q "$_comp_dir" "$_zshrc" 2>/dev/null; then
        return
    fi

    # Only touch .zshrc if zsh is actually installed
    if ! command -v zsh > /dev/null 2>&1; then
        return
    fi

    ignore touch "$_zshrc"
    printf '\n# Added by hexflow installer — shell completions\nfpath=(%s $fpath)\nautoload -Uz compinit && compinit\n' "$_comp_dir" >> "$_zshrc"
    say "added fpath entry to $_zshrc (restart zsh or run: source ~/.zshrc)"
}

install_completions() {
    local _install_dir="$1"
    local _bin="${_install_dir}/${BINARY_NAME}"

    if [ ! -x "$_bin" ]; then
        return
    fi

    # Bash — ~/.local/share/bash-completion/completions/ is auto-discovered
    local _bash_comp_dir="${HOME}/.local/share/bash-completion/completions"
    if mkdir -p "$_bash_comp_dir" 2>/dev/null; then
        if "$_bin" completions bash > "${_bash_comp_dir}/${BINARY_NAME}" 2>/dev/null; then
            say "installed bash completions to ${_bash_comp_dir}/${BINARY_NAME}"
        fi
    fi

    # Zsh — needs fpath entry to auto-discover
    local _zsh_comp_dir="${HOME}/.local/share/zsh/site-functions"
    if mkdir -p "$_zsh_comp_dir" 2>/dev/null; then
        if "$_bin" completions zsh > "${_zsh_comp_dir}/_${BINARY_NAME}" 2>/dev/null; then
            say "installed zsh completions to ${_zsh_comp_dir}/_${BINARY_NAME}"
            add_zsh_fpath "$_zsh_comp_dir"
        fi
    fi

    # Fish — ~/.config/fish/completions/ is auto-discovered
    local _fish_comp_dir="${HOME}/.config/fish/completions"
    if mkdir -p "$_fish_comp_dir" 2>/dev/null; then
        if "$_bin" completions fish > "${_fish_comp_dir}/${BINARY_NAME}.fish" 2>/dev/null; then
            say "installed fish completions to ${_fish_comp_dir}/${BINARY_NAME}.fish"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    need_cmd uname
    need_cmd mktemp
    need_cmd chmod
    need_cmd mkdir
    need_cmd tar
    need_cmd rm

    local _arch
    _arch="$(detect_platform)"

    local _asset="hexflow_linux_${_arch}.tar.gz"
    say "detected platform: linux/${_arch}"

    say "fetching latest release info from GitHub..."
    local _download_url="https://github.com/${REPO}/releases/latest/download/${_asset}"

    local _tmp
    if ! _tmp="$(ensure mktemp -d)"; then
        exit 1
    fi

    local _tarball="${_tmp}/${_asset}"

    say "downloading ${_asset}..."
    if ! download "$_download_url" "$_tarball"; then
        err "failed to download ${_asset}"
        err "please check your network connection and verify the release exists at:"
        err "  https://github.com/${REPO}/releases/latest"
        ignore rm -rf "$_tmp"
        exit 1
    fi

    say "extracting ${_asset}..."
    ensure tar -xzf "$_tarball" -C "$_tmp"

    if [ ! -f "${_tmp}/${BINARY_NAME}" ]; then
        err "expected binary '${BINARY_NAME}' not found in archive"
        ignore rm -rf "$_tmp"
        exit 1
    fi

    ensure mkdir -p "$INSTALL_DIR"
    ensure chmod +x "${_tmp}/${BINARY_NAME}"
    ensure mv "${_tmp}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"

    ignore rm -rf "$_tmp"

    say "installed ${BINARY_NAME} to ${INSTALL_DIR}/${BINARY_NAME}"

    if ! echo ":${PATH}:" | grep -q ":${INSTALL_DIR}:"; then
        warn "${INSTALL_DIR} is not in your PATH"
        add_to_path "$INSTALL_DIR"
        say "restart your shell or run: export PATH=\"${INSTALL_DIR}:\$PATH\""
    else
        say "${BINARY_NAME} is ready to use!"
    fi

    "${INSTALL_DIR}/${BINARY_NAME}" --version 2>/dev/null && say "installation complete!"

    install_completions "$INSTALL_DIR"
}

main "$@" || exit 1
