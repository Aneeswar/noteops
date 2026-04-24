# NoteOps GitOps Project

A complete GitOps workflow for a Node.js note-taking application using GitHub Actions, Helm, ArgoCD, and Kind.

## GitOps Flow

```text
[ Developer ] --(push)--> [ App Repo ]
                               |
                        [ GitHub Action ]
                               |
               (Build/Push Docker Image to Hub)
                               |
               (Update Tag in Config Repo values.yaml)
                               |
                               v
                        [ Config Repo ] <---(watch)--- [ ArgoCD ]
                                                           |
                                                    (Sync to Cluster)
                                                           |
                                                    [ Kind Cluster ]
```

## Prerequisites

- **Windows 10/11**
- **Docker Desktop** installed and running
- **GitHub Account**

## Required Secrets

In your **App Repository** (`noteops`), add the following GitHub Actions secrets:

1. `DOCKERHUB_USERNAME`: Your Docker Hub username (`aneeswar`).
2. `DOCKERHUB_TOKEN`: A Docker Hub Access Token.
3. `CONFIG_REPO_PAT`: A GitHub Personal Access Token with `repo` scope (Write access to `notesops-config`).

## Project Structure

- **App Repo (`/app`)**: Express API, HTML Frontend, Dockerfile, and CI Workflow.
- **Config Repo (`/notesops-config`)**: Helm Chart and ArgoCD Application manifest.
- **`setup.ps1`**: PowerShell script to bootstrap the local environment.

## Getting Started

1. **Create the Repositories**:
   - Create `noteops` and `notesops-config` on GitHub.
   - Push the respective folders to each repo.

2. **Run the Setup Script**:
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
