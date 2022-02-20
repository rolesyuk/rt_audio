#!/bin/bash

# HOWTO from https://blog.devgenius.io/how-to-build-debian-packages-from-meson-ninja-d1c28b60e709
# sudo apt-get install debhelper build-essentials dh-make

if [ ! -d pipewire ]; then
	git clone https://gitlab.freedesktop.org/pipewire/pipewire.git
fi

rm -f pipewire*.{changes,buildinfo,ddeb,deb,tar.xz}
pushd pipewire
git clean -xdf
git pull --recurse-submodules
dh_make --single --yes --createorig --packagename pipewire_$(awk -F "'" '/  version :/ {print $2}' meson.build | head -n1)
echo \
"override_dh_shlibdeps:
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info

override_dh_auto_configure:
	dh_auto_configure --buildsystem=meson -- --wrap-mode=nofallback -Dsession-managers=wireplumber
" >> debian/rules
dpkg-buildpackage -rfakeroot -us -uc -b
popd
