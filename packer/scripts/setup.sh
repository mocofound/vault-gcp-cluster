#!/usr/bin/env bash
set -x

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

echo "Installing jq"
sudo curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x /bin/jq

echo "Installing unzip"
sudo yum install unzip -y

echo "Configuring system time"
sudo timedatectl set-timezone UTC

echo "Installing Consul, Consul-template, Nomad and Vault"
install_from_zip() {
  cd /tmp && {
    unzip -qq "${1}.zip"
    sudo mv "${1}" "/usr/local/bin/${1}"
    sudo chmod +x "/usr/local/bin/${1}"
    rm -rf "${1}.zip"
  }
}


echo "Add users"
sudo adduser --disabled-password --gecos "User" consul
sudo adduser --disabled-password --gecos "User" vault

echo "Configuring HashiCorp directories"
directory_setup() {
  # create and manage permissions on directories
  sudo mkdir -pm 0755 /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chown -R ${1}:${1} /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chmod -R 0644 /etc/${1}.d/
}

install_from_zip consul
install_from_zip vault
directory_setup consul
directory_setup vault
directory_setup vault-agent


echo "Copy systemd services"
SYSTEMD_DIR="/lib/systemd/system"

systemd_files() {
  sudo cp /tmp/files/$1 $2
  sudo chmod 0664 $2/$1
}
systemd_files consul.service ${SYSTEMD_DIR}
systemd_files consul-online.service ${SYSTEMD_DIR}
systemd_files consul-online.target ${SYSTEMD_DIR}
systemd_files vault.service ${SYSTEMD_DIR}

sudo cp /tmp/files/consul-online.sh /usr/bin/consul-online.sh
sudo chmod +x /usr/bin/consul-online.sh
sudo systemctl enable consul-online

sudo cp /tmp/files/check_mem.sh /usr/bin/check_mem.sh
sudo chmod +x /usr/bin/check_mem.sh

sudo cp /tmp/files/check_cpu.sh /usr/bin/check_cpu.sh
sudo chmod +x /usr/bin/check_cpu.sh

#echo "Setup Hashistack profile"
#cat <<PROFILE | sudo tee /etc/profile.d/hashistack.sh
#export CONSUL_ADDR=http://127.0.0.1:8500
#export VAULT_ADDR="http://active.vault.service.consul:8200"
#export VAULT_TOKEN=root
#PROFILE

echo "Give consul user shell access for remote exec"
sudo /usr/sbin/usermod --shell /bin/bash consul >/dev/null

echo "Allow consul sudo access for echo, tee, cat, sed, and systemctl"
cat <<SUDOERS | sudo tee /etc/sudoers.d/consul
consul ALL=(ALL) NOPASSWD: /usr/bin/echo, /usr/bin/tee, /usr/bin/cat, /usr/bin/sed, /usr/bin/systemctl, /bin/systemctl
SUDOERS

echo "Setup ramdisk for Vault token sink"
sudo install -d /mnt/ramdisk --mode=0770 --owner=root --group=vault-agent
cat <<FSTAB | sudo tee --append /etc/fstab
tmpfs       /mnt/ramdisk tmpfs   nodev,nosuid,noexec,nodiratime,size=20M   0 0
FSTAB

