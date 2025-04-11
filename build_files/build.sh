#!/bin/bash

set -ouex pipefail

### Install packagesq
curl -L -o /etc/yum.repos.d/microsoft-rhel9.0-prod.repo https://packages.microsoft.com/yumrepos/microsoft-rhel9.0-prod/config.repo
curl -o /etc/yum.repos.d/microsoft-edge.repo https://packages.microsoft.com/yumrepos/edge/config.repo

# Undo the work of good open source maintainers https://github.com/ublue-os/bluefin-lts/pull/425
# Required because the Microsoft packages are an absolute joke
rm -rf /opt && mkdir /opt
dnf install -y intune-portal microsoft-edge-stable
mv /opt/* /var/opt/
rm -rf /opt && ln -s /var/opt /opt
