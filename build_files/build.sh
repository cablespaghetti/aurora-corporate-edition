#!/bin/bash

set -ouex pipefail

# Set up yum repos
curl -L -o /etc/yum.repos.d/microsoft-rhel9.0-prod.repo https://packages.microsoft.com/yumrepos/microsoft-rhel9.0-prod/config.repo
curl -o /etc/yum.repos.d/microsoft-edge.repo https://packages.microsoft.com/yumrepos/edge/config.repo

# Enable GPG verification on yum repos
sed -i 's/gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/microsoft-rhel9.0-prod.repo
sed -i 's/gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/microsoft-edge.repo

# Undo the work of good open source maintainers https://github.com/ublue-os/bluefin-lts/pull/425
# Required because the Microsoft packages are an absolute joke
# Remove opt symlink and replace it with an actual directory for the build as well as creating /var/opt
rm /opt && mkdir /opt && mkdir /var/opt

# Install old Fedora 41 packages for OpenJDK 11 which is presently a dependency for Intune
mkdir -p /var/roothome/.gpg

dnf install -y https://kojipkgs.fedoraproject.org//packages/copy-jdk-configs/4.1/6.fc41/noarch/copy-jdk-configs-4.1-6.fc41.noarch.rpm
dnf install -y https://fedora.mirrorservice.org/fedora/linux/updates/41/Everything/x86_64/Packages/j/$(curl https://fedora.mirrorservice.org/fedora/linux/updates/41/Everything/x86_64/Packages/j/ | grep java-11-openjdk-headless-11 | sed -E 's/.*href=\"(java.*.rpm)\".*/\1/' | sort -r | head -n 1)
dnf install -y https://fedora.mirrorservice.org/fedora/linux/updates/41/Everything/x86_64/Packages/j/$(curl https://fedora.mirrorservice.org/fedora/linux/updates/41/Everything/x86_64/Packages/j/ | grep java-11-openjdk-11 | sed -E 's/.*href=\"(java.*.rpm)\".*/\1/' | sort -r | head -n 1)

# Install Edge and Intune
dnf install -y intune-portal microsoft-edge-stable

# Install AWS VPN Client
dnf copr enable -y vorona/aws-rpm-packages
dnf install -y awsvpnclient
systemctl enable awsvpnclient

# Move installed packages to the proper location
mv /opt/microsoft /usr/lib/opt/microsoft
mv /opt/awsvpnclient /usr/lib/opt/awsvpnclient

# Register path symlink
# Thanks to p5 for the inspiration: https://github.com/rsturla/eternal-images
cat >/usr/lib/tmpfiles.d/microsoft.conf <<EOF
L  /var/opt/microsoft  -  -  -  -  /usr/lib/opt/microsoft
EOF

# Hacks to make AWS VPN Client work
mv /usr/bin/readlink /usr/bin/readlink.orig
cp /ctx/awsvpnclient-readlink /usr/bin/readlink
chmod 755 /usr/bin/readlink
cp /ctx/awsvpnclient-override.conf /etc/systemd/system/awsvpnclient.service.d/override.conf

# Put the opt symlink back like we found it
rm -rf /opt && ln -s /var/opt /opt

# Remove yum repos
rm /etc/yum.repos.d/microsoft*

# Tidy up ephemeral directories
rm -rf /var/lib/dnf /var/lib/rpm-state /var/roothome
rm -rf /tmp/*
