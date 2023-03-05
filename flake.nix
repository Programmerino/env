{
  nixConfig.extra-substituters = [
    "https://programmerino.cachix.org"
    "https://hyprland.cachix.org"
  ];

  nixConfig.extra-trusted-public-keys = [
    "programmerino.cachix.org-1:v8UWI2QVhEnoU71CDRNS/K1CcW3yzrQxJc604UiijjA="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];

  description = "Home Manager configuration of Davis Davalos-DeLosh";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pipewire = {
      url = "git+https://gitlab.freedesktop.org/pipewire/pipewire.git?ref=master";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur-repo = {
      url = github:nix-community/NUR;
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    unsilence-repo = {
      url = "github:Programmerino/unsilence";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    hyprland,
    ...
  } @ args: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    homeConfigurations.davis = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        hyprland.homeManagerModules.default
        ((import ./base-flake.nix).outputs args)
      ];
    };
  };
}
