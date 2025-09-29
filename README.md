# NixOS Dynamic SDDM Theme Module

Tired of a static login screen? This NixOS module elegantly solves that problem by synchronizing the background of your [SilentSDDM](https://github.com/uiriansan/SilentSDDM) theme with your current desktop wallpaper.

Now, your login screen will always look as fresh as your desktop!

## ✨ Features

*   **Fully Dynamic:** The SDDM background updates automatically whenever you change your desktop wallpaper.
*   **Seamless Integration:** Guarantees that the correct wallpaper is set **before** SDDM starts, eliminating race conditions during system boot.
*   **Declarative Configuration:** Enabled and configured with just a few lines in your NixOS configuration.
*   **Clean Solution:** Does not require forking the original `SilentSDDM` theme. All customizations are applied on-the-fly via a Nix overlay.
*   **Reusable:** Packaged as a Flake that can be easily integrated into any NixOS project.

## ⚙️ How It Works

This project consists of two main components:

1.  **An Overlay:** This modifies the `SilentSDDM` package at build time. It replaces the theme's static `backgrounds` folder with a symbolic link and overrides the theme configuration to always use a file named `current.jpg`.
2.  **A NixOS Module:** This sets up two `systemd` units to handle the logic:
    *   A service that copies your current wallpaper to a system-wide SDDM directory on every boot. It is guaranteed to run **before** the display manager service starts.
    *   A path watcher that monitors your wallpaper file for changes and triggers the same service to update the background in real-time, after the system has booted.

## 🚀 Installation & Usage

### Prerequisites

*   You are running NixOS with Flakes enabled.
*   You have a mechanism (like [ax-shell](https://github.com/poogas/Ax-Shell)) that updates a file at a specific path whenever your wallpaper changes.

### Step 1: Add this Flake to Your Inputs

In your main `flake.nix`, add `sddm-dynamic-theme` to the `inputs` section.

```nix
# /etc/nixos/flake.nix

{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    
    # ... your other inputs
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Add this repository
    sddm-dynamic-theme = {
      url = "github:poogas/nixos-sddm-dynamic-theme";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.silentSDDM.follows = "silentSDDM";
    };
  };
  
  # ...
}
```

### Step 2: Apply the Overlay

Add the overlay from this flake to your system configuration. This is necessary to customize the `SilentSDDM` package.

```nix
# /etc/nixos/overlays/default.nix (or wherever you manage overlays)

{ inputs, ... }: {
  nixpkgs.overlays = [
    # ... your other overlays
    inputs.sddm-dynamic-theme.overlays.default
  ];
}
```

### Step 3: Import and Configure the Module

Import the module into your NixOS configuration and enable it.

```nix
# /etc/nixos/configuration.nix

{ inputs, ... }: {
  imports = [
    # ... your other imports
    inputs.sddm-dynamic-theme.nixosModules.default # <-- Import the module
  ];

  # ...
  
  # Enable and configure the module
  services.sddm-dynamic-theme = {
    enable = true;
    username = "your-user"; # <-- Set your username
    
    # Optional: If your wallpaper file is located elsewhere,
    # you can override the default path.
    # sourceWallpaperPath = "/home/your-user/.config/wallpapers/current";
  };
  
  # ...
}
```

### Step 4: Rebuild Your System

Run `sudo nixos-rebuild switch --flake .#your-hostname` and enjoy your new dynamic login screen!

## 🔧 Configuration Options

| Option                | Type   | Default                                                  | Description                                                                     |
| --------------------- | ------ | -------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `enable`              | bool   | `false`                                                  | Enables or disables the module.                                                 |
| `username`            | string | (Required)                                               | The username whose wallpaper will be used for the SDDM background.              |
| `sourceWallpaperPath` | string | `"/home/${cfg.username}/.config/ax-shell/current.wall"` | The absolute path to the file that the module should watch for wallpaper changes. |

## 📄 License

This project is licensed under the [MIT License](./LICENSE).
