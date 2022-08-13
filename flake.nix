{
  description = "A flake containing the nixos configurations of most of my personal systems.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wayland-overlay = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    emacs-overlay,
    home-manager,
    nixos-hardware,
    wayland-overlay,
    flake-utils,
    ...
  } @ inputs:
    with flake-utils.lib;
      eachSystem
      [system.aarch64-linux]
      (sys: let
        overlays = [emacs-overlay.overlay wayland-overlay.overlay];
        pkgs = nixpkgs.legacyPackages.${sys};
      in {
        packages = rec {
          hello = pkgs.writeShellApplication {
            name = "helloDotfiles";
            runtimeInputs = [pkgs.coreutils];
            text = ''
              printf "\n\n"
              echo 👋👋 hello from ~averagechris/dotfiles
              echo have a nice day 😎
              printf "\n\n"
            '';
          };
          default = hello;
        };
      })
      // rec {
        overlays = {
          emacs = emacs-overlay.overlay;
          wayland = wayland-overlay.overlay;
        };
        nixosConfigurations = {
          vm = nixpkgs.lib.nixosSystem {
            system = system.aarch64-linux;
            specialArgs = {
              inherit (self.outputs) overlays;
              inherit inputs;
            };
            modules = [
              #./nixpkgs/nixos/users/chris-minimal.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              }
            ];
          };
        };
      };
}
