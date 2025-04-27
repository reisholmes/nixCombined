{
  # I essentially copied this from someone much smarter than me:
  # https://github.com/AlexNabokikh/nix-config
  # All I wanted was a simple, easy enough to follow examples, of managing
  # two machines (linux mint and mac, in my case) with home manager and
  # shared app configs between them. Alex's config matches what I required.
  # If you don't follow what I'm doing then go read his repo.
  description = "Nix and nix-darwin configs for my machines";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Global catppuccin theme
    catppuccin.url = "github:catppuccin/nix";

    # Nix Darwin (for MacOS machines)
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    catppuccin,
    darwin,
    home-manager,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;

    # Define user configurations
    users = {
      reis.holmes = {
        fullName = "Reis Holmes";
        name = "reis.holmes";
      };
      reis = {
        fullName = "Reis Holmes";
        name = "reis";
      };
    };

    # Function for NixOS system configuration
    mkNixosConfiguration = hostname: username:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs hostname;
          userConfig = users.${username};
          nixosModules = "${self}/modules/nixos";
        };
        modules = [./hosts/${hostname}];
      };

    # Function for nix-darwin system configuration
    mkDarwinConfiguration = hostname: username:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs hostname;
          userConfig = users.${username};
        };
        modules = [
          ./hosts/${hostname}
          home-manager.darwinModules.home-manager
        ];
      };

    # Function for Home Manager configuration
    mkHomeConfiguration = system: username: hostname:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {inherit system;};
        extraSpecialArgs = {
          inherit inputs outputs;
          userConfig = users.${username};
          nhModules = "${self}/modules/home-manager";
        };
        modules = [
          ./home/${username}/${hostname}
          catppuccin.homeModules.catppuccin
        ];
      };
  in {
    nixosConfigurations = {
      # leaving in as an example
      #  energy = mkNixosConfiguration "energy" "nabokikh";
    };

    darwinConfigurations = {
      "reis-work" = mkDarwinConfiguration "reis-work" "reis.holmes";
    };

    homeConfigurations = {
      "reis.holmes@reis-work" = mkHomeConfiguration "x86_64-linux" "reis.holmes" "reis-work";
      "reis@rh-sb3" = mkHomeConfiguration "x86_64-linux" "reis" "rh-sb3";
    };

    overlays = import ./overlays {inherit inputs;};
  };
}
