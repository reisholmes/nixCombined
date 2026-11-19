# What: Host-specific home-manager config for reis-new: aliases, ssh, git signing, GPU, stylix wallpaper.
# Used by: modules/hosts/reis-new.nix puts it in the modules list of homeConfigurations."reis@reis-new".
{
  config,
  pkgs,
  userConfig,
  ...
}: let
  # Prebuilt gaoler binary from the Codeberg release; sha256 from the
  # release `checksums` file (verified 2026-11-18).
  gaoler = pkgs.stdenv.mkDerivation {
    pname = "gaoler";
    version = "0.22.0";
    src = pkgs.fetchurl {
      url = "https://codeberg.org/KarlGW/gaoler/releases/download/v0.22.0/gaoler-0.22.0-linux-amd64.tar.gz";
      sha256 = "b6dd4b96260a9d8048c777d8c50f918af6e4cf2bb23c9f9cc03402df851168de";
    };
    nativeBuildInputs = [pkgs.gnutar pkgs.xz];
    # The tarball has no top-level directory, so skip the standard unpacker.
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      tar -xf $src --exclude '._*'
      mkdir -p $out/bin
      cp gaoler $out/bin/
    '';
  };
in {
  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    # Capture the current generation before switching so a no-op rebuild (same
    # generation path) does not re-diff a stale frozen generation pair.
    nix_rebuild = "old=$(home-manager generations | head -1 | awk '{print $7}'); home-manager switch --flake .#reis@reis-new --impure -b backup && new=$(home-manager generations | head -1 | awk '{print $7}'); if [ \"$old\" = \"$new\" ]; then echo \"No changes (generation unchanged: $new)\"; else nvd diff \"$old\" \"$new\"; fi";

    # Monitor management aliases for KDE Plasma Wayland
    monitor-disable-left = "kscreen-doctor output.DP-1.position.0,0 output.DP-2.disable";
    monitor-enable-left = "kscreen-doctor output.DP-2.enable output.DP-2.position.0,0 output.DP-2.rotation.left output.DP-1.position.1440,786";
    monitor-status = "kscreen-doctor -o";
  };

  # SSH settings per host
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      # Only personal Github
      "github.com" = {
        HostName = "github.com";
        IdentityFile = "~/.ssh/github_reish";
        PreferredAuthentications = "publickey";
        UpdateHostKeys = "yes";
      };

      # Wildcard
      "*" = {
        AddKeysToAgent = "yes";
        IdentitiesOnly = "yes";
        SetEnv = {
          TERM = "xterm-256color";
        };
        UseRoaming = "no";
      };
    };
  };

  # SSH signing configuration for git
  programs.git.sshSigning = {
    enable = true;
    allowedSigners = [
      {
        email = userConfig.email;
        key = userConfig.signingKeyPub;
      }
    ];
  };

  # Git configuration
  programs.git = {
    # Enable SSH signing globally (personal computer - all repos signed)
    signing = {
      key = "${config.home.homeDirectory}/.ssh/private-signing-key-github";
      signByDefault = true;
    };

    # Git settings (new format)
    settings = {
      # Set personal email from userConfig
      user.email = userConfig.email;
    };
  };

  # Packages specific to this machine
  home.packages = with pkgs; [
    lm_sensors
    # gaoler sandbox for pi: rootless podman serves the Docker API, docker (CLI) is for debugging the socket
    docker
    gaoler
    podman
  ];

  # gaoler: point it at the rootless podman Docker API socket and define the pi
  # profile (mounts ~/.pi, passes JAN_API_KEY from the host env). uid is 1000.
  # See llm-notes/gaoler.md for why rootless podman and the endpoint literal.
  home.file."/.gaoler/config.json".text = ''
    {
      "endpoint": "unix:///run/user/1000/podman/podman.sock",
      "image": {
        "template": "{HOME}/.gaoler/image.tmpl"
      },
      "profiles": {
        "pi": {
          "container": {
            "volumes": {
              "{HOME}/.pi": "{HOME}/.pi"
            },
            "env": {
              "JAN_API_KEY": "{env:JAN_API_KEY}"
            }
          },
          "inherit": true
        }
      }
    }
  '';

  # gaoler base image: node 24 + pi only. Built lazily on first `gaoler init`/run.
  home.file."/.gaoler/image.tmpl".text = ''
    FROM node:24-bookworm-slim
    RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
  '';

  # GPU drivers for standalone home-manager on Linux (host-OS /run/opengl-driver)
  targets.genericLinux.gpu.enable = true;

  # Silence Hyprland configType warning while home.stateVersion < "26.05"
  wayland.windowManager.hyprland.configType = "hyprlang";

  # Stable wallpaper path, so KDE's manual wallpaper setting survives repo moves
  xdg.dataFile."wallpapers/hearts.png".source = ../assets/stylix/hearts.png;

  # Stylix settings specific to this machine
  stylix = {
    enable = true;

    # Host-specific wallpaper
    # https://basicappleguy.com/basicappleblog/mountains-beyond-mountains
    hostConfig.wallpaper = ../assets/stylix/hearts.png;

    # Font sizes and base16Scheme inherited from stylix-common.nix module
  };
}
