# PowerShell script to setup Kind, Nginx Ingress, and ArgoCD on Windows

function Install-Tool {
    param($Name, $Command)
    if (!(Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $Name..." -ForegroundColor Cyan
        winget install --id $Name -e --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "$Name is already installed." -ForegroundColor Green
    }
}

# 1. Install Dependencies
Install-Tool "Docker.DockerDesktop" "docker"
Install-Tool "Kubernetes.Kind" "kind"
Install-Tool "Kubernetes.kubectl" "kubectl"
Install-Tool "Helm.Helm" "helm"

# 2. Create Kind Cluster with Ingress mapping
Write-Host "Creating Kind cluster..." -ForegroundColor Cyan
$kindConfig = @"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
"@
$kindConfig | Out-File -FilePath kind-config.yaml -Encoding utf8
kind create cluster --name noteops-cluster --config kind-config.yaml

# 3. Install NGINX Ingress Controller
Write-Host "Installing NGINX Ingress Controller..." -ForegroundColor Cyan
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
Write-Host "Waiting for Ingress Controller..." -ForegroundColor Yellow
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# 4. Install ArgoCD + Extensions (Rollouts, Image Updater)
Write-Host "Installing ArgoCD + Rollouts + Image Updater..." -ForegroundColor Cyan
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Argo Rollouts Controller
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# ArgoCD Image Updater
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

# Prometheus & Grafana (via Kustomize in Config Repo later, or light install here)
Write-Host "Waiting for controllers..." -ForegroundColor Yellow
kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=300s

# 5. Apply V2 ArgoCD Root Application (App of Apps)
Write-Host "Applying V2 ArgoCD Bootstrappers..." -ForegroundColor Cyan
kubectl apply -f notesops-config/argocd/argocd-app-dev.yaml
kubectl apply -f notesops-config/argocd/argocd-app-prod.yaml

Write-Host "`nSetup Complete! Access your app at http://localhost" -ForegroundColor Green
Write-Host "Initial sync might take a minute."
