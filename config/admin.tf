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
resource "vault_auth_backend" "gcp_admin" {
  path = "gcp_admin"
  type = "gcp"
}

resource "vault_policy" "admin" {
  name   = "admin"
  policy = data.vault_policy_document.admin.hcl
}

resource "vault_gcp_auth_backend_role" "gcp" {
  role                   = "admin-role"
  type                   = "gce"
  backend                = vault_auth_backend.gcp_admin.path
  bound_service_accounts = [var.admin_service_account]
  token_policies         = ["admin"]
  token_ttl              = 3600
}

data "vault_policy_document" "admin" {
  rule {
    path         = "*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Manage auth backends broadly across Vault"
  }
}
