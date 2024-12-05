# Vérifier si le module ImportExcel est installé
$moduleName = "ImportExcel"

# Vérifie si l'utilisateur actuel est un administrateur
$isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # Applique la politique d'exécution Unrestricted uniquement pour les administrateurs
    Set-ExecutionPolicy Unrestricted -Scope Process
}

# Vérification de l'existence du module
if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Write-Host "$moduleName n'est pas installé. Installation en cours..."
    
    # Installer le module ImportExcel depuis le PowerShell Gallery
    try {
        Install-Module -Name $moduleName -Force -Scope CurrentUser
        Write-Host "$moduleName installé avec succès."
    } catch {
        Write-Host "Erreur lors de l'installation du module $moduleName : $_"
        exit 1
    }
} else {
    Write-Host "$moduleName est déjà installé."
}


# Fonction pour retirer les accents des caractères
function Remove-Accents {
    param (
        [string]$input
    )
    $output = $input -replace 'é', 'e' `
                    -replace 'è', 'e' `
                    -replace 'ê', 'e' `
                    -replace 'ë', 'e' `
                    -replace 'à', 'a' `
                    -replace 'á', 'a' `
                    -replace 'â', 'a' `
                    -replace 'ä', 'a' `
                    -replace 'ç', 'c' `
                    -replace 'î', 'i' `
                    -replace 'ï', 'i' `
                    -replace 'ô', 'o' `
                    -replace 'ó', 'o' `
                    -replace 'ö', 'o' `
                    -replace 'ù', 'u' `
                    -replace 'û', 'u' `
                    -replace 'ü', 'u' `
                    -replace 'ÿ', 'y' `
                    -replace 'œ', 'oe' `
                    -replace 'æ', 'ae'
    return $output
}

# Demander à l'utilisateur de saisir le chemin du fichier source .xlsx
$sourceFile = Read-Host "Veuillez entrer le chemin complet du fichier source .xlsx"

# Vérifier si le fichier source existe
if (-not (Test-Path $sourceFile)) {
    Write-Host "Le fichier source spécifié n'existe pas. Veuillez vérifier le chemin."
    exit 1
}

# Demander à l'utilisateur de saisir le chemin du fichier de sortie .csv
$csvFile = Read-Host "Veuillez entrer le chemin complet du fichier de sortie .csv (ex. C:\dossier\monfichier.csv)"

# Si l'utilisateur ne spécifie pas de chemin, utiliser le chemin actuel par défaut
if (-not $csvFile) {
    $csvFile = Join-Path (Get-Location) "fichier_converti.csv"
    Write-Host "Le fichier CSV sera créé dans le répertoire courant : $csvFile"
}

# Importer les données du fichier Excel (première feuille)
try {
    $excelData = Import-Excel -Path $sourceFile
    Write-Host "Fichier Excel importé avec succès."
} catch {
    Write-Host "Erreur lors de l'importation du fichier Excel : $_"
    exit 1
}

# Traiter les données pour supprimer les accents dans chaque cellule
$excelData = $excelData | ForEach-Object {
    $newObj = $_ | Select-Object *
    $newObj.PSObject.Properties.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [string]) {
            $_.Value = Remove-Accents $_.Value
        }
    }
    $newObj
}

# Exporter les données au format CSV
try {
    $excelData | Export-Csv -Path $csvFile -NoTypeInformation
    Write-Host "Conversion en CSV réussie ! Le fichier a été enregistré à : $csvFile"
} catch {
    Write-Host "Erreur lors de l'exportation en CSV : $_"
    exit 1
}
