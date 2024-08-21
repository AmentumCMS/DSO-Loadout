# DSO Developer Lowside Loadout

This repo contains a collection of methods to loadout the default PC with additional tools needed for effective development.

### Git Suite

This section is the tooling used for GIT and code management
 
1. Git - The Basic Source code version control used
2. Visual Studio Code - The basic Development IDE used 
3. GutHub CLI - Makes downloads from our GitHub projects much easier
4. Windows Terminal - A handy consolidated multi terminal manager
5. Tortoise Git - A handy Windows Git integration and GUI

```
winget install Git.Git GitHub.cli Microsoft.WindowsTerminal Microsoft.VisualStudioCode Microsoft.VisualStudioCode.CLI TortoiseGit.TortoiseGit 
```

### Virtualization and Containerization Suite

This section is the tooling used for virtualization and containerization

1. Oracle VirualBox - Free Type 2 Hypervisor with a Commercially-Friendly license
2. HashiCorp Vagrant - FLOSS VM Manager used by developers to ease creation and mangement of VMs within git projects
3. Podman & Podman Desktop - A Containerization CLI + GUI that enables the managment and creation of container images
4. Kubectl & K9s - Kubernetes interface CLIs

```
winget install Oracle.VirtualBox Hashicorp.Vagrant RedHat.Podman-Desktop RedHat.Podman Kubernetes.kubectl Kubernetes.minikube Derailed.k9s
```

### Language Suite

This section is the tooling used for languages used by the team

1. Java - Fundimental development Language
2. NodeJS - Fundimental development Language
3. Python - Fundimental development Language
4. PowerShell - Windows programming language

```
winget install Microsoft.OpenJDK.11 Microsoft.OpenJDK.21 Microsoft.OpenJDK.17 OpenJS.NodeJS Python.Python.3.13 Microsoft.PowerShell
```

### Useful Apps

Basic set of apps: 

1. Horizon Client - Used for DoD Desktop Anywhere
2. Putty - SSH Client with CAC Support
3. WGet - Command line downloader

```
winget install GNU.Wget2 NoMoreFood.PuTTY-CAC VMware.HorizonClient
```

### Useful Drivers

```
winget install DisplayLink.GraphicsDriver Poly.PlantronicsHub Logitech.Options Logitech.OptionsPlus
```

## Sustainment

Winget make updates simple!

```
winget upgrade --all
```