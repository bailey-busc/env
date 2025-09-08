{
  self,
  config,
  ...
}:
let
  inherit (self.lib.modules) mkStrOpt';
in
{
  options.env = {
    username = mkStrOpt' "bailey";
  };
}
