#!/bin/bash
# SkyCAIR OS — 003-skyomegai: Download Ollama + Open WebUI dependencies
# Packages are sourced from packages.123tech.net (SkyNetSSL verified)
# with fallback to public Slackware mirrors.
source "$BUILDERUTILSPATH/slackwarerepository.sh"

GenerateRepositoryUrls

# Python runtime for Open WebUI
DownloadPackage "python3" &
DownloadPackage "python-pip" &
DownloadPackage "python-setuptools" &
wait

# HTTP + async runtime
DownloadPackage "curl" &
DownloadPackage "wget" &
DownloadPackage "ca-certificates" &
wait

# Vector math / AI inference dependencies
DownloadPackage "openblas" &
DownloadPackage "lapack" &
DownloadPackage "blas" &
wait

# Shared libraries for Ollama
DownloadPackage "libstdc++" &
DownloadPackage "glibc" &
wait

rm -f FILE_LIST serverPackages.txt
