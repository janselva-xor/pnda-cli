#!/bin/bash -v

# This script runs on all instances
# It installs a salt minion and mounts the disks

# The pnda_env-<cluster_name>.sh script generated by the CLI should
# be run prior to running this script to define various environment
# variables

set -e

/tmp/package-install.sh
DISTRO=$(cat /etc/*-release|grep ^ID\=|awk -F\= {'print $2'}|sed s/\"//g)

if [ "x$DISTRO" == "xubuntu" ]; then
export DEBIAN_FRONTEND=noninteractive
apt-get -y install xfsprogs salt-minion=2015.8.11+ds-1
elif [ "x$DISTRO" == "xrhel" ]; then
yum -y install xfsprogs wget salt-minion-2015.8.11-1.el7
#enable boot time startup
systemctl enable salt-minion.service
fi

# Set the master address the minion will register itself with
cat > /etc/salt/minion <<EOF
master: $PNDA_SALTMASTER_IP
EOF

cat >> /etc/salt/minion.d/beacons.conf <<EOF
beacons:
  kernel_reboot_required:
    interval: $PLATFORM_SALT_BEACON_TIMEOUT
    disable_during_state_run: True
EOF

# Set the grains common to all minions
cat >> /etc/salt/grains <<EOF
pnda:
  flavor: $PNDA_FLAVOR
  is_new_node: True

pnda_cluster: $PNDA_CLUSTER
EOF

if [ "x$DISTRO" == "xrhel" ]; then
cat >> /etc/cloud/cloud.cfg <<EOF
preserve_hostname: true
EOF
fi

/tmp/volume-mappings.sh /etc/pnda/disk-config/requested-volumes /etc/pnda/disk-config/volume-mappings