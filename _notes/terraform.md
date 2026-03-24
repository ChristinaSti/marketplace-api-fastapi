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

## bootstrap Terraform
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
    - `terraform apply`, or in the end `terraform apply -var-file=../common.tfvars -var-file=bootstrap.tfvars`
- How does terraform resolve variables using var.<name>?
    - looks for the `variable` blocks across all .tf files in the same directory
        - -> e.g. var.project_id resolves to variable "project_id" block
    - Values are resolved in this priority order:
        - `-var` CLI flag (terraform apply -var="project_id=foo")
        - `-var-file` flag or auto-loaded `*.auto.tfvars` / `terraform.tfvars`
        - Environment variables (`TF_VAR_project_id`)
        - `default` value in the `variable` block
        - If none of the above, Terraform prompts us interactively

#### GCP project
- "this" as a local resource name is a widely-used convention when there's only one instance of that resource type in the module (comes from the self idea in OOP)
- labels can be useful for: cost contribution (e.g. filter billing reports by team, environment, service), automation (scripts/policies that target resources by label, e.g., "delete all environment=dev resources nightly"), organization: quickly identify who owns what in the console
- project_id: should be recognizable for easier debugging, logs and GCP console where it is shown, must be globally unique in GCP
- since the project is created in this config, there is not default project specified in `provider "google" {}`

#### APIs
``` yaml
"cloudresourcemanager.googleapis.com", # project metadata an resources
"iam.googleapis.com",                  # IAM policies and service accounts
"iamcredentials.googleapis.com",       # Workload Identity Federation
"sts.googleapis.com",                  # Security Token Service (WIF)
"storage.googleapis.com",              # GCS (Terraform state bucket)
"artifactregistry.googleapis.com",     # Docker image registry
"run.googleapis.com",                  # Cloud Run
"compute.googleapis.com",              # networking (Cloud Run dependency)
"secretmanager.googleapis.com",        # Secret Manager
"sqladmin.googleapis.com",             # Cloud SQL
"servicenetworking.googleapis.com",    # enables private connections between VPC GCP-services (e.g. Cloud SQL private IP)
"vpcaccess.googleapis.com"             # creates VPC connectors for serverless services Cloud Run can reach private VPC resources
```

#### State
- the bootstrap state is intentionally local to be run ONCE by a human with org-admin permissions, not by CD pipeline should have very limited permissions => no remote storage location => no backend configuration in terraform block
- the bootstrap/state.tf file defines the storage bucket where the the `terraform.tfstate` of the terraform root is saved that the CD pipeline is supposed to run
##### Syntax
- `versioning {enabled = true}`: GCS retains every version of every object rather than overwriting on PUT
    - -> protects from accidental deletion and structural corruption (e.g. `terraform apply` crashes mid-write or `terraform state rm` runs by mistake)
- `lifecycle_rule {}`: avoid unbounded storage costs vor a big number of state versions
- `lifecycle{prevent_destroy = true}`: 
    - is a Terraform meta-argument, not sent to GCP API (despite "lifecycle" naming overlap)
    - any `destroy` of this resource is rejected with an error at plan time, before apply
- `uniform_bucket_level_access = true`
    - GCS has two IAM models:
        - Bucket-level IAM: standard GCP IAM policies on the bucket resource
        - Object-level ACLs: legacy per-object Access Control Lists
    - uniform_bucket_level_access disables object ACLs entirely => a single, auditable, IAM-native access model, no accidental permissive access control on an object
- `public_access_prevention = "enforced"`
    - operates below the IAM layer, is a safety net in case of IAM misconfiguration
    - if someone grants `allUsers` or `allAuthenticatedUsers` read access (anyone with a google account), GCP refuses to serve unauthenticated requests to this bucket
- `autoclass {enabled = true}`: automatically transitions objects between storage classes based on access frequency
    - Standard: frequently accessed, Nearline (~ monthly), Coldline (~ quarterly), Archive (rarely)
        -> cheaper storage cost from left to right but also higher retrieval cost
- `depends_on = [google_project_service.apis]` 
    -  explicit dependency is needed when ordering cannot be inferred from attribute references (here attr. of google_project_service.apis)

#### Outputs
- output exports values/created resources from a module/state so they can be read by `terraform output` command, other terraform modules via `module.<name>.<output>`, CI scripts as deployment metadata
- they are currently not used and therefore not implemented, github variables are used instead to pass resource information to the CD pipeline

