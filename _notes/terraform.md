# Terraform
- open-source Infrastructure as Code (IaC) tool created by HashiCorp
- allows to define i.e. cloud infrastructure using **configuration** files that we can version, reuse, and share, rather than manual console configuration
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
- when we create a new configuration or check out an existing configuration from version control we need to initialize the directory with `terraform init` => 
    - downloads the providers defined in the configuration and installs them in a hidden subdirectory of the current working directory, named `.terraform`
        - put in `.gitignore` because: contains executables, platform-specific, can be large
    - creates a lock file named `.terraform.lock.hcl`, which specifies the exact provider versions used to ensure that every Terraform run is consistent and we can control when we upgrade the providers
        - exclude it form `.gitignore` since it provides dependency reproducibility for the team and stability

## terraform configuration
- `required_version = "~> 1.14.0"`: pin terraform version: either exact version or a pessimistic constraint `~>` that allows only patch updates => prevents unexpected breaking changes
    - Background: update types denoted in version numbers `MAJOR.MINOR.PATCH`
        - Major: Breaking changes; we must update our code to stay compatible.
        - Minor: New, backward-compatible features or enhancements.
        - Patch: Backward-compatible bug fixes and stability improvements.
    - Note: the pessimistic operator allows only the rightmost digit of our version string to increment => if we omit the patch number completely like `"~> 1.14"` nay minor version equal or greater that will be allowed, not patch

## bootstrap
- in the end, github actions in CD pipeline are supposed to automatically run terraform
    - -> some reasons why this is a good practice even if the infrastructure changes rarely: 
        - preventing configurational drift: e.g. if someone tweaks a setting via cloud console, `terraform plan` can alert or `terraform apply` can revert it => keeping a clear version-controlled history of infra changes
        - remain compatibility with provider updates
- BUT the CD pipeline needs some prerequisites to be given in the cloud before it can run (chicken-egg-problem)
    - => for that, we create a second separate terraform root `terraform/bootstrap` that is run only once (or very rarely e.g. to add an API) at project start by a human (instead of by CD on every push to main) with Org-level permission (instead of project-level permissions) using a local state (instead of a remote state in GCS bucket)
    - the following infrastructure resources must be created in the bootstrap:
        1. a CD service account that gives the CD pipeline only the needed permissions (following the principle of least privilege)
        2. a GCP project with billing. It must be bootstrap because a) we cannot create a CD service account in a non-existent project b) it requires org-level `resourcemanager.projectCreator` and `billing.user` role and CD should never have org-level permissions
        3. GCS state bucket for the CD Terraform root.
            - the state file `terraform.tfstate` is the single source of truth for our infrastructure. It maps existing cloud resources to the configuration and tracks resource metadata. Terraform detects changes by comparing the current configuration code to the state file. This cached state avoids costly API call to the cloud provider. For teams, the state file should be stored in a remote backend to be able to work on the same infrastructure simultaneously and safely (with state locking and encryption for sensitive data)
        4. Workload Identity Federation (WIF)
            - is a modern authentication method that allows GitHub Actions to securely access cloud resources without saving long-lived secrets or passwords like a Service Account JSON key as GitHub Secrets 
                - => must be bootstrap because pipeline cannot run without authentication to GCP
            - instead, the workflow requests a temporary identity token from GitHub at runtime. The cloud provider "trusts" GitHub as an identity issuer, verifies GitHub's token and exchanges it for a short-lived access token valid only for that specific job => enhanced security: no long-lived key to leak, exchanged tokens typically expire within an hour
            - Granular Control: set "Attribute Conditions" so the cloud provider only accepts tokens from a specific organization and repository or even specific branches, environments, or actors
        5. Essential APIs. Must be in bootstrap, because:
            - Some APIs, like iam.googleapis.com, sts.googleapis.com are needed in bootstrap to create the WIF pool and service account (but not all) => keeping all APIs in one list is simpler to manage than splitting them across two roots
            - Enabling APIs requires roles/serviceusage.serviceUsageAdmin, which is a powerful permission to better not give the CD service account
- it is possible to share provider binaries across all terraform roots to save disk space by enabling a global plugin cache
    1. Create a central directory for our cache: `mkdir -p ~/.terraform.d/plugin-cache`
    2. Export the environment variable to a central directory in our shell profile
        - `vim ~/.bashrc`
        - paste `export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"`
            - -> `~` cannot be used here because it is not recognized by all programs as a shell expansion shortcut when in double quotes (there is no literal folder named "~") whereas most applications can handle env variables
        - `source ~/.bashrc` to read and execute the contents of .bashrc file in the current terminal (not necessary of the terminal was opened after changing the file)
        - run `terraform init` => providers are downloaded into the central folder and a symbolic link to it is created in the projects (`linux_amd64 -> /home/.../.terraform.d/plugin-cache/registry.terraform.io/hashicorp/google/7.25.0/linux_amd64`)
- Steps:
    - `cd terraform/bootstrap`
    - `terraform init`
    - `terraform apply`
- How does terraform resolve variables using var.<name>?
    - looks for the `variable` blocks across all .tf files in the same directory
        - -> e.g. var.project_id resolves to variable "project_id" block
    - Values are resolved in this priority order:
        - `-var` CLI flag (terraform apply -var="project_id=foo")
        - `-var-file` flag or auto-loaded `*.auto.tfvars` / `terraform.tfvars`
        - Environment variables (`TF_VAR_project_id`)
        - `default` value in the `variable` block
        - If none of the above, Terraform prompts us interactively

### GCP project
- "this" as a local resource name is a widely-used convention when there's only one instance of that resource type in the module (comes from the self idea in OOP)
- labels can be useful for: cost contribution (e.g. filter billing reports by team, environment, service), automation (scripts/policies that target resources by label, e.g., "delete all environment=dev resources nightly"), organization: quickly identify who owns what in the console
- project_id: should be recognizable for easier debugging, logs and GCP console where it is shown, must be globally unique in GCP
