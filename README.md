# NixOS Dynamic SDDM Theme Module

Tired of a static login screen? This NixOS module elegantly solves that problem by synchronizing the background of your [SilentSDDM](https://github.com/uiriansan/SilentSDDM) theme with your current desktop wallpaper **and** setting your user avatar.

Now, your login screen will always look as fresh and personalized as your desktop!

## ✨ Features

*   **Dynamic Wallpaper:** The SDDM background updates automatically whenever you change your desktop wallpaper.
*   **Dynamic Avatar:** Automatically sets and crops your user avatar for the SDDM login screen.
*   **Seamless Integration:** Guarantees that the correct wallpaper is set **before** SDDM starts, eliminating race conditions during system boot.
*   **Declarative Configuration:** Enabled and configured with just a few lines in your NixOS configuration.
*   **Clean Solution:** Does not require forking the original `SilentSDDM` theme. All customizations are applied on-the-fly via a Nix overlay.
*   **Reusable:** Packaged as a Flake that can be easily integrated into any NixOS project.

## ⚙️ How It Works

This project consists of two main components:

1.  **An Overlay:** This modifies the `SilentSDDM` package at build time. It replaces the theme's static `backgrounds` folder with a symbolic link and overrides the theme configuration to always use a file named `current.jpg`.
2.  **A NixOS Module:** This configures `systemd` units and services to handle the dynamic logic:
    *   **Wallpaper Service:** On every boot, this service copies your current wallpaper to a system-wide SDDM directory. It is guaranteed to run **before** the display manager starts.
    *   **Wallpaper Watcher:** This path watcher monitors your wallpaper file for changes and triggers the service to update the background in real-time.
    *   **Avatar Management:** The module processes your source avatar image (cropping and resizing it) and creates the necessary symbolic link for the `AccountsService` that SDDM uses to display user pictures.

## 🚀 Installation & Usage

### Prerequisites

*   You are running NixOS with Flakes enabled.
*   You have a mechanism (like [ax-shell](https://github.com/poogas/Ax-Shell)) that updates a file at a specific path whenever your wallpaper changes.
*   You have a source image file for your user avatar.

### Step 1: Add this Flake to Your Inputs

In your main `flake.nix`, add this repository to the `inputs` section.

```nix
# /etc/nixos/flake.nix

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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

{ config, inputs, username, ... }: {
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
    
    # Enable the avatar feature
    avatar = {
      enable = true;
      # Provide the path to your avatar image.
      # This can be a static path or a dynamic one from another module.
      sourcePath = config.home-manager.users.${username}.programs.ax-shell.settings.defaultFaceIcon;
    };
  };

  # ...
}
```

### Step 4: Rebuild Your System

Run `sudo nixos-rebuild switch --flake .#your-hostname` and enjoy your new fully personalized login screen!

## 🔧 Configuration Options

| Option                                | Type   | Default                                            | Description                                                                     |
| ------------------------------------- | ------ | -------------------------------------------------- | ------------------------------------------------------------------------------- |
| `enable`                              | bool   | `false`                                            | Enables or disables the module.                                                 |
| `username`                            | string | (Required)                                         | The username whose wallpaper and avatar will be used.                           |
| `sourceWallpaperPath`                 | string | `"/home/${cfg.username}/.config/ax-shell/current.wall"` | The absolute path to the file to watch for wallpaper changes.                  |
| `avatar.enable`                       | bool   | `false`                                            | Enables or disables the dynamic avatar feature.                                 |
| `avatar.sourcePath`                   | string | (Required if `avatar.enable` is true)              | The absolute path to the source image file for the user's avatar.               |

## 📄 License

This project is licensed under the [MIT License](./LICENSE).
