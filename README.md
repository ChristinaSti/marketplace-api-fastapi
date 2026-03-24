# marketplace-api-fastapi
Demo project.

purpose of `_notes`: "document" decisions, collect some new ad old knowledge
## Applied principles and tools:
- python web framework for building APIs: **FastAPI**
- python package and project manager: **uv**
- git remote repository: **GitHub Repository**
- issue tracking and project management: **Github Projects**
- git branching strategy: **trunk-based deployment**
- linting and formatting: **ruff**
- testing: **pytest**
- CI/CD: **GitHub Actions**
- Relational Database Management System: **PostgreSQL**
- Object-relational mapping (**ORM**)
- Python SQL toolkit and object-relational mapper: **SQLAlchemy2.0**
- Versioned database schema migration: **Alembic**
- App configuration loading and validation: **pydantic**
- Containerization: **Docker** (**multi-stage build**)
- Web Server: **Uvicorn** (may be combined with Gunicorn for multi-processing/vertical scaling within each Cloud Run instance in case of consistent high CPU load rather than high I/O load)
- Infrastructure as Code: **Terraform**
- Cloud Platform: **GCP**
    - Container image storage: **GCP Artifact Registry**
    - Service deployment: **Cloud Run (serverless)**
    - Database: **Cloud SQL**
    - **Networking**: 
        - Private network: **Virtual private cloud (VPC)**
        - access to Google's managed services (here Cloud SQL) run in Google's own VPC: **VPC Peering** via **Private Services Access (PSA)**
        - access to serverless services (here Cloud Run): **VPC Access Connector**
        - **Firewall**: explicit deny all Ingress for logging attempts
