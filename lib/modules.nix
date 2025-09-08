# Ripped from: https://github.com/jakehamilton/config/blob/d39934d0be295f16046fb3cf40cf7d314f4c58de/lib/module/default.nix
{ inputs, ... }:
let
  inherit (inputs) self;
  inherit (inputs.lib.lib)
    mapAttrs
    mkEnableOption
    mkOption
    types
    ;
in
rec {
  ## Create a NixOS module option.
  ##
  ## ```nix
  ## lib.mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  ## Create a NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkOpt' nixpkgs.lib.types.str "My default"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt' = type: default: mkOpt type default null;

  ## Create a boolean NixOS module option.
  ##
  ## ```nix
  ## lib.mkBoolOpt true "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkBoolOpt = mkOpt types.bool;

  ## Create a boolean NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkBoolOpt true
  ## ```
  ##
  #@ Type -> Any -> String
  mkBoolOpt' = mkOpt' types.bool;

  ## Create a string NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkStrOpt' "yes"
  ## ```
  ##
  #@ Type -> Any -> String
  mkStrOpt' = mkOpt' types.str;

  ## Create a int NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkIntOpt' 1
  ## ```
  ##
  #@ Type -> Any -> String
  mkIntOpt' = mkOpt' types.int;

  ## Create a int NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkFloatOpt' 1.5
  ## ```
  ##
  #@ Type -> Any -> String
  mkNumberOpt' = mkOpt' types.number;

  mkEnabledOpt' =
    name: default:
    (
      (mkEnableOption name)
      // {
        inherit default;
      }
    );

  mkEnabledOpt = name: mkEnabledOpt' name true;

  enabled = {
    ## Quickly enable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ true
    enable = true;
  };

  disabled = {
    ## Quickly disable an option.
    ##
    ## ```nix
    ## services.nginx = disabled;
    ## ```
    ##
    #@ false
    enable = false;
  };

  filterMkIf =
    value:
    if (self.lib.hasAttrs [ "type" "condition" "content" ] value) then
      (if (value.type == "mkIf") then (if value.condition then (value.content) else ({ })) else value)
    else
      value;

  filterMkIfFromList = map filterMkIf;

  # Filter out mkIf, mkMerge, etc and then convert to json
  filterMkIfFromAttrs = mapAttrs (_: filterMkIf);
}
