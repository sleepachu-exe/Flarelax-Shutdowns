#!/bin/bash

display() {
    echo -e "\033c"
    echo "
    ==========================================================================
  
$(tput setaf 6) Flarelax Free Host
$(tput setaf 6) 
    ==========================================================================
    "  
}

forceStuffs() {
mkdir -p plugins && mkdir -p plugins/noMemberShutdown
cd plugins && curl -O https://cdn.modrinth.com/data/DgUoVPBP/versions/QucVTrXS/IdleServerShutdown-1.3.jar && cd ../.
cd plugins && cd noMemberShutdown && curl -O https://raw.githubusercontent.com/AvexXS/SovietEgg/main/config.yml && cd ../. && cd ../.
echo "eula=true" > eula.txt
}

# Install functions
installJq() {
if [ ! -e "tmp/jq" ]; then
mkdir -p tmp
curl -s -o tmp/jq -L https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
chmod +x tmp/jq
fi
}

# Useful functions
jq() {
    tmp/jq "$@"
}

# Launch functions
launchJavaServer() {
  # Remove 200 mb to prevent server freeze
  number=200
  memory=$((SERVER_MEMORY - number))
  
  java -Xms128M -Xmx${memory}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui
}

optimizeJavaServer() {
  echo "view-distance=6" >> server.properties
}


# If server.jar exists but is too small (corrupt), delete it to force re-download
if [ -e "server.jar" ]; then
    SIZE=$(wc -c < "server.jar")
    if [ "$SIZE" -lt 1000000 ]; then
        echo "server.jar is corrupt (${SIZE} bytes). Deleting and re-downloading..."
        rm -f server.jar
    fi
fi

if [ ! -e "server.jar" ]; then
    display

    echo "Starting the download for PaperMC ${MINECRAFT_VERSION} please wait"

    sleep 4

    forceStuffs

    installJq

    VER_EXISTS=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r --arg VERSION $MINECRAFT_VERSION '.versions[] | contains($VERSION)' | grep -m1 true)
	LATEST_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions' | jq -r '.[-1]')

	if [ "${VER_EXISTS}" == "true" ]; then
		echo -e "Version is valid. Using version ${MINECRAFT_VERSION}"
	else
		echo -e "Specified version not found. Defaulting to the latest paper version"
		MINECRAFT_VERSION=${LATEST_VERSION}
	fi

	BUILD_NUMBER=$(curl -s https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION} | jq -r '.builds' | jq -r '.[-1]')
	JAR_NAME=paper-${MINECRAFT_VERSION}-${BUILD_NUMBER}.jar
	DOWNLOAD_URL=https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}/builds/${BUILD_NUMBER}/downloads/${JAR_NAME}

	curl -o server.jar "${DOWNLOAD_URL}"

    display

    echo -e ""

    optimizeJavaServer
    launchJavaServer
    forceStuffs
else
    display
    forceStuffs
    launchJavaServer
fi
