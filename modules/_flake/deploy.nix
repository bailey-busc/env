{ inputs, ... }:
{
  flake.deploy = {
    nodes = builtins.mapAttrs (_: c: rec {
      # sshUser = if c.config.users.users ? deploy then c.config.users.users.deploy.name else c.config.env.username;
      # interactiveSudo = sshUser == "root";
      sshUser = c.config.env.username;
      interactiveSudo = true;
      hostname = c.config.networking.hostName;
      profiles.system = {
        # user = if c.config.users.users ? deploy then c.config.users.users.deploy.name else "root";
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos c;
      };
    }) inputs.self.nixosConfigurations;
  };
}
