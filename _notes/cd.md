
``` yaml
name: CD # displayed in Actions UI
# trigger block
on: # event binding key
  push: # push event on main is fired regardless if changes are pushed directly to main or when a PR is merged
    branches: [main]

jobs: # contains one or more job definitions, each job is an isolated execution environment, jbs run in parallel by default unless you declare needs: dependencies between them
  deploy: #  job ID — an arbitrary string key used as an identifier within the workflow graph 
    runs-on: ubuntu-22.04 # allocates a fresh VM from that image pool

    # GITHUB_TOKEN permission scope block
    # By default, GitHub injects a short-lived GITHUB_TOKEN into every job
    # below, it is defined what a token can to
    permissions:
      contents: read # allows the token to read the repository's contents (needed for actions/checkout)
      id-token: write #  grants the job permission to request an OIDC (OpenID Connect) token from GitHub's OIDC provider => makes passwordless cloud auth possible
      
    steps: # unlike jobs, steps run serially on the same runner.
    # if a step exits with a non-zero code, all subsequent steps are skipped and the job is marked failed (unless you set continue-on-error: true

      - uses: actions/checkout@v6
      # runs git clone of repo that belongs to commit SHA that triggered the event, sets up auth credentials for subsequent git commands

      - name: Authenticate to Google Cloud # displayed in GutHub UI and logs output
        id: auth # step ID:  lets later steps reference this step's outputs using steps.auth.outputs.<output_name>
        uses: google-github-actions/auth@v3 # implements Workload Identity Federation (WIF)
        # 1. calls GitHub OIDC endpoint
        # 2. GitHub's OIDC provider returns a signed JWT containing claims like the repository name, branch, workflow name, etc
        # 3. The action sends this JWT to Google's Security Token Service (STS) (sts.googleapis.com)
        # 4. GCP's STS validates the JWT's signature against GitHub's JWKS endpoint (Google has pre-configured trust for your specific GitHub repo/workflow via the WIF pool)
        # 5. STS returns a federated access token: a short-lived OAuth2 token
        # 6. The action then calls iamcredentials.googleapis.com to impersonate the specified service account, exchanging the federated token for a service-account-scoped token
        # 7. This final token is written to $GOOGLE_APPLICATION_CREDENTIALS as a credential file on disk, so all subsequent gcloud/GCP SDK calls automatically pick it up via Application Default Credentials (ADC)
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          # full resource name of the WIF pool provider in GCP, formatted as projects/{project_number}/locations/global/workloadIdentityPools/{pool}/providers/{provider} 
          # => tells the action which GCP endpoint to exchange the OIDC token with
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
          # The GCP service account email to impersonate. The WIF pool's IAM binding must grant roles/iam.workloadIdentityUser to the GitHub identity (matching on repo/branch claims) on this service account — otherwise the impersonation is rejected
```