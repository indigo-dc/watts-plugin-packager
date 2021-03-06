#!/bin/bash
#
# Package WaTTS plugins for pacman, apt and yum.
#
# Author: Joshua Bachmeier <uwdkl@student.kit.edu>
#

if [[ $# -le 1 ]]
then
    echo $0: "Auto selecting package manager ..."
    if which makepkg &>/dev/null;  then $0 arch $@; built=yes; fi
    if which dpkg-deb &>/dev/null; then $0 deb $@;  built=yes; fi
    if which rpmbuild &>/dev/null; then $0 rpm $@;  built=yes; fi
    if [[ -z $built ]]
    then echo $0: "ERROR: Don't know how to build packages on your distro"; exit 1
    fi
else
    type=$1; shift
    conf=$1; shift
    curl_args=$@

    # Note: RPM spec files have a problem with empty dependencies,
    # so we add at least "yum" which should be installed anyway and is arch independent
    export CONFIG=$(
        if   [[ -f $conf ]];       then jq -c . "$conf"
        elif [[ $conf =~ ^http ]]; then curl -fL $curl_args "$conf"
        fi | (if [[ $(jq -V 2>&1 | cut -d' ' -f3) < "1.4" ]]
              then echo $0: WARNING: "Can't use default config with jq < 1.4. This may not work" >&2; cat
              else jq '{
                 pkg: {
                   long_desc: .pkg.short_desc,
                   vendor: .pkg.maintainer
                 },
                 archive: {
                   name: .pkg.name,
                   targz: ("https://github.com/indigo-dc/"+(.archive.name//.pkg.name)+"/archive/"+.pkg.version+".tar.gz")
                 },
                 deps: {
                   arch: [],
                   deb: [],
                   rpm: ["yum"]
                 },
                 architecture: {
                   arch: (.pkg.architecture // "any"),
                   rpm: (.pkg.architecture // "noarch"),
                   deb: (.pkg.architecture // "all")
                 },
                 build: {
                   bash: []
                 }
               } * .'
              fi))

    case $type in
        show-config)
            echo $CONFIG | jq .
            ;;
        arch)
            cd arch
            which makepkg >/dev/null || echo $0: "WARNING: This propably won't work" >&2
            echo $0: "Building '.pkg.tar.xz' (pacman compatible) package"

            makepkg -fd
            ;;
        deb)
            cd deb
            which dpkg-deb >/dev/null || echo $0: "WARNING: This propably won't work" >&2
            echo $0: "Building '.deb' (apt compatible) package"

            ./makepkg.sh
            ;;
        rpm)
            cd rpm
            which rpmbuild >/dev/null || echo $0: "WARNING: This propably won't work" >&2
            echo $0: "Building '.rpm' (yum compatible) package"

            rpmbuild -bb info.spec \
                | tee >(grep -Po '(?<=^Wrote: ).*\.rpm$' \
                            | xargs -I {} ln -sf {} $(echo $CONFIG | jq -j '.pkg.name,"-",.pkg.version')-noarch.rpm)
            ;;
        *)
            echo $0: "ERROR: Don't know how to build $type packages" >&2
            exit 1
            ;;
    esac
fi
