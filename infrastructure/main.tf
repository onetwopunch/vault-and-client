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
locals {
  # NOTE: See: https://www.vaultproject.io/docs/secrets/gcp/index.html
  # These are only necessary when using the GCP secrets backend
  vault_organization_roles = toset([
    "roles/iam.serviceAccountAdmin",
    "roles/compute.viewer",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ])
}

module "vault" {
  source  = "terraform-google-modules/vault/google"
  version = "~>4.0"

  project_id                   = var.project_id
  region                       = var.region
  kms_keyring                  = var.kms_keyring
  network_subnet_cidr_range    = var.network_subnet_cidr_range
  ssh_allowed_cidrs            = [var.network_subnet_cidr_range]
  storage_bucket_force_destroy = true
  vault_version                = var.vault_version
  load_balancing_scheme        = "INTERNAL"
}

module "iap_bastion" {
  source  = "terraform-google-modules/bastion-host/google"
  name    = "vault-bastion"
  tags    = ["allow-vault"]
  project = var.project_id
  region  = var.region
  zone    = var.zone
  network = module.vault.vault_network
  subnet  = module.vault.vault_subnet
  members = var.members

  # Allows bastion to sign a JWT and verify it's identity.
  service_account_roles_supplemental = ["roles/iam.serviceAccountTokenCreator"]


  startup_script = templatefile("${path.module}/templates/bastion-startup.sh", {
    vault_version = var.vault_version
    tf_version    = var.tf_version
    lb_ip         = module.vault.vault_addr
    vault_ca_cert = module.vault.ca_cert_pem[0]

    agent_config = templatefile("${path.module}/templates/agent.hcl", {
      vault_address = module.vault.vault_addr
    })

    vault_systemd = templatefile("${path.module}/templates/vault-agent.service", {})
  })
}

resource "google_organization_iam_member" "project-iam" {
  for_each = local.vault_organization_roles
  org_id   = var.org_id
  role     = each.key
  member   = "serviceAccount:${module.vault.service_account_email}"
}

resource "google_storage_bucket" "vault_tf_state" {
  count    = var.use_remote_state_vault ? 1 : 0
  project  = var.project_id
  name     = "${var.project_id}-vault-tf-state"
  location = "US"
}

resource "google_storage_bucket_iam_member" "vault_tf_state" {
  count  = var.use_remote_state_vault ? 1 : 0
  bucket = google_storage_bucket.vault_tf_state[0].name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.iap_bastion.service_account}"
}

# Autogenerate the backend.tf file for the Vault config since we
# cannot pass in buckets to backends in terraform
resource "local_file" "provider" {
  count           = var.use_remote_state_vault ? 1 : 0
  filename        = "${path.module}/../config/backend.tf"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/vault-backend.tf", {
    vault_addr = module.vault.vault_addr
    bucket     = google_storage_bucket.vault_tf_state[0].name
  })
}


