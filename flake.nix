# flake.nix
{
  description = "Minimal home-manager flake for ubuntu user";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  {
    homeManagerConfigurations.ubuntu =
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home.nix ];
    };

    # Allow `nix run .#home-manager` to work.
    packages.x86_64-linux.home-manager = home-manager.packages.x86_64-linux.default;
  };
}