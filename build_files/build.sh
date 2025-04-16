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

# Install Edge and Intune
dnf install -y intune-portal microsoft-edge-stable

# Move installed MS packages to the proper location
mv /opt/microsoft /usr/lib/opt/microsoft

# Register path symlink
# Thanks to p5 for the inspiration: https://github.com/rsturla/eternal-images
cat >/usr/lib/tmpfiles.d/microsoft.conf <<EOF
L  /var/opt/microsoft  -  -  -  -  /usr/lib/opt/microsoft
EOF

# Put the opt symlink back like we found it
rm -rf /opt && ln -s /var/opt /opt

# Remove yum repos
rm /etc/yum.repos.d/microsoft*

# Tidy up ephemeral directories
rm -rf /var/lib/dnf
rm -rf /tmp/*
