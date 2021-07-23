#!/usr/bin/env bash
cd /home/steam/kf2server || exit 1
STEAM_UID=${PUID:=1000}
STEAM_GID=${PGID:=1000}

log() {
  PREFIX="[Killing Floor 2][steam]"
  printf "%-16s: %s\n" "${PREFIX}" "$1"
}

line() {
  log "###########################################################################"
}

initialize() {
  line
  log "Killing Floor 2 Server - $(date)"
  log "STEAM_UID ${STEAM_UID} - STEAM_GUID ${STEAM_GID}"
  log "$1"
  line
}

log "Variables loaded..."
log "Port: ${KF_PORT}"
log "Name: ${KF_SERVER_NAME}"
log "Mode: ${KF_GAME_MODE}"
log "Password: (REDACTED)"

log "Running Install... (be patient, 16 GB+)"

# Install server using steamcmd
if [[ ! -f "/home/steam/kf2server/Binaries/Win64/KFGameSteamServer.bin.x86_64" ]]; then
  cd "/home/steam/steamcmd" || exit 1
  ./steamcmd.sh                              \
  +login anonymous                           \
  +force_install_dir "/home/steam/kf2server" \
  +app_update 232130 validate +exit
else
  log "Skipping install process, looks like kf2server is already installed"
fi

# Forcely update server using steamcmd
if [[ "${KF_UPDATE_SERVER}" == 'true' ]]; then
  log "Attempting to update before launching the server!"
  rm -rf "/home/steam/Steam/steamapps"
  cd "/home/steam/steamcmd" || exit 1
  ./steamcmd.sh                              \
  +login anonymous                           \
  +force_install_dir "/home/steam/kf2server" \
  +app_update 232130 update validate +exit
fi

cp --force /home/steam/steamcmd/linux64/steamclient.so /home/steam/kf2server/Binaries/Win64/lib64/steamclient.so
cp --force /home/steam/steamcmd/linux64/steamclient.so /home/steam/kf2server/linux64/steamclient.so
cp --force /home/steam/steamcmd/linux64/steamclient.so /home/steam/kf2server/steamclient.so

# Generate configuration files
if [[ ! -f "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" ]]; then
  log "It appears the config file is missing, generating..."
  "/home/steam/kf2server/Binaries/Win64/KFGameSteamServer.bin.x86_64" kf-bioticslab?difficulty=0?adminpassword=secret?gamepassword=secret -port=7777 &
  sleep 20
  KFPID=$(pgrep -f port=7777)
  kill "${KFPID}"
  log "Configuration files generated"
fi

# Update configuration files
if [[ -f "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" ]] ||
   [[ -f "/home/steam/kf2server/KFGame/Config/LinuxServer-KFEngine.ini" ]] ||
   [[ -f "/home/steam/kf2server/KFGame/Config/LinuxServer-KFWeb.ini" ]]; then

  log "Updating configuration files..."

  if [[ "${KF_GAME_MODE}" == 'VersusSurvival' ]]; then
    KF_GAME_MODE='VersusSurvival?maxplayers=12';
  fi

  # default to $(($KF_PORT + 19238))
  [[ -z "${KF_QUERY_PORT}" ]] && export KF_QUERY_PORT="$((KF_PORT + 19238))"

  crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" KFGame.KFGameInfo GameLength "${KF_GAMELENGTH}"
  crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" Engine.GameReplicationInfo ServerName "${KF_SERVER_NAME}"
  crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" KFGame.KFGameInfo BannerLink "${KF_BANNER_LINK}"
  crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" KFGame.KFGameInfo ServerMOTD "${KF_MOTD}"
  crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFGame.ini" KFGame.KFGameInfo WebsiteLink "${KF_WEBSITE_LINK}"

  crudini --set --existing "/home/steam/kf2server/KFGame/Config/KFWeb.ini" IpDrv.WebServer bEnabled "${KF_ENABLE_WEB}"

  # remove both existing DownloadManagers parameters
  crudini --del "/home/steam/kf2server/KFGame/Config/LinuxServer-KFEngine.ini" IpDrv.TcpNetDriver DownloadManagers
  crudini --set "/home/steam/kf2server/KFGame/Config/LinuxServer-KFEngine.ini" IpDrv.TcpNetDriver DownloadManagers OnlineSubsystemSteamworks.SteamWorkshopDownload
  if [[ "${KF_DISABLE_TAKEOVER}" == 'true' ]]; then
    crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFEngine.ini" Engine.GameEngine bUsedForTakeover "FALSE"
  else
    crudini --set --existing "/home/steam/kf2server/KFGame/Config/LinuxServer-KFEngine.ini" Engine.GameEngine bUsedForTakeover "TRUE"
  fi

  log "All configuration files have been updated"
else
  log "One or several configuration files are not present. Exiting.."
  exit 1
fi

line
log "Launching the server"
export WINEDEBUG=fixme-all

cmd="/home/steam/kf2server/Binaries/Win64/KFGameSteamServer.bin.x86_64 "
cmd+="${KF_MAP}?Game=KFGameContent.KFGameInfo_${KF_GAME_MODE}"
cmd+="?Difficulty=${KF_DIFFICULTY}"
cmd+="?AdminPassword=${KF_ADMIN_PASS}"
[[ -z "${MULTIHOME_IP}" ]] || cmd+="?Multihome=${MULTIHOME_IP}"
[[ -z "${KF_MUTATORS}" ]] || cmd+="?Mutator=${KF_MUTATORS}"
[[ -z "${KF_GAME_PASS}" ]] || cmd+="?GamePassword=${KF_GAME_PASS}"
cmd+=" -Port=${KF_PORT}"
cmd+=" -WebAdminPort=${KF_WEBADMIN_PORT}"
cmd+=" -QueryPort=${KF_QUERY_PORT}"

exec $cmd
