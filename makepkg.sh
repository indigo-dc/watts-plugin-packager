#!/bin/bash

type=$1
export CONFIG=$(
    if   [[ -f $2 ]];       then jq -c . "$2"
    elif [[ $2 =~ ^http ]]; then curl -L "$2" | jq -c .
    fi | (if [[ $(jq -V 2>&1 | cut -d' ' -f3) < "1.4" ]]
          then echo $0: WARNING: "Can't use default config with jq < 1.4" >&2; cat
          else jq '{
                 pkg: {
                   long_desc: .pkg.short_desc,
                   vendor: .pkg.maintainer
                 },
                 archive: {
                   name: .pkg.name,
                   targz: ("https://github.com/indigo-dc/"+.pkg.name+"/archive/v"+.pkg.version+".tar.gz")
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

        makepkg -fd
        ;;
    deb)
        cd deb
        which dpkg-deb >/dev/null || echo $0: "WARNING: This propably won't work" >&2

        ./makepkg.sh
        ;;
    rpm)
        cd rpm
        which rpmbuild >/dev/null || echo $0: "WARNING: This propably won't work" >&2

        rpmbuild -bb info.spec \
            | tee >(grep -Po '(?<=^Wrote: ).*\.rpm$' \
                        | xargs -I {} ln -sf {} $(echo $CONFIG | jq -j '.pkg.name,"-",.pkg.version',"-noarch.rpm"))
        ;;
    *)
        echo $0: "ERROR: Don't know how to build $type packages" >&2
        exit 1
        ;;
esac
