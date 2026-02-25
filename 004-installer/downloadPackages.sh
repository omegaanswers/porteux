#!/bin/bash
# SkyCAIR OS — 004-installer: Download Calamares packages
# These packages are pulled from the SkySTACK package repository
# (packages.123tech.net) and fall back to public Slackware mirrors.
source "$BUILDERUTILSPATH/slackwarerepository.sh"

GenerateRepositoryUrls

# Dependencies required by Calamares
DownloadPackage "kpmcore" &
DownloadPackage "boost" &
DownloadPackage "yaml-cpp" &
DownloadPackage "icu4c" &
wait
DownloadPackage "polkit-qt5" &
DownloadPackage "qt5" &
DownloadPackage "extra-cmake-modules" &
DownloadPackage "plasma-framework" &
wait
DownloadPackage "libpwquality" &
DownloadPackage "parted" &
wait

### Clean up repository index
rm -f FILE_LIST serverPackages.txt
