#!/usr/bin/env bash

{ # This ensures the entire script is downloaded #

# Config.
VPM_VERSION="1.8.0"
VPM_SOURCE=https://raw.githubusercontent.com/andrewscwei/vpm/v$VPM_VERSION/vpm.sh

# Colors.
COLOR_PREFIX="\x1b["
COLOR_RESET=$COLOR_PREFIX"0m"
COLOR_BLACK=$COLOR_PREFIX"0;30m"
COLOR_RED=$COLOR_PREFIX"0;31m"
COLOR_GREEN=$COLOR_PREFIX"0;32m"
COLOR_ORANGE=$COLOR_PREFIX"0;33m"
COLOR_BLUE=$COLOR_PREFIX"0;34m"
COLOR_PURPLE=$COLOR_PREFIX"0;35m"
COLOR_CYAN=$COLOR_PREFIX"0;36m"
COLOR_LIGHT_GRAY=$COLOR_PREFIX"0;37m"

# @global
#
# Checks if a command is available
#
# @param $1 Name of the command.
function VPM_HAS() {
  type "$1" > /dev/null 2>&1
}

# @global
#
# Gets the default install path. This can be overridden when calling the
# download script by passing the VPM_DIR variable.
function VPM_INSTALL_DIR() {
  printf %s "${VPM_DIR:-"$HOME/.vpm"}"
}

# Download command (curl or wget).
function vpm_download_command() {
  if VPM_HAS "curl"; then
    curl --compressed -q "$@"
  elif VPM_HAS "wget"; then
    # Emulate curl with wget
    ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                                   -e 's/-L //' \
                                   -e 's/--compressed //' \
                                   -e 's/-I /--server-response /' \
                                   -e 's/-s /-q /' \
                                   -e 's/-o /-O /' \
                                   -e 's/-C - /-c /')
    eval wget $ARGS
  fi
}

# Installs vpm as a script.
function vpm_install() {
  local dest="$(VPM_INSTALL_DIR)"

  mkdir -p "$dest"

  if [ -f "$dest/vpm.sh" ]; then
    echo -e "${COLOR_BLUE}vpm: vpm ${COLOR_ORANGE}is already installed in ${COLOR_CYAN}$dest${COLOR_ORANGE}, updating it instead...${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}Downloading ${COLOR_BLUE}vpm${COLOR_RESET} to ${COLOR_CYAN}$dest${COLOR_RESET}"
  fi

  # Download the script.
  vpm_download_command -s "$VPM_SOURCE" -o "$dest/vpm.sh" || {
    echo >&2 "${COLOR_BLUE}vpm: ${COLOR_RED}Failed to download from ${COLOR_CYAN}$VPM_SOURCE${COLOR_RESET}"
    return 1
  } &
  for job in $(jobs -p | sort)
  do
    wait "$job" || return $?
  done

  # Make script executable.
  chmod a+x "$dest/vpm.sh" || {
    echo >&2 "${COLOR_BLUE}vpm: ${COLOR_RED}Failed to mark ${COLOR_CYAN}$dest/vpm.sh${COLOR_RESET} as executable"
    return 3
  }
}

# Main process
function main() {
  # Download and install the script.
  if VPM_HAS vpm_download_command; then
    vpm_install
  else
    echo >&2 "${COLOR_BLUE}vpm: ${COLOR_RED}You need ${COLOR_CYAN}curl${COLOR_RED} or ${COLOR_CYAN}wget${COLOR_RED} to install ${COLOR_BLUE}vpm${COLOR_RESET}"
    exit 1
  fi

  # Edit profile file to set up vpm.
  local dest="$(VPM_INSTALL_DIR)"
  local profile=''
  local sourcestr="\nalias vpm='. ${dest}/vpm.sh'\n"

  if [ -f "$HOME/.profile" ]; then
    profile="$HOME/.profile"
  elif [ -f "$HOME/.bashrc" ]; then
    profile="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    profile="$HOME/.bash_profile"
  else
    echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}Profile not found, tried ${COLOR_CYAN}~/.profile${COLOR_RESET}, ${COLOR_CYAN}~/.bashrc${COLOR_RESET} and ${COLOR_CYAN}~/.bash_profile${COLOR_RESET}"
    echo -e "     Create one of them and run this script again"
    echo -e "     OR"
    echo -e "     Append the following lines to the correct file yourself:"
    echo -e "     ${COLOR_CYAN}${sourcestr}${COLOR_RESET}"
    exit 1
  fi

  if ! command grep -qc '/vpm.sh' "$profile"; then
    echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}Appending ${COLOR_BLUE}vpm${COLOR_RESET} source string to ${COLOR_CYAN}$profile${COLOR_RESET}"
    command printf "${sourcestr}" >> "$profile"
  else
    echo -e "${COLOR_BLUE}vpm: vpm ${COLOR_RESET}source string is already in ${COLOR_CYAN}$profile${COLOR_RESET}"
  fi

  # Source vpm
  \. "$dest/vpm.sh"

  echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}Installation complete. Close and reopen your terminal to start using ${COLOR_BLUE}vpm${COLOR_RESET}"
}

main

} # This ensures the entire script is downloaded #