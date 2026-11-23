# What: Host-specific home-manager config for reis-new: aliases, ssh, git signing, GPU, stylix wallpaper.
# Used by: modules/hosts/reis-new.nix puts it in the modules list of homeConfigurations."reis@reis-new".
{
  config,
  pkgs,
  userConfig,
  ...
}: let
  # Gaoler v0.22.0 from the Codeberg source, with the build-progress panic
  # fixed (patches/gaoler-0.22.0-build-progress-clamp.patch; stock panics on
  # podman 6's stepless build stream). Reported upstream; drop the patch when
  # a fixed release lands.
  gaoler = pkgs.buildGoModule rec {
    pname = "gaoler";
    version = "0.22.0";
    src = pkgs.fetchurl {
      url = "https://codeberg.org/KarlGW/gaoler/archive/v0.22.0.tar.gz";
      sha256 = "0d66442b625393508a4efa840459a0f4a2451ce297bd2d815f8e0c664697f4c7";
    };
    patches = [../../patches/gaoler-0.22.0-build-progress-clamp.patch];
    subpackages = ["./cmd/gaoler"];
    doCheck = false;
    vendorHash = "sha256-kJc4CrQblmXoksBMuCNMyGtdpPEtaJdMOv+v/bNKlx8=";
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

  # Launch pi in a gaoler container on the current directory. Starts the
  # transient rootless podman API socket if it is missing (see
  # llm-notes/gaoler.md for the socket lifetime pitfall).
  programs.zsh.siteFunctions.pis = ''
    pis() {
      local sock="$XDG_RUNTIME_DIR/podman/podman.sock"
      if [ ! -S "$sock" ]; then
        mkdir -p "$(dirname "$sock")"
        systemd-run --user --unit podman-api \
          podman system service --time=0 "unix://$sock"
      fi
      gaoler run --profile pi --user 0 pi "$@"
    }
  '';

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
              "{HOME}/.pi": "{HOME}/.pi",
              "{HOME}/.pi/agent/models.json": "{HOME}/.pi/agent/models.json",
              "{HOME}/.pi/agent/settings.json": "{HOME}/.pi/agent/settings.json"
            },
            "env": {
              "HOME": "/home/reis",
              "JAN_API_KEY": "{env:JAN_API_KEY}"
            },
            "networks": [
              "host"
            ]
          },
          "inherit": true
        }
      }
    }
  '';

  # The nix podman package ships no containers config files, so pulls fail with
  # "config file not found". Podman 6's new image engine only accepts the new
  # requirement types (reject, insecureAcceptAnything, signedBy, ...), so the
  # old stock policy cannot be used. Accept unverified images, same default as
  # Docker Desktop. See llm-notes/gaoler.md.
  home.file."/.config/containers/policy.json".text = ''
    {
      "default": [
        { "type": "insecureAcceptAnything" }
      ]
    }
  '';

  # gaoler base image template: node 24 + pi + a user matching the host user.
  # Built by `gaoler init`. The user is required: gaoler runs containers as the
  # host username and podman resolves it against the container /etc/passwd.
  home.file."/.gaoler/image.tmpl".text = ''
    FROM docker.io/library/node:24-bookworm-slim
    # node:slim already has user/group `node` at 1000; userdel removes both.
    RUN userdel node && groupadd -g 1000 reis && useradd -m -u 1000 -g 1000 reis
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
