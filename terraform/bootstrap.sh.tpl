#! /bin/bash

node_name="$(curl -s curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/name)"
local_ipv4="$(curl -s curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/ip)"
public_ipv4="$(curl -s curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"

# Vault config
echo ' 
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
seal "gcpckms" {
  project     = "${project_name}"
  region      = "${local_region}"
  key_ring    = "${gcp-keyring}"
  crypto_key  = "${gcp-key}"
}
ui=true' | sudo tee /etc/vault.d/vault.hcl

# Consul config
echo ' datacenter          = "${local_region}"
server = true
node_name = "NODE_NAME"
bootstrap_expect = ${cluster_size}
leave_on_terminate  = true
advertise_addr      = "LOCAL_IPV4"
data_dir            = "/tmp"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
retry_join          = ["provider=gce tag_value=${cluster_tag_name}"]
disable_remote_exec = false' | sudo tee /etc/consul.d/consul.hcl

sudo sed -i -e 's/LOCAL_IPV4/'"$local_ipv4"'/g' -e 's/NODE_NAME/'"$node_name"'/g' /etc/consul.d/consul.hcl

sudo systemctl start consul
sudo systemctl start vault

# consul read/write functions to store Vault values
cget() { curl -sf http://127.0.0.1:8500/v1/kv/service/vault/$1?raw; }
cput() { curl -sfX PUT --output /dev/null http://127.0.0.1:8500/v1/kv/service/vault/$1 -d $2; }

# Delay to allow Vault time to start
# This will run on all instances, but only the first will be Vault active.
sleep 5
echo "Initializing Vault cluster in ${local_region}"
#VAULT_HOST=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault?dc=${local_region} | jq -r '.[0].Address')
curl \
    --silent \
    --request PUT \
    --data '{"recovery_shares": 1, "recovery_threshold": 1}' \
    http://127.0.0.1:8200/v1/sys/init | tee \
    >(jq -r .root_token > /tmp/${local_region}-root-token) \
    >(jq -r .recovery_keys[0] > /tmp/${local_region}-unseal-key)

# Store region specific root tokens in local Consul cluster
if ! grep -q "null" /tmp/${local_region}-root-token; then
  cput ${local_region}-root-token $(cat /tmp/${local_region}-root-token)
  cput ${local_region}-unseal-key $(cat /tmp/${local_region}-unseal-key)
fi

sleep 5

echo "Restarting Vault standby nodes using Consul exec"
consul exec -datacenter=${local_region} -service vault -tag standby sudo systemctl restart vault

# Sets env vars for all users
echo "Setup Hashistack profile"
echo " export CONSUL_ADDR=http://127.0.0.1:8500
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN= " | sudo tee /etc/profile.d/hashistack.sh