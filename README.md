# DSO Developer Lowside Loadout

This repo contains a collection of methods to loadout the default PC with additional tools needed for effective development.

### Git Suite

This section is the tooling used for GIT and code management

 ```
 winget install Git.Git GitHub.cli Microsoft.WindowsTerminal Microsoft.VisualStudioCode Microsoft.VisualStudioCode.CLI TortoiseGit.TortoiseGit 
 ```
 
 ### Virtualization and Containerization Suite
 
 This section is the tooling used for virtualization and containerization

 ```
winget install Oracle.VirtualBox Hashicorp.Vagrant RedHat.Podman-Desktop RedHat.Podman Kubernetes.kubectl Kubernetes.minikube Derailed.k9s
 ```

 ### Language Suite

 This section is the tooling used for languages used by the team

 ```
 winget install Microsoft.OpenJDK.11 Microsoft.OpenJDK.21 Microsoft.OpenJDK.17 OpenJS.NodeJS Python.Python.3.13 Microsoft.PowerShell
 ```

 ### Useful Apps
 
 Basic set of apps: WGet, Putty+CAC Support, & VMware Horizon Client

 ```
 winget install GNU.Wget2 NoMoreFood.PuTTY-CAC VMware.HorizonClient
 ```

Additional useful apps that Pappas uses

 ```
winget install Microsoft.PowerToys RamenSoftware.7+TaskbarTweaker Bitwarden.Bitwarden  Bitwarden.CLI
```

### Useful Drivers

```
winget install DisplayLink.GraphicsDriver Poly.PlantronicsHub Logitech.Options Logitech.OptionsPlus
```

## Sustainment

```
winget upgrade --all
```