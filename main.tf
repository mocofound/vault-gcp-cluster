module "vault_cluster" {
  # Use version v0.0.1 of the vault-cluster module
  source = "github.com/hashicorp/terraform-google-vault//modules/vault-cluster?ref=v0.0.1"

  # Specify the ID of the Vault AMI. You should build this using the scripts in the install-vault module.
  source_image = "${var.gcp_vault_consul_ami}"
  
  # This module uses S3 as a storage backend
  gcs_bucket_name   = "${var.gcs_bucket_name}"
  
  # Configure and start Vault during boot. 
  startup_script = <<-EOF
                   #!/bin/bash
                   /opt/vault/bin/run-vault --gcs-bucket ${var.gcs_bucket_name} --tls-cert-file /opt/vault/tls/vault.crt.pem --tls-key-file /opt/vault/tls/vault.key.pem
                   EOF
  
  # ... See variables.tf for the other parameters you must define for the vault-cluster module
}