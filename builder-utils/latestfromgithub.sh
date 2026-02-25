#!/bin/bash

# Try to download a pre-built package from packages.123tech.net (SkySTACK repo)
# Returns 0 if found and downloaded, 1 if not available — caller falls back to build from source
# Requires: $SKYCAIR_REPO_CUSTOM $MODULEPATH $ARCH set by setflags.sh
TryPrebuiltFromSkyRepo() {
	local project="$1"
	local version="$2"
	local pkgname="${project}-${version}-${ARCH}-1_skycair.txz"
	local url="${SKYCAIR_REPO_CUSTOM}/packages/${pkgname}"

	[ -z "${SKYCAIR_REPO_CUSTOM:-}" ] && return 1

	if wget -q --spider "${url}" > /dev/null 2>&1; then
		echo "SkyRepo: found pre-built ${pkgname} — downloading"
		mkdir -p "${MODULEPATH}/packages"
		wget -q -O "${MODULEPATH}/packages/${pkgname}" "${url}" && return 0
	fi
	echo "SkyRepo: ${pkgname} not in repo — building from source"
	return 1
}

GetLatestVersionTagFromGithub() {
	repository="$1"
	project="$2"
	filterOutVersion="$3"
	versions=$(curl -s https://github.com/${repository}/${project}/tags/ | grep -oP "(?<=/${repository}/${project}/releases/tag/)[^\"]+" | uniq | grep -v "alpha" | grep -v "beta" | grep -v "rc[0-9]")
	[ -n "$filterOutVersion" ] && versions=$(echo "$versions" | grep -Ev "$filterOutVersion")
	versionNormalized=$(echo "${versions//_/.}" | sort -V -r | head -n 1)
	[[ ${versions} == *"${versionNormalized}"* ]] && version=${versionNormalized} || version=${versionNormalized//./_}

	echo "${version}"
}

DownloadLatestFromGithub() {
	repository="$1"
	project="$2"
	filterOutVersion="$3"
	filename=
	version=$(GetLatestVersionTagFromGithub "${repository}" "${project}" "${filterOutVersion}")
	releaseUrl="https://github.com/${repository}/${project}/releases/download/${version}/${project}-${version//[^0-9._]/}.tar"
	tagUrl="https://github.com/${repository}/${project}/archive/refs/tags/${version}.tar.gz"
	validUrl=

	if wget --spider "${releaseUrl}.xz" > /dev/null 2>&1; then
		validUrl="${releaseUrl}.xz"
	elif wget --spider "${releaseUrl}.gz" > /dev/null 2>&1; then
		validUrl="${releaseUrl}.gz"
	else
		validUrl=${tagUrl}
	fi

	contentDisposition=$(wget --server-response --content-disposition $validUrl 2>&1 | grep -i "content-disposition:")

	filename=${contentDisposition#*filename=}
	version="${version//[^0-9._]/}"

	echo "$filename $version"
}
