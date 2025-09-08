{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    noseyparker
    ssh-to-pgp
    gcr
    seahorse
  ];
}
