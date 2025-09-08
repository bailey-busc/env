{ self, ... }:
let
  inherit (builtins) fromJSON readFile;
  secretsDir = "${self}/data/secrets";
in
{
  # Load Tailscale IP addresses from JSON file
  ips = readFile ../data/tailscale_ips.json |> fromJSON;

  # SSH public keys for users and hosts
  keys = {
    # User keys
    users.bailey = {
      azalea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDFB3nTqngD4HurehT9DS4L8qvzGYQV3bXjckiiU8x2";
      iphone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAi25soXTrvsB9SACcInvOcnpeJ7z4PTZafSkFXPq2d8";
      iris = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPobOKBpE/Ebdr31ig5+zxZegSxEAavjuY2QSawvPZk1";
      orchid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOT3XJhB17JOn0yY2T/Obabd1KlvvHKhw2xbKu2bC4s";
      oleander = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiBCYLwatpDTl1Qf0x/IbUU6+U3SNsekESGho4s91Gi bailey@glimp.se";
      yubikey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZNO8bZrbOm6dH3QgDl8c5cKQvOSQ8Nz3lAPMHDiBGY openpgp:0x3916F0A7";
    };
    # Host keys
    hosts = {
      azalea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTSoq5EVWWo++793cr36ntd86THkpvse57FqEHVlnEE";
      iris = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhDw/oeFarqTDvrY89VZPbn0Fy1mUammzFG9glOQHlJ";
      ivy-greentown = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDBid3WL1fhnnIST1772VOp5LBrZGLpflhXDzIcGGWkv";
      ivy-lucid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7UvW57loO1RTjUDmZBxgRfd1Bw9ilBOaB8mys0Eros";
      orchid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1ov0Hf2rkC0cGIPyY2a3rRssExOwJCH/lPiMiqSK5I";
    };
    signing = {
      azalea = readFile "${self}/data/keys/signing/azalea.pub";
      iris = readFile "${self}/data/keys/signing/iris.pub";
      orchid = readFile "${self}/data/keys/signing/orchid.pub";
    };
  };
  secretsSubdirPath = subdir: name: "${secretsDir}/${subdir}/${name}.age";
  secretsSubdirPubPath = subdir: name: "${secretsDir}/${subdir}/${name}.pub";
  secretsPath = name: "${secretsDir}/${name}.age";
  secretsPubPath = name: "${secretsDir}/${name}.pub";
}
