#!/bin/bash

# Define variables
CHROOT_DIR="/var/chroot"
DEBIAN_RELEASE="buster" # Change this to your desired Debian release
ARCH="amd64"            # Change this to your desired architecture

# Function to check if the script is run as root
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
  fi
}

# Function to create the chroot directory
create_chroot_directory() {
  if [ ! -d "$CHROOT_DIR" ]; then
    mkdir -p "$CHROOT_DIR"
    echo "Created chroot directory at $CHROOT_DIR"
  else
    echo "Chroot directory already exists at $CHROOT_DIR"
  fi
}

# Function to install debootstrap if not already installed
install_debootstrap() {
  if ! command -v debootstrap &> /dev/null; then
    echo "debootstrap not found, installing..."
    apt-get update
    apt-get install -y debootstrap
  else
    echo "debootstrap is already installed"
  fi
}

# Function to create the chroot environment using debootstrap
create_chroot() {
  echo "Creating chroot environment..."
  debootstrap --arch="$ARCH" "$DEBIAN_RELEASE" "$CHROOT_DIR" http://deb.debian.org/debian
}

# Function to setup basic directories and files
setup_chroot() {
  echo "Setting up basic directories and files in chroot environment..."

  for dir in /proc /sys /dev /dev/pts; do
    mkdir -p "$CHROOT_DIR/$dir"
  done

  mount -t proc /proc "$CHROOT_DIR/proc"
  mount --rbind /sys "$CHROOT_DIR/sys"
  mount --rbind /dev "$CHROOT_DIR/dev"

  cp /etc/resolv.conf "$CHROOT_DIR/etc/"
  cp /etc/hosts "$CHROOT_DIR/etc/"

  echo "Basic setup complete"
}

# Function to enter the chroot environment
enter_chroot() {
  echo "Entering chroot environment. Type 'exit' to leave."
  chroot "$CHROOT_DIR" /bin/bash
}

# Main function
main() {
  check_root
  create_chroot_directory
  install_debootstrap
  create_chroot
  setup_chroot
  enter_chroot
}

main "$@"
