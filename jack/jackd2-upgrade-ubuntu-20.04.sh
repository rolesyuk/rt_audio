#!/bin/bash

OLD_PACKAGES=$(dpkg -l | awk '/jackd2.*1\.9\.12/ {print $2}')
NEW_PACKAGES="https://mirrors.kernel.org/ubuntu/pool/universe/j/jackd2/jackd2_1.9.14-0ubuntu2_amd64.deb
              https://mirrors.kernel.org/ubuntu/pool/universe/j/jackd2/jackd2-firewire_1.9.14-0ubuntu2_amd64.deb
              https://mirrors.kernel.org/ubuntu/pool/main/j/jackd2/libjack-jackd2-0_1.9.14-0ubuntu2_amd64.deb
              https://mirrors.kernel.org/ubuntu/pool/main/j/jackd2/libjack-jackd2-0_1.9.14-0ubuntu2_i386.deb
              https://mirrors.kernel.org/ubuntu/pool/main/j/jackd2/libjack-jackd2-dev_1.9.14-0ubuntu2_amd64.deb
              https://mirrors.kernel.org/ubuntu/pool/main/j/jackd2/libjack-jackd2-dev_1.9.14-0ubuntu2_i386.deb"

wget -c ${NEW_PACKAGES} || exit -1
sha256sum -c checksums.sha256 || exit -1
if [ -n "${OLD_PACKAGES}" ]; then
	sudo dpkg -P --force-depends ${OLD_PACKAGES} || exit -1
fi
sudo dpkg -i $(for PACKAGE in ${NEW_PACKAGES}; do basename ${PACKAGE}; done | xargs)