#### IAM (Identity and Access management)
- service account:
    -  intended to represent a non-human user, such as an application, virtual machine (VM), or automated workload
    - allows these services to authenticate and securely call Google API methods without requiring human credentials, using IAM roles to define specific permissions for accessing resources
``` yaml
"roles/run.admin",                    # deploy Cloud Run services & jobs
"roles/iam.serviceAccountUser",       # act as the Cloud Run runtime SA
"roles/artifactregistry.writer",      # push Docker images
"roles/secretmanager.secretAccessor", # read database secrets
"roles/cloudsql.client",              # connect to Cloud SQL
"roles/storage.objectAdmin",          # read/write Terraform state
```

#### WIF (workload identity federation)
- `google_iam_workload_identity_pool`: 
    - creates a trust container in GCP, like a namespace that tells GCP what identities to trust from an external system
    only accepts identity tokens from external identity providers that are registered inside this pool
    - it does nothing by itself, it is just the pool that providers and bindings are associated to
- `google_iam_workload_identity_pool_provider`:
    - here is where actual trust relationship is defined: what external identity provider to trust, how to interpret its tokens, conditions under which to accept them => if the JWT token is accepted, it returns a **federated access token** - a short-lived OAuth2 token
    - `issuer_uri = "https://token.actions.githubusercontent.com"`: GitHub's JWKS (JSON Web Key Set) endpoint URL where GCP fetches GitHub's public key from that is used to verify the signature of every JWT that comes in claiming to be from GitHub
    - `attribute_mapping`: 
        - GitHub's signed JWT contains a claims payload with fields like sub, repository, ref
        - attribute_mapping block translates GitHub's JWT claim names into GCP's attribute system
    - `attribute_condition`: 
        - every incoming JWT is evaluated against this condition after signature verification -> if it evaluates to false, GCP's STS returns a 403, no token is issued
            - => only workflows triggered from the main branch of my specific repository in a push event are accepted.
- `google_service_account_iam_member`:
    - the github action then calls iamcredentials.googleapis.com to impersonate the specified service account, exchanging the federated token for a service-account-scoped token which can then be used by the CD pipeline to authenticate for subsequent gcloud/GCP SDK calls
    - `role = "roles/iam.workloadIdentityUser"`: ability to call generateAccessToken on the IAM Credentials API to **impersonate a service account**
    - `member = "principalSet://iam.googleapis.com/${pool.name}/attribute.repository/${var.github_repo}"`: 
        - principalSet: not a single identity but a set of identities defined by an attribute - any external identity that came through this pool AND whose `attribute.repository` matches my-org/my-repo

## Terraform in CD pipeline

### Artifact Registry
- is a fully managed service used to centrally store and manage software build artifacts, such as container images, native language packages (e.g., Maven, npm, and Python)

#### Syntax
- `format = DOCKER"`: registry type, supports the OCI (open docker initiative) Distribution Specification, other possible values: MAVEN, NPM, PYTHON, GO
- `cleanup_policies`: Without cleanup policies, every CI push accumulates images forever.
    - KEEP rules take precedence over DELETE rules
    - rules applied in this project:
        - Keep tagged images (latest, git SHAs) for 90 days
        - Delete untagged images after 7 days (leftover build layers from when a tag is moved, intermediate images from CI builds that failed before pushing a final tagged image)
        - Always keep the 10 most recent tagged images regardless of age
- evtl. TODO: `tag_prefixes = ["sha-"]` in `delete-old-tagged` and `tag_prefixes = ["v"]` in `keep-release-tags`: exclude release tags like v1.0.0 from deletion and to keep them indefinitely

### Cloud Run
- create a runtime service account to follow the principle of least privilege (not using the broad CD service account)
- `"roles/secretmanager.secretAccessor"`: required for --set-secrets to inject database credentials
- `"roles/cloudtrace.agent"`: allows Cloud Run to export traces for latency diagnostics
- `"roles/logging.logWriter"`: allows to write logs automatically

### Network

#### Principles
- using Virtual private Cloud (VPC)
- **VPC**: is a logically isolated section of a cloud provider's network where I can run my own resources in a private, controlled environment, even though the underlying hardware is shared with other customers, while leveraging the **scalability of public cloud services**
- IP address: a numerical label assigned to every device on a network used to identify and locate it
- **Subnet**: inside my VPC, I split my address space into smaller subnets, e.g. one for web servers, one for databases
    - a private subnet has no direct internet access, ab public subnet can communicate with the internet
