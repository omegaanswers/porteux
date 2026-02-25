#!/bin/bash

SetFlags() {
	MODULENAME="$1"

	export KERNELVERSION="6.18.8"
	export ARCHITECTURELEVEL="x86-64-v2"
	export GCCFLAGS="-O3 -march=$ARCHITECTURELEVEL -mtune=generic -fno-semantic-interposition -fno-trapping-math -ftree-vectorize -fno-unwind-tables -fno-asynchronous-unwind-tables -ffunction-sections -fdata-sections -flto=auto -fno-plt -fipa-pta -fno-ident -fmodulo-sched -floop-parallelize-all -fuse-linker-plugin"
	export LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -Wl,--build-id=none -Wl,-O2 -Wl,--strip-all -Wl,--sort-section=alignment -Wl,-z,pack-relative-relocs -Wl,-sort-common"
	export CLANGFLAGS="-O3 -march=$ARCHITECTURELEVEL -mtune=generic -fno-semantic-interposition -fno-trapping-math -ftree-vectorize -fno-unwind-tables -fno-asynchronous-unwind-tables -ffunction-sections -fdata-sections -flto=auto -fno-plt -faddrsig -Wno-unused-command-line-argument"
	export LLDFLAGS="${LDFLAGS/-Wl,-sort-common/} -fuse-ld=lld -Wl,--icf=safe -Wl,--lto-O3"
	export RUSTFLAGS="-Copt-level=3 -Ctarget-cpu=$ARCHITECTURELEVEL -Ztune-cpu=generic -Cstrip=symbols -Clink-arg=-ffunction-sections -Clink-arg=-fdata-sections -Cforce-unwind-tables=no -Clto=fat -Clinker=clang -Clink-arg=-fuse-ld=lld -Clink-arg=-Wl,--gc-sections -Clink-arg=-Wl,-O2 -Clink-arg=-Wl,--strip-all -Clink-arg=-Wl,--icf=safe -Clink-arg=-Wl,--lto-O3 -Cpanic=abort -Cdebuginfo=0 -Cembed-bitcode=yes -Zdylib-lto -Zlocation-detail=none -Ccodegen-units=1"
	export RUSTC_BOOTSTRAP=1 # allows -Z unstable flags on stable compiler
	
	current_folder=$(dirname "$(realpath "$0")")
	git config --global --add safe.directory "${current_folder}"/.. 2>/dev/null
	export SKYCAIRVERSION=$(git -C "${current_folder}"/.. branch --show-current)
	[ ! $SKYCAIRVERSION ] && SKYCAIRVERSION=$(date -r . +%Y%m%d)
	slackware_full_version=$(cat /etc/slackware-version)
	slackware_version=${slackware_full_version//* }

	if [[ $slackware_version == *"+" ]]; then
		export SLACKWAREVERSION=current
		export SKYCAIRBUILD=current		
	else
		echo "Fatal error: SkyCAIR can only be built in Slackware current environment." && exit 1
	fi

	export SCRIPTPATH="$PWD"
	export SKYCAIRBUILDERPATH="/tmp/skycair-builder-$SKYCAIRVERSION"
	export MODULEPATH="$SKYCAIRBUILDERPATH/$MODULENAME"
	export BUILDERUTILSPATH="$SCRIPTPATH/../builder-utils"

	export ARCH=$(uname -m)
	export NUMBERTHREADS=$(nproc --all)
	export MAKEPKGFLAGS="-l y -c n --compress -0"

	if [ -z ${SYSTEMBITS+x} ] && [ "$(getconf LONG_BIT)" = "64" ]; then
		export SYSTEMBITS="64"
	fi

	# SkySTACK controlled repository — packages.123tech.net
	# SkyNetSSL verified: all packages scanned before serving
	# Falls back to public mirrors if internal repo is unreachable
	export SKYCAIR_REPO_DOMAIN="https://packages.123tech.net"
	export SKYCAIR_REPO_SLACKWARE="$SKYCAIR_REPO_DOMAIN/slackware/slackware$SYSTEMBITS-$SLACKWAREVERSION/slackware$SYSTEMBITS"
	export SKYCAIR_REPO_CUSTOM="$SKYCAIR_REPO_DOMAIN/skycair"
	export SKYCAIR_REPO_SKYMOD="$SKYCAIR_REPO_DOMAIN/skymod"

	# Fallback public mirrors (used if packages.123tech.net unreachable)
	export SLACKWAREDOMAIN_FALLBACK_1="https://mirrors.slackware.com"
	export SLACKWAREDOMAIN_FALLBACK_2="https://slackware.uk"

	# Active repository — try SkySTACK first, fallback to public
	if curl -sf --max-time 5 "$SKYCAIR_REPO_DOMAIN/health" > /dev/null 2>&1; then
		export SLACKWAREDOMAIN="$SKYCAIR_REPO_DOMAIN"
		export REPOSITORY="$SKYCAIR_REPO_SLACKWARE"
		echo "Using SkySTACK repository: $SKYCAIR_REPO_DOMAIN"
	else
		export SLACKWAREDOMAIN="$SLACKWAREDOMAIN_FALLBACK_1"
		export REPOSITORY="$SLACKWAREDOMAIN/slackware/slackware$SYSTEMBITS-$SLACKWAREVERSION/slackware$SYSTEMBITS"
		echo "WARNING: packages.123tech.net unreachable — using fallback mirror: $SLACKWAREDOMAIN"
	fi
}
