{ inputs, ... }:

final: prev: {
  custom-silentSDDM = (final.callPackage "${inputs.silentSDDM}/default.nix" {
    theme = "default";
    theme-overrides = {
      LockScreen.background = "current.jpg";
      LoginScreen.background = "current.jpg";
    };
  }).overrideAttrs (oldAttrs: {
    installPhase = (oldAttrs.installPhase or "") + ''
      rm -rf $out/share/sddm/themes/silent/backgrounds
      ln -s /var/lib/sddm/backgrounds $out/share/sddm/themes/silent/backgrounds
    '';
  });
}