- **CIDR** (Classless Inter-Domain Routing): a compact way to express a range of IP addresses
    - -> example: 10.0.0.0/16 means all addresses from 10.0.0.0 to 10.0.255.255 (256 x 256 = 65,536 addresses)
        - -> IP-addresses are represented as 32 bits - 8 bits for each of the 4 groups
            - 1111 1111 => 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 255
        - => the /16 in the above CIDR example tells I how many bits are fixed/locked, they define the network
            - => the larger the number after the slash, the smaller the network
- **Internet Gateway**: a component attached to a VPC to allow resources inside it to send and receive traffic to/from the public internet
- **Route Table**: 
    - a set of rules that determine where network traffic is directed 
    - each subnet has a route table
    - example: traffic going to the internet -> use the internet gateway
- **Security Group**: 
    - a virtual **firewall applied to individual resources**
    - it controls which inbound and outbound traffic is allowed based on rules I define
    - e.g. allow HTTPS traffic on port 443 from anywhere
- **Network ACL** (Access control List): 
    - a **firewall applied at subnet level** (broader than security group)

- **Why use VPC?**
    - **Isolation**: resources are invisible to other cloud customers
    - **Security**: control exactly what traffic can flow in and out
    - **Custom Networking**: define own IP ranges, subnets, and routes
    - **Hybrid connectivity**: connect the VPC to on-premises office network via VPN or a dedicated link

- **VPC Peering**: a connection between two separate VPCs that allows the to traffic to each other privately without ever touching the public internet
    - => the 2 VPCs act as one network from a routing perspective

- **Private Services Access (PSA)**: 
    - is a Google Cloud-specific feature
    - solves the following problem:
        - Google's manages services (e.g. Cloud SQL, Cloud Filestore, Memorystore) run inside Google's own VPC
        - => the customer's VPCs are separate from Google's VPC => customer resources would have to reach Google's managed services over the public internet which is slower and less secure
    - solution:
        - PSA sets up a private VPC Peering connection between the customer's VPC and Google's internal service VPC
        - => Google's managed service instance (e.g. Cloud SQL instance) gets an IP from the reserved range (dedicated exclusively for Google to use) of the customer VPC => communication works as if they were in the same VPC

- **Serverless Compute**: services like Cloud Run, Cloud Functions, or App Engine where I deploy code without managing any servers yourself
    - => Google runs them in its own infrastructure outside my VPC
    - => Problems:
        - it can reach neither the private subnets in my VPC nor the PSA-connected services => would have to go over the public internet

- **Serverless VPC Access Connector**: 
    - is a small, Google-managed bridge component that I deploy inside my VPC
    - it gets IP addresses from the CIDR range I specify
    - **Serverless services** are then configured to route their outbound traffic through that VPC Access Connector bridge => that traffic enters my VPC privately

#### Traffic flow overview of this project
Internet
    |
Cloud Run (public endpoint, serverless service managed by GCP) 
    |
---(via VPC Access Connector)---
    |
   VPC 
    |
--(via PSA)--
    |
