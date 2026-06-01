#Requires -Module Az.KeyVault

param(
    [string]$ResourceGroupName = "rg-biblioteca",
    [string]$Location = "westeurope",
    [string]$Sku = "Standard"
)

$randomSuffix = -join ((65..90) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$keyVaultName = "kv-biblioteca-$randomSuffix"

Write-Host "=== Creación de Key Vault ===" -ForegroundColor Cyan
Write-Host "Resource Group : $ResourceGroupName"
Write-Host "Location        : $Location"
Write-Host "Key Vault Name  : $keyVaultName"
Write-Host ""

# 1. Create Resource Group
Write-Host "[1/4] Creando Resource Group..." -ForegroundColor Yellow
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    Write-Host "  ✓ Resource Group '$ResourceGroupName' creado en $Location" -ForegroundColor Green
}
else {
    Write-Host "  ✓ Resource Group '$ResourceGroupName' ya existe" -ForegroundColor Green
}

# 2. Create Key Vault
Write-Host "[2/4] Creando Key Vault..." -ForegroundColor Yellow
$kv = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue
if (-not $kv) {
    $kv = New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $ResourceGroupName -Location $Location -Sku $Sku -EnableSoftDelete -EnablePurgeProtection
    Write-Host "  ✓ Key Vault '$keyVaultName' creado" -ForegroundColor Green
}
else {
    Write-Host "  ✓ Key Vault '$keyVaultName' ya existe" -ForegroundColor Green
}

# 3. Enable RBAC authorization (disable vault access policy)
Write-Host "[3/4] Configurando RBAC..." -ForegroundColor Yellow
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -EnabledForDeployment -EnabledForTemplateDeployment
Write-Host "  ✓ Acceso RBAC configurado" -ForegroundColor Green

# 4. Assign current user Key Vault Administrator role
Write-Host "[4/4] Asignando rol Key Vault Administrator al usuario actual..." -ForegroundColor Yellow
$currentUser = Get-AzContext
$currentUserId = $currentUser.Account.Id
if (-not $currentUserId) {
    Write-Warning "No se pudo obtener el usuario actual. Asigna el rol manualmente."
}
else {
    # Use RBAC role assignment
    $roleAssignment = New-AzRoleAssignment -ObjectId $currentUserId `
        -RoleDefinitionName "Key Vault Administrator" `
        -Scope $kv.ResourceId `
        -ErrorAction SilentlyContinue

    if ($roleAssignment) {
        Write-Host "  ✓ Rol asignado a '$currentUserId'" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ El usuario '$currentUserId' ya tiene el rol o no se pudo asignar automáticamente." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Resumen ===" -ForegroundColor Cyan
Write-Host "Key Vault Name : $keyVaultName"
Write-Host "Resource Group : $ResourceGroupName"
Write-Host "Vault URI      : $($kv.VaultUri)"
Write-Host ""

# Create JWT secret and store in Key Vault
Write-Host "¿Deseas crear un JWT Secret en el Key Vault? (s/n)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq "s") {
    $jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object { [char]$_ })
    $secret = ConvertTo-SecureString -String $jwtSecret -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "jwt-secret" -SecretValue $secret | Out-Null
    Write-Host "  ✓ JWT Secret almacenado en Key Vault como 'jwt-secret'" -ForegroundColor Green
}

Write-Host ""
Write-Host "Para usar en tus servicios, establece esta variable de entorno:" -ForegroundColor Cyan
Write-Host "KeyVaultName=$keyVaultName" -ForegroundColor White
