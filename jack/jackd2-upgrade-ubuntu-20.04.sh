#!/bin/bash

OLD_PACKAGES=$(dpkg -l | awk '/jackd2.*1\.9\.12/ {print $2}')
NEW_PACKAGES=$(ls jammy_to_focal_backport/*jackd2*.deb)

if [ -n "${OLD_PACKAGES}" ]; then
	sudo dpkg --purge --force-depends ${OLD_PACKAGES} || exit -1
fi
sudo dpkg -i ${NEW_PACKAGES}
