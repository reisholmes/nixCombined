{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.git.sshSigning;
in {
  options.programs.git.sshSigning = {
    enable = lib.mkEnableOption "SSH signing for git commits";

    allowedSigners = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          email = lib.mkOption {
            type = lib.types.str;
            description = "Email address for the signer";
          };
          key = lib.mkOption {
            type = lib.types.str;
            description = "SSH public key for the signer";
          };
        };
      });
      default = [];
      description = "List of allowed signers with their email and SSH public key";
    };

    sshKeygenProgram = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to ssh-keygen program (null uses system default)";
      example = "/usr/bin/ssh-keygen";
    };

    allowedSignersPath = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/allowed_signers";
      description = "Path to allowed_signers file";
    };

    forceFileUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force update of allowed_signers file on rebuild";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create allowed_signers file for git SSH signing
    home.file.".ssh/allowed_signers" = {
      text = lib.concatMapStringsSep "\n"
        (signer: "${signer.email} ${signer.key}")
        cfg.allowedSigners;
      force = cfg.forceFileUpdate;
    };

    # Git SSH signing configuration
    programs.git.settings = {
      gpg.format = "ssh";
      gpg.ssh = {
        allowedSignersFile = cfg.allowedSignersPath;
      } // lib.optionalAttrs (cfg.sshKeygenProgram != null) {
        program = cfg.sshKeygenProgram;
      };
    };
  };
}
