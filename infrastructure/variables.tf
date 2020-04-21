# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
variable "org_id" {
  description = "Org ID where Vault will have permissions to create Service Accounts and update project IAM for them."
  type        = string
}

variable "project_id" {
  description = "Project ID where Vault will live"
  type        = string
}

variable "members" {
  description = "List of members able to access the bastion and adminstrate Vault"
  type        = list
}

variable "network_subnet_cidr_range" {
  description = "The CIDR range for the Vault network"
  type        = string
  default     = "10.127.0.0/20"
}

variable "kms_keyring" {
  description = "KMS key ring for Vault auto-unseal"
  type        = string
}

variable "region" {
  description = "Region where Vault and Bastion will live"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "Zone where bastion will live"
  type        = string
  default     = "us-west1-a"
}

variable "vault_version" {
  type        = string
  default     = "1.3.1"
  description = "Version of Vault server and client on the bastion"
}

variable "tf_version" {
  type        = string
  default     = "0.12.20"
  description = "Version of Terraform on the bastion"
}

variable "allowed_external_cidrs" {
  type        = list
  description = "The external CIDR ranges that should be able to access Vault"
  default     = []
}

variable "use_remote_state_vault" {
  type        = bool
  description = "Whether to create a bucket and store a configuration file for Vault remote state"
  default     = true
}
