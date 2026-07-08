#!/bin/bash

display() {
    echo -e "\033c"
    echo "
    ==========================================================================

 Flarelax Free Host

    =========================================================================="
}

forceStuffs() {
    mkdir -p plugins/noMemberShutdown
    cd plugins && curl -O https://cdn.modrinth.com/data/DgUoVPBP/versions/QucVTrXS/IdleServerShutdown-1.3.jar && cd ..
    cd plugins/noMemberShutdown && curl -O https://raw.githubusercontent.com/AvexXS/SovietEgg/main/config.yml && cd ../..
    echo "eula=true" > eula.txt
}

launchJavaServer() {
    number=200
    memory=$((SERVER_MEMORY - number))
    java -Xms128M -Xmx${memory}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
        -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 \
        -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 \
        -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 \
        -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 \
        -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \
        -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true \
        -jar server.jar nogui
}

optimizeJavaServer() {
    echo "view-distance=6" >> server.properties
}

# Get latest Paper version using grep/sed only (no jq or python3 needed)
getLatestPaperVersion() {
    curl -s https://api.papermc.io/v2/projects/paper \
        | grep -o '"versions":\[[^]]*\]' \
        | grep -o '"[0-9][^"]*"' \
        | tail -1 \
        | tr -d '"'
}

# Get latest build number for a given version using grep/sed only
getLatestBuild() {
    curl -s "https://api.papermc.io/v2/projects/paper/versions/$1" \
        | grep -o '"builds":\[[^]]*\]' \
        | grep -o '[0-9]*' \
        | tail -1
}

# Remove corrupt server.jar if less than 1MB
if [ -e "server.jar" ]; then
    SIZE=$(wc -c < "server.jar")
    if [ "$SIZE" -lt 1000000 ]; then
        echo "Corrupt server.jar (${SIZE} bytes). Removing..."
        rm -f server.jar
    fi
fi

if [ ! -e "server.jar" ]; then
    display
    echo "Downloading PaperMC ${MINECRAFT_VERSION}..."
    sleep 2

    forceStuffs

    LATEST_VERSION=$(getLatestPaperVersion)
    echo "Latest available version: $LATEST_VERSION"

    if [ "$MINECRAFT_VERSION" = "latest" ] || [ -z "$MINECRAFT_VERSION" ]; then
        MINECRAFT_VERSION=$LATEST_VERSION
    fi

    echo "Using PaperMC version: $MINECRAFT_VERSION"

    BUILD_NUMBER=$(getLatestBuild "$MINECRAFT_VERSION")
    echo "Using build: $BUILD_NUMBER"

    DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}/builds/${BUILD_NUMBER}/downloads/paper-${MINECRAFT_VERSION}-${BUILD_NUMBER}.jar"
    echo "Downloading: $DOWNLOAD_URL"

    curl --progress-bar -o server.jar "$DOWNLOAD_URL"

    display
    optimizeJavaServer
    launchJavaServer
else
    display
    forceStuffs
    launchJavaServer
fi
