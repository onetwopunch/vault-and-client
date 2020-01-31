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
sudo yum install -y unzip

# Donwload Vault and Terraform
curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip

pushd /tmp
unzip vault.zip
unzip terraform.zip
mv vault terraform /usr/bin/
popd

# TLS cert
mkdir -p /etc/vault/config
# Allow SCP of terraform code
chmod 777 /etc/vault/config
cat << EOF > /etc/vault/ca.crt
${vault_ca_cert}
EOF

###############
# Vault agent #
###############
# Add a user for the Vault agent process
useradd -s /bin/false vault-agent
# Add a user for the terraform client
useradd -d /opt/vault-admin -s /bin/false -G vault-agent vault-admin

# Then create the home directory for this service where the vault token
# will be stored.
mkdir -p /opt/vault-admin
chmod 0770 /opt/vault-admin
chown -R vault-admin:vault-agent /opt/vault-admin
cat <<'EOF' >> /opt/vault-admin/.bashrc
export VAULT_ADDR=${lb_ip}
export VAULT_CACERT=/etc/vault/ca.crt
EOF

# Store agent config
cat <<"EOF" > /etc/vault/agent.hcl
${agent_config}
EOF
chmod 0600 /etc/vault/agent.hcl
chown -R vault-agent:vault-agent /etc/vault


# Create Vault agent systemd service
cat <<"EOF" > /etc/systemd/system/vault-agent.service
${vault_systemd}
EOF

# Start the vault agent
chmod 0600 /etc/systemd/system/vault-agent.service
systemctl daemon-reload
systemctl enable vault-agent

# Pretty message and helpful environment variables
cat << 'EOF' > /etc/motd
____   ____            .__   __    __________                  __  .__
\   \ /   /____   __ __|  |_/  |_  \______   \_____    _______/  |_|__| ____   ____
 \   Y   /\__  \ |  |  \  |\   __\  |    |  _/\__  \  /  ___/\   __\  |/  _ \ /    \
  \     /  / __ \|  |  /  |_|  |    |    |   \ / __ \_\___ \  |  | |  (  <_> )   |  \
   \___/  (____  /____/|____/__|    |______  /(____  /____  > |__| |__|\____/|___|  /
               \/                          \/      \/     \/                      \/
-------------------------------------------------------------------------------------


sudo -su vault-admin
cd /etc/vault/config
# After running `make sync` locally...
terraform apply
EOF
