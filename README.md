# Vault POC

This POC of Vault includes the following features and capabilities:

#### 1. Vault cluster deployed with [terraform-google-vault](https://github.com/terraform-google-modules/terraform-google-vault)

* Isolated Network and Subnet for Vault and Bastion
* GCS Backend
* Default Vault server configuration
* Self-signed TLS certificates stored encrypted in a GCS bucket

#### 2. Bastion host to access Vault deployed with [terraform-google-bastion-host](https://github.com/terraform-google-modules/terraform-google-bastion-host)

* Hardened VM accessible via IAP and OS Login
* Vault agent configuration in startup script

#### 3. Vault configuration using the [Terraform Vault Provider](https://www.terraform.io/docs/providers/vault/index.html)

* Audit backend to push logs to Stackdriver
* Configured GCE auth backend with Admin role associated with Bastion service account
* GCP Secret backend for a CICD app such as Jenkins on prem to read a service account key with the ability to push artifacts to GCS (and GCR)


This code is designed as a starting point or platform for Vault implementation. Additional work looking into Vault configuration
should be completed for specific requirements.

## Infrastructure Deploy

```
cd infrastructure
# Add variables to terraform.tfvars
terraform apply
```

## Vault Configuration Deploy

I've added some helper scripts in the Makefile to make development of Vault config easier.

To scp the terraform files in `config/` to the bastion for apply:

```
make sync
```

Then to ssh onto the host for development:

```
make ssh
```

You'll then need to switch user to the `vault-admin` account and navigate to the config directory to apply from the bastion.
The reason for this is we are using the vault agent as a systemd service, which stores the admin vault token at the home directory
of this user so it's always logged in as the admin. There are obviously other ways of doing this that are more secure, but this
method illustrates well how the vault agent can and should be configured.

To run the initial terraform apply, you'll need to initialize vault and set the root token. You won't have to go through this every time you make a change to terraform.

```
sudo -su vault-admin
cd /etc/vault/config

vault operator init

# This will output the root token
vault login ROOT_TOKEN
terraform apply

# Remove the root token, which is currently logged in
vault token revoke -self

# Log out of vault-admin so you can use sudo
exit

# Restart the agent to pull a new token from GCE auth quicker
sudo systemctl restart vault-agent

# Log back in as vault-admin
sudo -su vault-admin

# You should now be logged in as the vault admin
vault token lookup
Key                 Value
---                 -----
...
creation_ttl        1h
display_name        gcp_admin-vault-bastion
...
```

Some things to notice:

1. Assuming the systemd service (`systemctl status vault-agent`) is running, the vault agent should auto-authenticate as the admin and store the auth token `.vault-token` in the `vault-admin`'s home directory. i.e. `/opt/vault-admin/.vault-token` should exist
2. If the systemd service isn't running, you can restart it with `sudo systemctl start vault-agent`


Now as the vault admin you can run `make sync` from your local development environment as you make changes to the
terraform config, then on the bastion, run:

```
terraform apply
```

## Demo

### SSH and Admin Usage

```
make ssh
sudo systemctl status vault-agent

sudo -su vault-admin
vault status
vault token lookup

vault kv put secret/test value='My API Token'
vault kv get secret/test
```

### Create single use token for GCP SA


Wrap a token as an operator to distribute. The output could be added to terraform or even in instance metadata to be unwrapped by the application

```
export WRAPPED_TOKEN=$(vault token create -field=wrapping_token -policy=cicd -wrap-ttl=3600)
```

Act as the wrapped token and unwrap the actual token

```
VAULT_TOKEN=$WRAPPED_TOKEN vault unwrap
```

Fetch the short-lived service account and store in a file

```
export VAULT_TOKEN=[Actual token from the previous step]
vault read -field=private_key_data gcp_cicd_sa/key/storage_admin | base64 --decode > ~/storage_admin.json
```

Authenticate as that service account and validate that it works

```
gcloud auth activate-service-account --key-file ~/storage_admin.json
gsutil ls
```

From a separate tab, we can list the service account keys created (Including system key for binding)

```
gcloud iam service-accounts list
# Set EMAIL as the vault SA
gcloud iam service-accounts keys list --iam-account $EMAIL
```

Back to the other tab we can revoke the token at that path, which will also delete the service account key.
This would happen at the TTL set when configuring the secret backend:


```
vault token revoke -mode=path gcp_app_sa
```

# Continuing Resources:

* [Vault Provider](https://www.terraform.io/docs/providers/vault/index.html)
* [Vault Secrets Engine](https://www.vaultproject.io/docs/secrets/)
* [Vault Auth Methods](https://www.vaultproject.io/docs/auth/)
* [Vault Reference Architecture](https://medium.com/@jryancanty/hashicorp-vault-and-terraform-on-google-cloud-security-best-practices-3d94de86a3e9)
