#!/bin/bash
#
# Debian Build script for the WaTTS info plugin
#
# Under any dpkg based distro (e.g. Ubuntu) run:
#  $ ./makepkg.sh
#
# Maintainer: Joshua Bachmeier <uwdkl@student.kit.edu>
#

pkgname=$(echo $CONFIG | jq -r .pkg.name)
_pkgname=$(echo $CONFIG | jq -r .archive.name)
pkgver=$(echo $CONFIG | jq -r .pkg.version)
pkgrel=1

srcdir=$(readlink -f ${_pkgname}-${pkgver})
pkgdir=$(readlink -f ${pkgname}_${pkgver}-${pkgrel})


curl -L $(echo $CONFIG | jq -r .archive.targz) -o ${pkgname}-${pkgver}.tar.gz || exit
tar xf "${pkgname}-${pkgver}.tar.gz" || exit
mkdir -p "${pkgdir}" || exit

# Dependencies
depends=(tts)
for dep in $(echo $CONFIG | jq -r '.deps.deb[]')
do
    depends+=($dep)
done

# Debian stuff
mkdir -p "${pkgdir}/DEBIAN" || exit
cat << EOF > ${pkgdir}/DEBIAN/control
Package: ${pkgname}
Version: ${pkgver}-${pkgrel}
Architecture: all
Depends: $(echo ${depends[@]} | tr ' ' ',')
Maintainer: $(echo $CONFIG | jq -r .pkg.maintainer)
Description: $(echo $CONFIG | jq -r .pkg.short_desc)
 $(echo $CONFIG | jq -r .pkg.long_desc)
EOF

# Package
pushd "${srcdir}"
echo $CONFIG | jq -r .build.bash[] | while read cmd
do
    eval "$cmd"
done
mkdir -p "${pkgdir}/var/lib/watts/plugins" || exit
cp plugin/* "${pkgdir}/var/lib/watts/plugins" || exit
popd

# Finale
dpkg-deb --build ${pkgname}_${pkgver}-${pkgrel}
