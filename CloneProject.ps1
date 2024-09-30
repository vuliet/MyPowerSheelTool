param (
    [string]$sourceProjectPath = "D:\Source\CompanyDemo",  # Path to the original project
    [string]$destinationProjectPath = "D:\Test",  # Path to the new project
    [string]$oldNamespace = "CompanyDemo",                 # Old namespace
    [string]$newNamespace = "CompanyDemo2"                       # New namespace
)

# 1. Check if the destination project folder already exists
if (Test-Path -Path $destinationProjectPath) {
    Write-Host "The destination folder already exists. Deleting the old folder before copying."
    Remove-Item -Recurse -Force $destinationProjectPath
}

# 2. Exclude folders when copying
$excludeFolders = @('bin', 'obj', '.git', '.vs')

function Copy-Project {
    param (
        [string]$source,
        [string]$destination
    )

    # Get list of directories and files
    Get-ChildItem -Path $source -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($source.Length)

        # Check if the current item is in an excluded folder
        $shouldExclude = $false
        foreach ($excludeFolder in $excludeFolders) {
            if ($_.FullName -like "*\$excludeFolder\*" -or $_.Name -in $excludeFolders) {
                $shouldExclude = $true
                break
            }
        }

        if (-not $shouldExclude) {
            $destPath = Join-Path $destination $relativePath

            if ($_.PSIsContainer) {
                # If it's a folder, create the folder at the destination
                if (-not (Test-Path -Path $destPath)) {
                    New-Item -Path $destPath -ItemType Directory
                }
            } else {
                # If it's a file, copy the file to the destination
                Copy-Item -Path $_.FullName -Destination $destPath
            }
        }
    }
}

# 3. Copy the project, excluding the excluded folders
Copy-Project -source $sourceProjectPath -destination $destinationProjectPath

# 4. Rename solution and project files
$oldSolutionFile = Get-ChildItem -Path $destinationProjectPath -Filter "*.sln"
$oldProjectFile = Get-ChildItem -Path $destinationProjectPath -Filter "*.csproj"

if ($oldSolutionFile) {
    $newSolutionFile = $oldSolutionFile.FullName -replace [regex]::Escape($oldNamespace), $newNamespace
    Rename-Item -Path $oldSolutionFile.FullName -NewName (Split-Path $newSolutionFile -Leaf)
}

if ($oldProjectFile) {
    $newProjectFile = $oldProjectFile.FullName -replace [regex]::Escape($oldNamespace), $newNamespace
    Rename-Item -Path $oldProjectFile.FullName -NewName (Split-Path $newProjectFile -Leaf)
}

# 5. Replace namespace in all .cs, .csproj, .sln, .config files
Get-ChildItem -Path $destinationProjectPath -Recurse -Include *.cs,*.csproj,*.sln,*.config,*.xml | ForEach-Object {
    (Get-Content -Path $_.FullName) -replace $oldNamespace, $newNamespace | Set-Content -Path $_.FullName
}

Write-Host "The project has been copied and the namespace has been changed from $oldNamespace to $newNamespace."
