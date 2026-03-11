# Terraform
- open-source Infrastructure as Code (IaC) tool created by HashiCorp
- allows to define i.e. cloud infrastructure using **configuration** files that you can version, reuse, and share, rather than manual console configuration
- it offers a consistent workflow to provision and manage the resources throughout their lifecycle

## Installation on Ubuntu/Debian
``` bash
# Download HashiCorp’s public security key, send it to stdout (-O) not a file
# Converts the ASCII-armored GPG key into a binary keyring format
# Saves it to a trusted system keyring location
# Why: APT uses this key to verify packages are signed by HashiCorp => prevents tampering / MITM attacks (attacker intercepting or altering communication between 2 participants)
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# echo "deb ...": construct a repository entry dynamically
# deb: declare a binary package repository
# ...arch...: insert the system architecture (e.g. amd64)
# signed-by=...: tells APT which key to trust for this repo only, more secure than global trust
# https...: repository base URL
# ...os-release: detects Ubuntu codename (e.g. jammy, focal)
# lsb_release...: fallback if first method fails
echo "deb \
[arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | \
# write the repository entry (the standard input from pipe) to a new file (and to standard output)
sudo tee /etc/apt/sources.list.d/hashicorp.list
# apt update: fetches package lists, now including HashiCorp’s repo
# &&: only runs the next command if the previous one succeeds
# installs Terraform from the newly added repo
sudo apt update && sudo apt install terraform
```

## Initialization
- when you create a new configuration or check out an existing configuration from version control you need to initialize the directory with `terraform init` => 
    - downloads the providers defined in the configuration and installs them in a hidden subdirectory of the current working directory, named `.terraform`
        - put in `.gitignore` because: contains executables, platform-specific, can be large
    - creates a lock file named `.terraform.lock.hcl`, which specifies the exact provider versions used to ensure that every Terraform run is consistent and you can control when you upgrade the providers
        - exclude it form `.gitignore` since it provides dependency reproducibility for the team and stability ()

## terraform configuration
- `required_version = "~> 1.14"`: pin terraform version: either exact version or a pessimistic constraint `~>` that allows only patch updates => prevents unexpected breaking changes
    - Background: update types denoted in version numbers `MAJOR.MINOR.PATCH`
        - Major: Breaking changes; you must update your code to stay compatible.
        - Minor: New, backward-compatible features or enhancements.
        - Patch: Backward-compatible bug fixes and stability improvements.