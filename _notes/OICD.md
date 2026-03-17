# OIDC identity token

- OIDC = OpenID Connect
-  it's an identity layer built on top of the OAuth 2.0 standard, it's a widely adopted open protocol
- it's a JWT (JSON Web Token) — a short-lived, cryptographically signed blob of JSON
- example decoded token payload:
``` json
{
  "iss": "https://token.actions.githubusercontent.com",
  "repository": "your-org/your-repo",
  "ref": "refs/heads/main",
  "workflow": "CD",
  "job_workflow_ref": "your-org/your-repo/.github/workflows/cd.yml@refs/heads/main"
}
```
- asymmetric cryptography math guarantees: anything signed with the private key can be verified with the public key, but the public key cannot be used to forge new signatures
- what does **'signing'** mean, how is JWT created?
    1. Build the token payload (repo name, branch, workflow, expiry, etc.)
    2. Hash the payload → a fixed-length fingerprint e.g. "a3f9c2..."
    3. Encrypt that hash with the private key → the "signature"
    4. Attach the signature to the token
        => final JWT: `base64(header) . base64(payload) . base64(signature)`
- what does **verifying** mean?
    1. Fetch GitHub's public keys from:
   https://token.actions.githubusercontent.com/.well-known/jwks
    2. Decrypt the signature using the public key → recovers the hash
    3. Independently hash the token payload
    4. Compare the two hashes — if they match, the signature is valid
---

### Why is it Used?

The problem it solves is **"how does GCP know it's really GitHub calling?"** — without you having to store a long-lived password or key anywhere.

The alternative (a service account JSON key) is essentially a password. It lives in GitHub Secrets indefinitely, has to be manually rotated, and if it leaks it's valid until someone notices. OIDC eliminates all of that.

---

### How Does it Work? (Step by Step)
```
GitHub Runner                GitHub's OIDC Provider          GCP
     │                              │                          │
     │── "give me a token" ────────>│                          │
     │<─ signed JWT ───────────────│                          │
     │                              │                          │
     │── "here's my JWT, give me GCP access" ──────────────>  │
     │         GCP verifies JWT signature against              │
     │         GitHub's public keys (fetched from             │
     │         token.actions.githubusercontent.com)            │
     │         and checks your WIF trust conditions            │
     │<─ short-lived GCP access token (1 hour) ────────────── │
     │                              │                          │
     │── deploy using access token ──────────────────────────>│
```