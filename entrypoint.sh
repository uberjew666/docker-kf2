#!/usr/bin/env bash

# Set up timezone
ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" >/etc/timezone

if [ "${EUID}" -ne 0 ]; then
  log "Please run as root"
  exit
fi

log() {
  PREFIX="[Killing Floor 2][root]"
  printf "%-16s: %s\n" "${PREFIX}" "$1"
}

line() {
  log "###########################################################################"
}

check_memory() {
  MEMORY=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))
  MESSAGE="Your system has less than 2GB of ram!!\nValheim might not run on your system!!"
  if [ $MEMORY -lt 2000 ]; then
    line
    log "${MESSAGE^^}"
    line
    line
  fi
}

setup_filesystem() {
  log "Setting up file systems"
  STEAM_UID=${PUID:=1000}
  STEAM_GID=${PGID:=1000}

  # Maps
  mkdir -p "/home/steam/kf2server/KFGame/BrewedPC/Maps"

  # Workshop
  mkdir -p "/home/steam/kf2server/Binaries/Win64/steamapps/workshop"

  # Cache
  mkdir -p "/home/steam/kf2server/KFGame/Cache"

  # Other
  chown -R ${STEAM_UID}:${STEAM_GID} "/home/steam/"
}


line
log "Killing Floor 2 server - $(date)"
log "Initialising your container..."
check_memory
line

log "Switching UID and GID"
log "$(usermod -u ${PUID} steam)"
log "$(groupmod -g ${PGID} steam)"

setup_filesystem

# Launch as steam user :)
log "Navigating to steam home..."
cd /home/steam/kf2server || exit 1

log "Launching as steam..."
exec gosu steam /start_kf2.sh
