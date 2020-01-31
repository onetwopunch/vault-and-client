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
resource "vault_gcp_secret_backend" "gcp_cicd" {
  path = "gcp_cicd_sa"
}

# NOTE: For the CICD app to push artifacts to GCR, it must have the ability to write
# to GCS at a project level.
resource "vault_gcp_secret_roleset" "cicd" {
  backend      = vault_gcp_secret_backend.gcp_cicd.path
  roleset      = "storage_admin"
  secret_type  = "service_account_key"
  project      = var.cicd_project_id
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  binding {
    resource = "//cloudresourcemanager.googleapis.com/projects/${var.cicd_project_id}"

    roles = [
      "roles/storage.admin",
    ]
  }
}

resource "vault_policy" "cicd" {
  name = "cicd"

  policy = <<EOT
path "gcp_cicd_sa/key/${vault_gcp_secret_roleset.cicd.roleset}" {
  policy = "read"
}
EOT
}

resource "vault_mount" "generic" {
  path        = "secret"
  type        = "kv-v2"
  description = "Secret mount"
}
