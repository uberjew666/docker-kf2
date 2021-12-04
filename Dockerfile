FROM cm2network/steamcmd:root

RUN apt-get update -y               \
    && apt-get install -y           \
    wget lib32gcc1 libcurl4         \
    dos2unix gosu crudini sudo      \
    procps less                     \
    && apt-get clean                \
    && rm -rfv /var/lib/apt/lists/*

ENV PUID=1000                                                                \
    PGID=1000                                                                \
    TZ="Europe/London"                                                       \
    KF_MAP="KF-BioticsLab"                                                   \
    KF_DIFFICULTY="Normal"                                                   \
    KF_ADMIN_PASS="secret"                                                   \
    KF_GAME_PASS=""                                                          \
    KF_GAME_LENGTH="Normal"                                                  \
    KF_GAME_MODE="Survival"                                                  \
    KF_PORT="7777"                                                           \
    KF_MUTATORS=""                                                           \
    KF_SERVER_NAME="KF2"                                                     \
    KF_UPDATE_SERVER="false"                                                 \
    KF_ENABLE_BETA="false"                                                   \
    KF_ENABLE_WEB="false"                                                    \
    KF_WEBADMIN_PORT="8080"                                                  \
    KF_DISABLE_TAKEOVER="false"                                              \
    KF_BANNER_LINK="http://art.tripwirecdn.com/TestItemIcons/MOTDServer.png" \
    KF_MOTD="Welcome to our server. \n \n Have fun and good luck!"           \
    KF_WEBSITE_LINK="http://killingfloor2.com"                               \
    MULTIHOME_IP=""

ADD entrypoint.sh /entrypoint.sh
ADD start_kf2.sh /start_kf2.sh

RUN usermod -u ${PUID} steam     \
    && groupmod -g ${PGID} steam \
    && chsh -s /bin/bash steam   \
    && chmod 755 /entrypoint.sh  \
    && chmod 755 /start_kf2.sh   \
    && dos2unix /entrypoint.sh

ENTRYPOINT ["/bin/bash","/entrypoint.sh"]
