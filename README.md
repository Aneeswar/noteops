# NoteOps GitOps Project V2 - Advanced Edition

A production-grade GitOps workflow for a Node.js Express application featuring:
- **Kustomize** for Multi-Environment Management (Dev/Prod).
- **Argo Rollouts** for Canary Deployments.
- **Prometheus & Grafana** for Observability.
- **Jest & Newman** for Automated Testing.
- **ArgoCD Image Updater** for manifest-free updates.

## GitOps Flow V2

```text
[ Dev Push ] -> [ GitHub CI ] -> [ Unit Tests ] -> [ Push Image ] -> [ Update Dev Kustomize ]
                                                                             |
                                                                       [ ArgoCD Sync ]
                                                                             |
                                                                      [ Argo Rollout ]
                                                                   (Canary: 10% -> 50% -> 100%)
                                                                             |
[ Manual Promotion ] -> [ .\promote.ps1 ] -> [ Update Prod Kustomize ] -> [ Prod Sync ]
```

## Prerequisites

- **Windows 10/11**
- **Docker Desktop** (running)
- **GitHub Account** & **Docker Hub Account**

## Required Secrets (App Repo)

1. `DOCKERHUB_USERNAME`: `aneeswar`
2. `DOCKERHUB_TOKEN`: Docker Hub PAT
3. `CONFIG_REPO_PAT`: GitHub PAT (repo scope)

## Project Structure

- **`app/`**: Node.js API with `/metrics` and `/health`, unit tests, and Dockerfile.
- **`notesops-config/`**:
  - `deploy/kustomize/base`: Shared Kubernetes resources.
  - `deploy/kustomize/overlays/dev`: Dev-specific settings + Rollout.
  - `deploy/kustomize/overlays/prod`: Prod-specific settings + Rollout.
  - `argocd/`: Application manifests for both environments.
- **`setup.ps1`**: Installs Kind, Nginx, ArgoCD, Rollouts, and Image Updater.
- **`promote.ps1`**: Promotes the current dev tag to production.

## Getting Started

1. **Bootstrap**: Run `.\setup.ps1` to create the cluster and install all controllers.
2. **Promote**: Run `.\promote.ps1 -SourceEnv dev -TargetEnv prod` to ship to production.
3. **Monitor**: Access Grafana at `http://localhost/grafana` (if configured in ingress).
   Open PowerShell as Administrator and run:
   ```powershell
   .\setup.ps1
   ```
   This will install Kind, Helm, and Kubectl (via WinGet), create the cluster, and install ArgoCD.

3. **Log in to ArgoCD**:
   The script will print the `admin` password. Access the dashboard:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Visit `https://localhost:8080`.

4. **Access the App**:
   Once ArgoCD syncs the application, access it at:
   `http://localhost`

## Triggering a Deployment

1. Modify `app/public/index.html` or `app/server.js`.
2. Push your changes to `main`.
3. GitHub Actions will:
   - Build a new image tagged with the Git SHA.
   - Update `deploy/helm/values.yaml` in the `notesops-config` repo.
4. ArgoCD will detect the change and update the deployment automatically.
