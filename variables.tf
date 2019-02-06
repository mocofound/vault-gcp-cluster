variable "gcp_vault_consul_ami" {
  description = "Specify the ID of the Vault AMI. You should build this using the scripts in the install-vault module."
  default = "vaultcluster"
}

variable "gcs_bucket_name" {
  description = "This module uses S3 as a storage backend"
  default = "steniobucketvault"
}