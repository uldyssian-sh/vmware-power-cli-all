# PowerCLI One-Shot Installer (User Scope, Non-Admin Safe)

**Author:** LT  
**Version:** 1.0  

This repository contains a hardened, console-friendly script to install or update **VMware.PowerCLI** **without Administrator rights**.  
It strictly targets **CurrentUser** scope and includes robust fallbacks to handle constrained environments.

---

## License for This Repository
This repository’s own content (README, file list, structure) is licensed under the MIT License. See LICENSE for details.

---

## What’s new in this version?

- Always installs to **CurrentUser** (never AllUsers).
- Adds a **3-stage** install strategy:
  1. `Install-PSResource` (PSResourceGet)  
  2. `Install-Module` (PowerShellGet)  
  3. `Save-Module` + stage into user module path  
- Verifies/creates the **user module path** and ensures it’s in `PSModulePath`.
- Better **diagnostics** and clear console status lines.
- Optional switches: `-TrustPSGallery`, `-DisableCeip`.

---

## Requirements

- **PowerShell** 5.1 or **PowerShell 7+**  
- Internet access to **PowerShell Gallery** (or corporate mirror)

> Admin rights are **not** required unless your organization blocks user-scoped package installs entirely.

---

## Quick Start

1. Download `Install-PowerCLI-All.ps1`.
2. Open **PowerShell** (or **PowerCLI**).
3. (Optional) Allow script execution for this session only:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

4. Install PowerCLI to your user profile:
   .\Install-PowerCLI-All.ps1 -DisableCeip -TrustPSGallery

After running:
You’ll see a green summary and a table of all VMware.* modules (name, version, path).
Connect to vCenter:
Connect-VIServer -Server vcsa.example.com


## How it works (under the hood)
The script tries three methods (in order) and stops at the first success:
1. PSResourceGet (modern):
   Install-PSResource -Name VMware.PowerCLI -Scope CurrentUser
2. PowerShellGet (classic):
   Install-Module -Name VMware.PowerCLI -Scope CurrentUser
3. PowerShellGet Save-Module (staging fallback):
   * Downloads the module to a temp folder with Save-Module
   * Copies the version folder(s) into your user modules path
   * Imports VMware.PowerCLI

The script also:
* Registers PSGallery if missing (best effort to mark as Trusted).
* Ensures the NuGet provider is available for CurrentUser.
* Creates and prepends the user module path to PSModulePath.

## Troubleshooting

“Administrator rights are required …”
This hardened script already installs to CurrentUser and avoids AllUsers.
If you still get the error on all three attempts, your organization likely enforces a policy that blocks user-scoped package installs. Options:
* Use a corporate PowerShell repository that allows user installs.
* Run the script from an elevated session (if allowed).
* Ask IT to pre-provision VMware.PowerCLI into your user profile.

  “PSGallery is not trusted” prompts:
  .\Install-PowerCLI-All.ps1 -TrustPSGallery

If policy blocks trusting PSGallery, you might still see prompts—answer Yes to continue.
“NuGet provider missing” or provider errors
The script installs NuGet for CurrentUser automatically:
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser

If blocked by policy, contact your administrator or use your corporate feed.
Module import fails after install
Verify PSModulePath includes your user modules path printed in the summary.
You can also run: $env:PSModulePath -split ';'

## Uninstall (user scope)
To remove PowerCLI from your user profile:
$path = if ($PSVersionTable.PSEdition -eq 'Core') {
  Join-Path $HOME 'Documents\PowerShell\Modules\VMware.PowerCLI'
} else {
  Join-Path $HOME 'Documents\WindowsPowerShell\Modules\VMware.PowerCLI'
}
Remove-Item -Recurse -Force $path


  
