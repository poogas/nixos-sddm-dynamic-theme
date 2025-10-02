{
  description = "A reusable NixOS module for a dynamic SilentSDDM theme.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    silentSDDM.url = "github:uiriansan/SilentSDDM/cfb0e3eb380cfc61e73ad4bce90e4dcbb9400291";
  };

  outputs =
    {
      self,
      nixpkgs,
      silentSDDM,
    }:
    {
      overlays.default = import ./overlay.nix { inputs = { inherit silentSDDM; }; };

      nixosModules.default = import ./module.nix;
    };
}
