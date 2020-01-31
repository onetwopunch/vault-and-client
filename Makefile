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
SHELL := /usr/bin/env bash
BASTION_NAME := vault-bastion

.PHONY: sync
sync:
	gcloud compute scp --tunnel-through-iap --recurse config/*.tf* $(BASTION_NAME):/etc/vault/config

.PHONY: ssh
ssh:
	gcloud compute ssh --tunnel-through-iap $(BASTION_NAME)
