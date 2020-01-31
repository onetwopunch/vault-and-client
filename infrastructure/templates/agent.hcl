vault {
  address = "${vault_address}"
  ca_cert = "/etc/vault/ca.crt"
}

auto_auth {
  method "gcp" {
    mount_path = "auth/gcp_admin"
    config {
      type = "gce"
      role = "admin-role"
    }
  }

  sink "file" {
    config {
      path = "/opt/vault-admin/.vault-token"
    }
  }
}
