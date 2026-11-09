# What: Declares the `users` flake option holding identity data: emails and public signing keys.
# Used by: Host modules read config.users.<name>.
{lib, ...}: {
  options.users = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = {};
    description = "Per-user identity data: emails and public signing keys.";
  };

  config.users = {
    "reis.holmes" = {
      fullName = "Reis Holmes";
      name = "reis.holmes";
      workEmail = "reis.holmes@optimizely.com";
      signingKeyPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNBSXWl4vHikJV3SOXxLdHq005sD3a/QIsvRfXGY3R2 4367558+reisholmes@users.noreply.github.com";
      workSigningKeyPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKouJmVbhP+ojiWpSH4RDiVg/DQb0uHrVxFWztKEQ3u3 work-signing-key";
    };
    reis = {
      fullName = "Reis Holmes";
      name = "reis";
      email = "4367558+reisholmes@users.noreply.github.com";
      signingKeyPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNBSXWl4vHikJV3SOXxLdHq005sD3a/QIsvRfXGY3R2 4367558+reisholmes@users.noreply.github.com";
    };
  };
}
