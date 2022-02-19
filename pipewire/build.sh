#!/bin/bash

# sudo apt-get install debhelper build-essentials dh-make

if [ ! -d pipewire ]; then
	git clone https://gitlab.freedesktop.org/pipewire/pipewire.git
fi

pushd pipewire
git clean -xdf
git pull --recurse-submodules
meson setup builddir -Dprefix=/usr -Dsession-managers=wireplumber
dh_make --single --yes --createorig --packagename pipewire_$(awk -F "'" '/  version :/ {print $2}' meson.build | head -n1)
dh_auto_configure --buildsystem=meson
dh_make
echo \
"override_dh_shlibdeps:
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info
" >> debian/rules
dpkg-buildpackage -rfakeroot -us -uc -b
popd
