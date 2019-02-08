# Vault-GCP-Cluster

This repo provides a reference to installing Vault in GCP, with cloud auto-unseal.

Demo install: Not production ready, but can be used for PoVs and simple tests
Prod install: Follows recommended best practices

## TODO
- Use users "consul" and "vault" instead of "root"
- Fix Load balancer health checks
- Specify a project for consul retry_join, for future when multiple deployments same gcp org
- Split Vault and Consul instances
- Enable Vault TLS
- Deploy to second datacenter
- Join Consul clusters across datacenters
- Enable Vault Performance Replication
- Update documentation with diagram

## Note
### Load Balancer
GCP load balancer works slightly different than other cloud platforms. The external IP is provided by a "forwarding rule", which is associated with a target pool of instances (IPs, scale groups, etc). This target pool is associated with one or more health checks. You can then use firewall rules to allow access to the port/network that the forwarding rule and target pool are deployed. 

## Requirements
In order to use this demo, you will need:
- A GCP account with sufficient permissions to create resources
- Vault and Consul binaries (open source or enterprise)
- [Terraform in your machine](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [Packer in your machine](https://www.packer.io/intro/getting-started/install.html)
- You will need to enable the following APIs: Compute Engine API, Cloud Resource Manager API, Cloud KMS API, IAM Identity Access Management

## Demo Install

(insert diagram)
- Packer image with Vault and Consul in the same VM
- No TLS setup
- Firewall open to the public

## Prod Install

(insert diagram)
- Independent packer images for Vault and for Consul
- TLS between Vault
- Consul ACL
- Private subnet, and outside access through bastion host

## Steps
### Create Packer image
The packer image will just store Vault's and Consul binaries, copy configuration files and install dependencies. It will not install or configure Vault or Consul, this will be done upon Terraform deployment.
- Go to the [\packer](\packer) 
- Make a copy of [\packer\vars.json.example](\packer\vars.json.example)
- Update with adequate values
- Download your [GCP's json auth file](https://cloud.google.com/video-intelligence/docs/common/auth)
- Place it in ~/.gcp, or if you want in another location, update the env var GOOGLE_APPLICATION_CREDENTIALS afterwards
- Run
```
export GOOGLE_APPLICATION_CREDENTIALS=[PATH TO YOUR GCP AUTH FILE]
packer build -var-file=vars.json packer.json
```

### Deploy Terraform
- Open folder matching desired deployment (demo or prod)
- Update variables.tfvars with image ids from Packer output
- Update variables.tfvars with any other customization
- Execute
```
export GOOGLE_CLOUD_KEYFILE_JSON=[PATH TO YOUR GCP AUTH FILE]
terraform init
terraform plan
# If you agree with the plan and are ready to deploy,
terraform apply
```

### Notes
- The Vault token is available in /tmp
- Terraform destroy wont destroy the keyring, if you get an error message you can just change the name
- If you clone this repository and host in your public git account, please make sure you do not save your GCP credentials with this code.