Cloud SQL (Google's manged service)

#### Concrete Resources created via TF
1. **The VPC Network**: `"google_compute_network" "main"`
    - `auto_create_subnetworks`: if True, Google automatically creates one subnet per Google Cloud region, using predefined CIDR blocks from the 10.128.0.0/9 range
        - almost always want `auto_create_subnetworks = False` especially to make sure there remains enough free range for custom defined components like  PSA, a Serverless VPC Access Connector, VPN connections to on-prem
2. **Subnet for serverless VPC Access connector**: `"google_compute_subnetwork" "connector"`
    - `ip_cidr_range = "10.8.0.0/24"`:
        - available private IP ranges:
            - The internet has reserved three ranges that are guaranteed never to be used on the public internet => can be freely used in private networks:
                - 10.0.0.0/8        — ~16 million addresses
                - 172.16.0.0/12     — ~1 million addresses
                - 192.168.0.0/16    — ~65,000 addresses
        - Cloud Run's VPC connector needs a /28 subnet (16 IPs) at minimum
        - I allocate /24 (6 flexible bits = 256 IPs) to leave room for future services
    - `private_ip_google_access = true`: leaving it false there would mean my private resources silently lose access to Google APIs
3. **Serverless VPC Access Connector** `"google_vpc_access_connector" "main"`: 
    - bridges serverless Cloud Run service into the VPC so it can reach Cloud SQL via private IP
    - **Scaling** type:
        1. instance scaling:
            - example definition:
                ```
                min_instances = 2 # minimum required by GCP
                max_instances = 3
                ```
            - indirect scaling, Google infers how much capacity/throughput I need within the range that the defined numbers of instances offer
        2. Throughput scaling:
            - example definition:
                ```
                min_throughput = 200   # Mbps — baseline, keeps at least this capacity ready
                max_throughput = 1000  # Mbps — ceiling, Google won't exceed this
                ```
            - values must be multiples of 200 Mbps
            - direct scaling, tell Google how many Mbps I need => Google decides internally how many instances of what size to provision to meet that target => tends to react more smoothly to traffic spikes because Google can make finer-grained decisions than I can by manually tuning instance counts => USUALLY PREFERRED
            - make sure the limits are close to  multiple of the throughput of the machine_type, otherwise there will be idle capacity I need to pay for

    - **`machine_type`** choices:
        -  **`e2-micro`**
            - throughput per instance: 100 Mbps
            - are cheapest, suitable for low traffic
            - shared core: get a fraction of a vCPU (e.g. 1 unit of time out of 4 units of time)
            - => a process might be mid-task when the CPU is taken away, has to wait, then resumes => creates irregular, bursty pauses/latency spikes rather than a smoothly slower execution
        - **`e2-standard-4`**: 
            - throughput per instance: 500 Mbps
            - get full 4 vCPUs
            - Recommended for high throughput (~3200-16000 Mbps), production environments, or high concurrency. 
4. **Private Services Access (PSA)** for Cloud SQL:
    - `"google_compute_global_address" "private_services"`: 
        - reserves an IP range in my VPC
        - `prefix_length = 20`: /20 => 12 flexible bits = 4096 IPs for Cloud SQL + future services
    - `"google_service_networking_connection" "private_services"`: 
        - creates a VPC peering connection between my VPC and Google's service producer network (where Cloud SQL is)
    - => Cloud SQL is only reachable from within the VPC, has no public IP, eliminates public attack surface
5. **Firewall rules**
    - Firewall rules in GCP are VPC-level resources (there are no Security Groups or Network ACLs)
    - Cloud Run is a serverless, Google-managed service that sits outside my VPC (unlike Compute Engine VM instances and GKE nodes) => VPC firewall rules do not apply
        - Access is controlled by two different mechanisms instead:
            - IAM: roles/run.invoker on the service (allows/denies who can call it)
            - Cloud Run ingress settings: set to all, internal, or internal-and-cloud-load-balancing
    - `"google_compute_firewall" "deny_all_ingress"`
        - `priority = 65534`
            - not (possible to) use 65535, it is reserved by GCP for its own implicit deny-all ingress (but allow all egress)
                - -> this rule is completely silent, it drops traffic with no logging
                - => better use my own explicit deny rules to have audit trail
            - any allow rule I add at a lower number will take precedence automatically
        - `deny { protocol = "all" }`: blocks every protocol. This is a safer default: I must explicitly allow what I need rather than accidentally leaving a protocol open 
        - `source_ranges = ["0.0.0.0/0"]`: matches all possible source IPs
        - `log_config { metadata = "INCLUDE_ALL_METADATA" }`:
            - all metadata: source/destination IP, port, instance details
            - this matters for: security auditing (see what was blocked from where), debugging (check if a firewall rule is the cause if something does not work), compliance (some standards require evidence of network lever logging)
            - trade-off: Cloud logging volume associated cost => evtl. only enable it on deny rules, not on every rule
        - `google_compute_firewall` vs. `google_compute_network_firewall_policy`:
            a) `google_compute_firewall`:
                - Scope: Single VPC network
                - Evaluation: Flat rule list with priority
                - Use cases: single project or simple setup, teams manage their own VPC rules independently, no need for hierarchy or inheritance
            b) `google_compute_network_firewall_policy`:
                - Scope: Can be attached at Organization, Folder, VPC network
                - Evaluation: Hierarchical (org -> folder -> network)
                - Use cases: multiple projects / shared VPCs, need organization-wide enforcement, central security team managing rules, need for deny-by-default guardrails, compliance requirements (e.g., enforce no public SSH globally)
