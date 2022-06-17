#!/bin/bash

# Latest compatible version of packages
# Vanced microG 0.2.24.220220
# YouTube 17.22.36
# YouTube Music 5.03.50

VMG_VERSION="0.2.24.220220"
YT_VERSION="17.22.36"
YTM_VERSION="5.03.50"

echo "Declaring artifacts"
declare -A artifacts

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations app-release-unsigned .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

get_artifact_download_url ()
{
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

echo "Fetching dependencies"
for artifact in "${!artifacts[@]}"
do
    if [ ! -f $artifact ]
    then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

echo "Fetching MicroG"
chmod +x apkeep
if [ ! -f "vanced-microG.apk" ]
then
    echo "Downloading microG"
    ./apkeep -a com.mgoogle.android.gms@$VMG_VERSION .
    mv com.mgoogle.android.gms@$VMG_VERSION.apk vanced-microG.apk
fi

echo "Preparing"
mkdir -p build
available_patches=$(java -jar revanced-cli.jar -b revanced-patches.jar -a a -o b -l | sed -Er  's#\[available\] (.+)#-i \1 #')

echo "Compiling YouTube"
if [ -f "com.google.android.youtube.apk" ]
then
    echo "Compiling root package"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --install \
                               -a com.google.android.youtube.apk -o build/revanced-root.apk
    echo "Compile non-root package"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --install \
                               $available_patches \
                               -a com.google.android.youtube.apk -o build/revanced-nonroot.apk
else
    echo "Cannot find YouTube base package, skip compiling"
fi

echo "Compiling YouTube Music"
if [ -f "com.google.android.apps.youtube.music.apk" ]
then
    echo "Compiling root package"
    java -jar revanced-cli.jar -b revanced-patches.jar --install \
                               -a com.google.android.apps.youtube.music.apk -o build/revanced-music-root.apk
    echo "Compile non-root package"
    java -jar revanced-cli.jar -b revanced-patches.jar --install \
                               $available_patches \
                               -a com.google.android.apps.youtube.music.apk -o build/revanced-music-nonroot.apk
else
    echo "Cannot find YouTube Music base APK, skip compiling"
fi

echo "Done compiling"