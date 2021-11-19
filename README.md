docker-kf2server
==========

Dockerfile for running a Killing Floor 2 server

* GitHub: https://github.com/uberjew666/docker-kf2server
* Docker Hub: https://hub.docker.com/r/uberjew666/kf2server

Requirements
------------

2GB RAM and 20GB free disk space are essential. SSD recommended, otherwise map
changes will take a long time. Disk space requirements will keep going up as 
updates are released.

**RHEL Host Nodes**
------------
A couple of amendments specific to RHEL and any offshoots:

To allow an IPv4 address to be shared with containers on a RHEL host, you need to ensure that `net.ipv4.ip_forward` is enabled. This can be set using `sysctl -w net.ipv4.ip_forward=1`. Afterwards, you must restart docker `systemctl restart docker` or `service docker restart` depending on if you are using init.d or systemd.

With docker `-v` mounts you can add `:z` to the end of the mount argument to add the relevant SELinux contexts to use the bind mount automatically. For example `-v $HOME/kf2:/home/steam/kf2server` becomes `-v $HOME/kf2:/home/steam/kf2server:z`.


Simple start
------------

    mkdir -p $HOME/kf2
    docker run -d -t --name kf2server \
        -p 0.0.0.0:20560:20560/udp \
        -p 0.0.0.0:27015:27015/udp \
        -p 0.0.0.0:7777:7777/udp \
        -p 0.0.0.0:8080:8080 \
        -v $HOME/kf2:/home/steam/kf2server \
        uberjew666/kf2server:latest

Configuring the server
----------------------

Configuration is done via environment variables. To run a long, hard server:

    docker run -d -t --name kf2server \
        -p 0.0.0.0:20560:20560/udp \
        -p 0.0.0.0:27015:27015/udp \
        -p 0.0.0.0:7777:7777/udp \
        -p 0.0.0.0:8080:8080 \
        -v $HOME/kf2:/home/steam/kf2server \
        -e KF_DIFFICULTY=hard \
        -e KF_GAME_LENGTH=long \
        uberjew666/kf2server:latest

Updating the server
-------------------

Set the KF_UPDATE_SERVER environmental variable to true:

    docker run -d -t --name kf2 -p 0.0.0.0:20560:20560/udp \
        -p 0.0.0.0:27015:27015/udp \
        -p 0.0.0.0:7777:7777/udp \
        -p 0.0.0.0:8080:8080 \
        -v $HOME/kf2:/home/steam/kf2server \
        -v $HOME/kf2_steamdir:/home/steam/steam \
        -e KF_UPDATE_SERVER=true \
        uberjew666/kf2server:latest

Variables
---------

| Variable              | Default           | Description                                                                                                                                                                                                |
|-----------------------|-------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `KF_MAP`              | `KF-BioticsLab`   | Starting map when the server is first loaded.                                                                                                                                                              |
| `KF_DIFFICULTY`       | `normal`          | Game difficulty. * normal * hard * suicidal * hellonearth                                                                                                                                                  |
| `KF_ADMIN_PASS`       | `secret`          | Used for web console and in-game admin logins.                                                                                                                                                             |
| `KF_GAME_PASS`        | `''`              | The password used to access the game. Setting this will make the server "private".                                                                                                                         |
| `KF_GAME_LENGTH`      | `normal`          | The length of the game. * short - 4 waves * normal - 7 waves * long - 10 waves                                                                                                                             |
| `KF_GAME_MODE`        | `Survival`        | The gametype to use. * Survival * VersusSurvival * WeeklySurvival * Endless                                                                                                                                |
| `KF_PORT`             | `7777`            | The game port (UDP) used to accept incoming clients. This is the port entered in the ingame console's `open` command.                                                                                      |
| `KF_QUERY_PORT`       | `KF_PORT + 19238` | The query port used to this server instance.                                                                                                                                                               |
| `KF_MUTATORS`         | `''`              | If the mutators are correctly installed on the server they can be used like this: `mutator=ClassicScoreboard.ClassicSCMut,KFMutator.KFMutator_MaxPlayersV2` Multiple mutators must be seperated with a `,` |
| `KF_SERVER_NAME`      | `KF2`             | The server name to display in the server browser.                                                                                                                                                          |
| `KF_UPDATE_SERVER`    | `false`           | Forces steamcmd to download the server files, even if already installed. Useful for when new event updates are released.                                                                                   |
| `KF_ENABLE_WEB`       | `false`           | A boolean toggle for the web interface hosted on the KF_WEBADMIN_PORT (default 8080) If setting this to true, it's recommended you change the `KF_ADMIN_PASS` variable too.                                |
| `KF_WEBADMIN_PORT`    | `8080`            | The port used to access the web admin interface.                                                                                                                                                           |
| `KF_DISABLE_TAKEOVER` | `false`           | Allows the server to be used by other players looking to create a private game when the server is uninhabited.                                                                                             |
| `KF_BANNER_LINK`      | `http://art.tripwirecdn.com/TestItemIcons/MOTDServer.png` | A link to a PNG file to display on the server welcome page. You must escape special characters.                                                                    |
| `KF_MOTD`             | `Welcome to our server. \n \n Have fun and good luck!` | A MOTD message to show under the banner image on the welcome page. You must escape special characters.                                                                |
| `KF_WEBSITE_LINK`     | `http://killingfloor2.com` | A website link shown at the bottom of the srver welcome page to allow the visitor to go to your site. You must escape special characters.                                                         |
| `MULTIHOME_IP`        | `''`              | Sets the IP to run the server on in cases where it has been assigned multiple public IPs.                                                                                                                  |


