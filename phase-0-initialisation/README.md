# Phase 0: Initialization and Preparation

*Read the [French Version (Version Française)](README_FR.md) here.*

## Objective
Initialize the SRE repository architecture (Project 3), building upon the infrastructure and application from Project 2 (DevSecOps). Set up the necessary foundations for the future addition of observability, reliability, and chaos engineering components.

## Status
**Completed**

## Actions Performed

1. **Source Code Migration**
   - Transferred Project 2 assets: application code (`/app`), Infrastructure as Code (`/terraform`), the CI/CD workflow (`.github/`), and the SonarQube configuration (`sonar-project.properties`).
   - Cleaned up temporary or unused files from the previous project.

2. **Version Control Initialization**
   - Initialized a clean Git repository tailored for the SRE project.
   - Created and adapted the `.gitignore` to exclude future artifacts related to local SRE tools (Prometheus/Grafana data) in addition to usual exclusions (node_modules, terraform.tfstate, secrets).
   - Validated and pushed the initial commit ("baseline") to GitHub.

3. **Validation of Existing Setup (CI/CD and OIDC)**
   - Verified secure authentication with Azure via OIDC (OpenID Connect), preventing credential leakage.
   - Verified that the pre-existing CI/CD pipeline (inherited from Project 2) is ready and executes correctly to deploy the application and the initial infrastructure without the SRE layers.

## Associated Directories
- `app/`
- `terraform/`
- `.github/`
- `PLAN.md`
