{ config, pkgs, lib, ... }:

with lib;

let
  # Создаем опции для нашего модуля
  cfg = config.services.sddm-dynamic-theme;
in
{
  options.services.sddm-dynamic-theme = {
    enable = mkEnableOption "Enable dynamic SilentSDDM theme";

    username = mkOption {
      type = types.str;
      description = "The user whose wallpaper will be used for SDDM.";
    };
    
    sourceWallpaperPath = mkOption {
      type = types.str;
      default = "/home/${cfg.username}/.config/ax-shell/current.wall";
      description = "Absolute path to the source wallpaper file.";
    };
  };

  config = mkIf cfg.enable {
    qt.enable = true;
    environment.systemPackages = [ pkgs.custom-silentSDDM pkgs.custom-silentSDDM.test ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "silent";
      extraPackages = pkgs.custom-silentSDDM.propagatedBuildInputs;
      settings.General = {
        GreeterEnvironment = "QML2_IMPORT_PATH=${pkgs.custom-silentSDDM}/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard";
        InputMethod = "qtvirtualkeyboard";
      };
    };

    systemd.services."update-sddm-wallpaper" = {
      description = "Update SDDM wallpaper";
      before = [ "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ imagemagick ];
      serviceConfig = { Type = "oneshot"; User = "root"; Group = "sddm"; };
      script = ''
        if [ ! -f "${cfg.sourceWallpaperPath}" ]; then exit 0; fi
        magick "${cfg.sourceWallpaperPath}" -background black -flatten "/var/lib/sddm/backgrounds/current.jpg"
        chmod 644 "/var/lib/sddm/backgrounds/current.jpg"
      '';
    };

    systemd.paths."update-sddm-wallpaper" = {
      description = "Watch for wallpaper changes to update SDDM";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = cfg.sourceWallpaperPath;
        MakeDirectory = true;
        Unit = "update-sddm-wallpaper.service";
      };
    };
  };
}
