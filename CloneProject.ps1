param (
    [string]$sourceProjectPath = "D:\MyProject\VNG\Exercise_1_BackgroundJobApp",  # Đường dẫn đến project gốc
    [string]$destinationProjectPath = "D:\Test",  # Đường dẫn đến project mới
    [string]$oldNamespace = "Exercise_1_BackgroundJobApp",                 # Namespace cũ
    [string]$newNamespace = "Exercise_2_BackgroundJobApp"                       # Namespace mới
)

# 1. Kiểm tra nếu thư mục dự án mới đã tồn tại
if (Test-Path -Path $destinationProjectPath) {
    Write-Host "Thư mục đích đã tồn tại. Xóa thư mục cũ trước khi sao chép."
    Remove-Item -Recurse -Force $destinationProjectPath
}

# 2. Lọc các thư mục cần loại trừ khi sao chép
$excludeFolders = @('bin', 'obj', '.git', '.vs')

function Copy-Project {
    param (
        [string]$source,
        [string]$destination
    )

    # Lấy danh sách các thư mục và tệp
    Get-ChildItem -Path $source -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($source.Length)

        # Kiểm tra xem đối tượng hiện tại có nằm trong thư mục bị loại trừ không
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
                # Nếu là thư mục, tạo thư mục tại điểm đích
                if (-not (Test-Path -Path $destPath)) {
                    New-Item -Path $destPath -ItemType Directory
                }
            } else {
                # Nếu là tệp, sao chép tệp sang đích
                Copy-Item -Path $_.FullName -Destination $destPath
            }
        }
    }
}

# 3. Sao chép dự án, bỏ qua các thư mục được loại trừ
Copy-Project -source $sourceProjectPath -destination $destinationProjectPath

# 4. Đổi tên file solution và project
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

# 5. Thay thế namespace trong tất cả các file .cs, .csproj, .sln, .config
Get-ChildItem -Path $destinationProjectPath -Recurse -Include *.cs,*.csproj,*.sln,*.config,*.xml | ForEach-Object {
    (Get-Content -Path $_.FullName) -replace $oldNamespace, $newNamespace | Set-Content -Path $_.FullName
}

Write-Host "Dự án đã được sao chép và namespace đã được đổi từ $oldNamespace sang $newNamespace."