Running multiple servers
------------------------

1. Ensure 'KF_UPDATE_SERVER' is not set to 'true'. Updates will be handled from the first server only.
2. Change ports (increment), set environment variables to match
3. Change server name (optional)

Update the volume mounts as follows:

Map the following read-only volume from server 1

 - $HOME/kf2:/home/steam/kf2server:ro \

Map the following read-write volumes

 - $HOME/kf2-server2/kf2server/KFGame/Logs:/home/steam/kf2server/KFGame/Logs
 - $HOME/kf2-server2/kf2server/KFGame/Config:/home/steam/kf2server/KFGame/Config

These are only required for Steam Workshop maps (see below)

 - $HOME/kf2-server2/kf2server/Binaries/Win64/steamapps:/home/steam/kf2server/Binaries/Win64/steamapps
 - $HOME/kf2-server2/kf2server/KFGame/Cache:/home/steam/kf2server/KFGame/Cache

You *must* also copy the basic config files from server1

    mkdir -p $HOME/kf2-server2/kf2server/KFGame/Config
    cp -a $HOME/kf2/kf2server/KFGame/Config/* $HOME/kf2-server2/kf2server/KFGame/Config

Steam Workshop maps
-------------------

Under `kf2server`, modify the file `KFGame/Config/LinuxServer-KFEngine.ini` as per [Tripwire's wiki][1]

Example shown below is for [Biolapse - Biotics Holdout][2] by 

[1]: https://wiki.tripwireinteractive.com/index.php?title=Dedicated_Server_(Killing_Floor_2)#Setting_Up_Steam_Workshop_For_Servers
[2]: http://steamcommunity.com/sharedfiles/filedetails/?id=1258411772


    [OnlineSubsystemSteamworks.KFWorkshopSteamworks]
    ServerSubscribedWorkshopItems=1258411772


You'll also need to add the maps to `LinuxServer-KFGame.ini` as described in the wiki [here][3] and [here][4].

[3]: https://wiki.tripwireinteractive.com/index.php?title=Dedicated_Server_%28Killing_Floor_2%29#Maps
[4]: https://wiki.tripwireinteractive.com/index.php?title=Dedicated_Server_%28Killing_Floor_2%29#Get_Custom_Maps_To_Show_In_Web_Admin

Examples:

    [KFGame.KFGameInfo]
    ...
    GameMapCycles=(Maps=("KF-BurningParis","KF-Biolapse"))
    ...

    [KF-Biolapse KFMapSummary]
    MapName=KF-Biolapse
    ScreenshotPathName=UI_MapPreview_TEX.UI_MapPreview_Placeholder


Building the image
------------------

    docker build -t uberjew666/docker-kf2server:latest .
