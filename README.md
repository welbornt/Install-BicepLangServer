# Install-Bicep-LangServer
Install the bicep-langserver for Helix

# Installation
Run the following PowerShell command with administrative priveleges.  
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://raw.githubusercontent.com/welbornt/Install-BicepLangServer/refs/heads/main/Install-BicepLangServer.ps1 | Invoke-Expression
```
  
Alternatively, you can download the script and run it locally to use the below optional params:  
  
-DestinationPath  
Specify the destination that the language server should be installed.  
The default distination path is determined by the operating system.  
Windows: `$env:LOCALAPPDATA\Programs\bicep-langserver`  
Mac/Linux: `$HOME/.local/bin/bicep-langserver`  
  
-DownloadPath  
Specify an alternative location that the temporary files should be downloaded to (they are automatically cleaned up after installation).  
The default download location is in the users temporary directory with `[System.IO.Path]::GetTempPath()`  
  
# Validate the language server via Helix
`hx --health | grep bicep`
Note: On Windows you will need to start a new shell session for the path to update so that Helix can find the language server.
