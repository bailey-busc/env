{
  lib,
  ...
}:
rec {
  # Convert a Nix value to an XML string
  toXML =
    value:
    if builtins.isAttrs value then
      let
        # Handle attributes with special @ prefix for attributes
        attrs = lib.filterAttrs (n: _: lib.hasPrefix "@" n) value;
        children = lib.filterAttrs (n: _: !(lib.hasPrefix "@" n)) value;

        # Convert attributes to string
        attrsStr = lib.concatStrings (
          lib.mapAttrsToList (n: v: " ${lib.removePrefix "@" n}=\"${toString v}\"") attrs
        );

        # Convert children to string
        childrenStr = lib.concatStrings (
          lib.mapAttrsToList (n: v: if n == "#text" then toString v else "<${n}${toXML v}</${n}>") children
        );
      in
      attrsStr + (if childrenStr == "" then "/>" else ">${childrenStr}")
    else
      toString value;

  # Generate an XML document with optional declaration
  mkXML =
    {
      declaration ? "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      root,
    }:
    if declaration != null then
      declaration + "\n" + "<${root.name}${toXML root.value}"
    else
      "<${root.name}${toXML root.value}";

  # Helper to create a root element
  mkRoot = name: value: {
    inherit name value;
  };

  # Helper to create text content
  text = content: {
    "#text" = content;
  };

  # Helper to create an empty element
  empty = { };
}
