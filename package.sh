#!/bin/bash

$UE_ROOT/Engine/Build/BatchFiles/RunUAT.sh BuildCookRun \
    -Server -NoClient -ServerConfig=Shipping \
    -Project=$PROJECT_PATH \
    -UTF8Output -NoDebugInfo -AllMaps -NoP4 -Build -Cook -Stage -Pak -Package -Archive \
    -ArchiveDirectory=$ARCHIVE_DIR \
    -Platform=Linux \
    -Target=$TARGET


LIBRARY_DIR="Plugins/GameLiftServerSDK/ThirdParty/GameLiftServerSDK/Linux/x86_64-unknown-linux-gnu"
CRYPTO_PATH="$LIBRARY_DIR/libcrypto.so.1.1"
SSL_PATH="$LIBRARY_DIR/libssl.so.1.1"
PROJECT_FILE_NAME=$(basename $PROJECT_PATH)
PROJECT_NAME=${PROJECT_FILE_NAME%.*}

# Copies crypto library to archive
echo Copying $(dirname $PROJECT_PATH)/$CRYPTO_PATH to $ARCHIVE_DIR/LinuxServer/$PROJECT_NAME/$CRYPTO_PATH
cp "$(dirname $PROJECT_PATH)/$CRYPTO_PATH" "$ARCHIVE_DIR/LinuxServer/$PROJECT_NAME/$CRYPTO_PATH"

# Copies ssl library to archive
echo Copying $(dirname $PROJECT_PATH)/$SSL_PATH to $ARCHIVE_DIR/LinuxServer/$PROJECT_NAME/$SSL_PATH
cp "$(dirname $PROJECT_PATH)/$SSL_PATH" "$ARCHIVE_DIR/LinuxServer/$PROJECT_NAME/$SSL_PATH"

# Copies install.sh to archive
INSTALL_SH_DIR="$(dirname $PROJECT_PATH)/Scripts/install.sh"
echo Copying "$INSTALL_SH_DIR" to "$ARCHIVE_DIR/LinuxServer/install.sh"
cp $INSTALL_SH_DIR $ARCHIVE_DIR/LinuxServer/install.sh