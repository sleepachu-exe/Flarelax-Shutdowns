#!/bin/bash

display() {
    echo -e "\033c"
    echo "
    ==========================================================================

 Flarelax Free Host

    =========================================================================="
}

forceStuffs() {
mkdir -p plugins && mkdir -p plugins/noMemberShutdown
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

# Detect and remove corrupt server.jar (less than 1MB = bad download)
if [ -e "server.jar" ]; then
    SIZE=$(wc -c < "server.jar")
    if [ "$SIZE" -lt 1000000 ]; then
        echo "Corrupt server.jar detected (${SIZE} bytes). Removing and re-downloading..."
        rm -f server.jar
    fi
fi

if [ ! -e "server.jar" ]; then
    display
    echo "Downloading PaperMC ${MINECRAFT_VERSION}..."
    sleep 2
    forceStuffs

    # Use python3 to parse JSON - no jq needed!
    API_RESPONSE=$(curl -s https://api.papermc.io/v2/projects/paper)
    LATEST_VERSION=$(echo "$API_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['versions'][-1])")

    if [ "$MINECRAFT_VERSION" = "latest" ] || [ -z "$MINECRAFT_VERSION" ]; then
        MINECRAFT_VERSION=$LATEST_VERSION
    else
        # Check if version exists
        VER_EXISTS=$(echo "$API_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print('true' if '$MINECRAFT_VERSION' in d['versions'] else 'false')" 2>/dev/null)
        if [ "$VER_EXISTS" != "true" ]; then
            echo "Version $MINECRAFT_VERSION not found. Using latest: $LATEST_VERSION"
            MINECRAFT_VERSION=$LATEST_VERSION
        fi
    fi

    echo "Using PaperMC version: $MINECRAFT_VERSION"

    BUILD_NUMBER=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['builds'][-1])")
    JAR_NAME="paper-${MINECRAFT_VERSION}-${BUILD_NUMBER}.jar"
    DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}/builds/${BUILD_NUMBER}/downloads/${JAR_NAME}"

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
