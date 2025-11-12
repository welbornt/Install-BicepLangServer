param(
	[Parameter(Mandatory=$false)]
	[string]$DownloadPath = [System.IO.Path]::GetTempPath(),
	[Parameter(Mandatory=$false)]
	[string]$DestinationPath = ""
)

# Identify the OS
$os = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'MacOS' } else { 'Unknown' }

# Validate the script is running with admin priveleges
switch ($os){
	'Windows' {
		if (!
			(New-Object Security.Principal.WindowsPrincipal(
			[Security.Principal.WindowsIdentity]::GetCurrent()
			)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
		){
			Write-Host "Insufficient priveleges. Re-run as Administrator."
			exit 1
		}
	}
	Defult {
		if (([System.Environment]::UserName -ne 'root') -and ((id -u) -ne 0)){
			Write-Host "Insufficient priveleges. Re-run with sudo."
			exit 1
		}
		if ($null -eq (Get-Command -Name 'dotnet' -ErrorAction SilentlyContinue)){
			Write-Host "Command 'dotnet' not found. Install dotnet and re-run."
			exit 2
		}
	}
}

# If no install directory is specified, set it to the default
if ($DestinationPath -eq ""){
	switch ($os){
		'Windows' {
			$installDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Programs"
		}
		Default {
			$installDir = Join-Path -Path $HOME -ChildPath ".local/bin"
		}
	}
}
else {
	$installDir = $DestinationPath
}
$installDir = Join-Path -Path $installDir -ChildPath 'bicep-langserver'

# Define variables for downloading the lsp
$fileName = 'bicep-langserver.zip'
$apiUri = 'https://api.github.com/repos/Azure/bicep/releases/latest'
$headers = @{
	'User-Agent' = 'Bicep.Helix'
	'Accept' = 'application/vnd.github.v3+json'
}

# Download the lsp and extract it
$asset = (Invoke-RestMethod -Uri $apiUri -Headers $headers).Assets | Where-Object { $_.name -eq $fileName }
$archivePath = Join-Path -Path $DownloadPath -ChildPath $fileName
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
if (!(Test-Path $installDir)){ New-Item -ItemType Directory -Path $installDir -Force }
Expand-Archive -Path $archivePath -DestinationPath $installDir -Force

# Copy the lsp exe (Windows) or create the caller script and add it to the path
switch ($os){
	'Windows' {
		Copy-Item -Path (Join-Path -Path $installDir -ChildPath 'Bicep.LangServer.exe') -Destination (Join-Path -Path $installDir -ChildPath 'bicep-langserver.exe')
		$currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
		$updatedPath = "$installDir;$currentPath"
		[System.Environment]::SetEnvironmentVariable('Path', $updatedPath, [System.EnvironmentVariableTarget]::User)
	}
	Default {
		# Create a script to execute the dll per https://github.com/helix-editor/helix/discussions/7881#discussioncomment-6724773
		$scriptContent = "#!/usr/bin/env sh`nexec dotnet $installDir/Bicep.LangServer.dll"
		$scriptPath = Join-Path -Path '/usr/local/bin' -ChildPath 'bicep-langserver'
		Set-Content -Path $scriptPath -Force -Value $scriptContent
		if (!$?){
			Write-Host "There was an error accessing /usr/local/bin. Re-run the script with admin priveleges."
			exit 3
		}
		Invoke-Expression -Command "chmod +x $scriptPath"
	}
}

# Wrap up
if (!$?){
	Write-Host "There was an error installing bicep-langserver."
	exit 4
}
Remove-Item -Path $archivePath -Force

Write-Host "Successfully installed bicep-langserver."
