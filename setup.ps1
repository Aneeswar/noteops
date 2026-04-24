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

# 4. Install ArgoCD
Write-Host "Installing ArgoCD..." -ForegroundColor Cyan
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "Waiting for ArgoCD pods..." -ForegroundColor Yellow
kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=300s

# 5. Extract ArgoCD Admin Password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
$decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
Write-Host "`nArgoCD Login: admin / $decodedPassword" -ForegroundColor Green

# 6. Apply ArgoCD Application
Write-Host "Applying ArgoCD Application..." -ForegroundColor Cyan
kubectl apply -f notesops-config/argocd-app.yaml

Write-Host "`nSetup Complete! Access your app at http://localhost" -ForegroundColor Green
Write-Host "Initial sync might take a minute."
