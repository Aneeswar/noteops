param(
    [Parameter(Mandatory=$true)]
    [string]$SourceEnv, # e.g. "dev"
    [Parameter(Mandatory=$true)]
    [string]$TargetEnv  # e.g. "prod"
)

Write-Host "Promoting image from $SourceEnv to $TargetEnv..." -ForegroundColor Cyan

# 1. Get current image from source overlay
$sourcePath = "notesops-config/deploy/kustomize/overlays/$SourceEnv/kustomization.yaml"
$targetPath = "notesops-config/deploy/kustomize/overlays/$TargetEnv/kustomization.yaml"

if (!(Test-Path $sourcePath)) {
    Write-Error "Source environment $SourceEnv not found at $sourcePath"
    exit 1
}

# Simple regex to find the image tag in kustomization.yaml
$content = Get-Content $sourcePath -Raw
if ($content -match "newTag: (.*)") {
    $tag = $matches[1].Trim()
    Write-Host "Found tag: $tag" -ForegroundColor Green
} else {
    Write-Error "Could not find newTag in $sourcePath"
    exit 1
}

# 2. Update target overlay
Write-Host "Updating $targetPath with tag $tag..." -ForegroundColor Yellow
$targetContent = Get-Content $targetPath -Raw
$newTargetContent = $targetContent -replace "newTag: .*", "newTag: $tag"
$newTargetContent | Out-File -FilePath $targetPath -Encoding utf8

# 3. Commit and Push
cd notesops-config
git add .
git commit -m "promote: $SourceEnv to $TargetEnv tag $tag"
git push
cd ..

Write-Host "Promotion complete! ArgoCD will now sync $TargetEnv." -ForegroundColor Green
