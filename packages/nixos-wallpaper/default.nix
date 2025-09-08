{
  lib,
  writers,
  python3Packages,
  runCommandLocal,
  imagemagick,
  coreutils,
  route159,
  jura,
  nixos-branding,
  ...
}:
{
  width ? 3840,
  height ? 2160,
  kind ? "logomark", # logomark, logotype
  clearSpace ? "recommended", # none, minimal, recommended
  colorVariant ? "default", # default, rainbow, black, white
  colorGradient ? false,
  background ? "#000000", # wwwowow
  scaling ? 0.8,
}:
let
  script =
    writers.writePython3Bin "mk-custom-logo"
      {
        libraries = [ python3Packages.nixoslogo ];
      }
      ''
        import itertools

        from nixoslogo.core import (
            DEFAULT_LOGOTYPE_SPACINGS,
            DEFAULT_LOGOTYPE_SPACINGS_WITH_BEARING,
            ClearSpace,
            ColorStyle,
            LogoLayout,
            LogomarkColors,
            LogotypeStyle,
        )
        from nixoslogo.logo import NixosLogo
        from nixoslogo.logomark import Logomark
        from nixoslogo.logotype import FontLoader, Logotype

        background_color = "${background}"

        # Logo horizontal layout
        for (
            logomark_colors,
            logomark_color_style,
            logotype_color,
            logotype_style,
            clear_space,
        ) in itertools.product(
            LogomarkColors,
            ColorStyle,
            ("black", "white"),
            LogotypeStyle,
            ClearSpace,
        ):
            logo = NixosLogo(
                background_color=background_color,
                logo_layout=LogoLayout.HORIZONTAL,
                logotype_spacings=DEFAULT_LOGOTYPE_SPACINGS_WITH_BEARING,
                logomark_colors=logomark_colors,
                logomark_color_style=logomark_color_style,
                logotype_color=logotype_color,
                logotype_style=logotype_style,
                clear_space=clear_space,
            )
            logo.write_svg()
            logo.close()

        # Logo vertical layout
        for (
            logomark_colors,
            logomark_color_style,
            logotype_color,
            logotype_style,
            clear_space,
        ) in itertools.product(
            LogomarkColors,
            ColorStyle,
            ("black", "white"),
            LogotypeStyle,
            ClearSpace,
        ):
            logo = NixosLogo(
                background_color=background_color,
                logo_layout=LogoLayout.VERTICAL,
                logotype_spacings=DEFAULT_LOGOTYPE_SPACINGS,
                logomark_colors=logomark_colors,
                logomark_color_style=logomark_color_style,
                logotype_color=logotype_color,
                logotype_style=logotype_style,
                clear_space=clear_space,
            )
            logo.write_svg()
            logo.close()

        # Logomark
        for (
            logomark_colors,
            logomark_color_style,
            clear_space,
        ) in itertools.product(
            LogomarkColors,
            ColorStyle,
            ClearSpace,
        ):
            logo = Logomark(
                background_color=background_color,
                colors=logomark_colors,
                color_style=logomark_color_style,
                clear_space=clear_space,
            )
            logo.write_svg()

        # Logotype
        for (
            logotype_color,
            logotype_style,
            clear_space,
        ) in itertools.product(
            ("black", "white"),
            LogotypeStyle,
            ClearSpace,
        ):
            loader = FontLoader()
            logo = Logotype(
                loader=loader,
                background_color=background_color,
                logotype_spacings=DEFAULT_LOGOTYPE_SPACINGS,
                color=logotype_color,
                style=logotype_style,
                clear_space=clear_space,
            )
            logo.write_svg()
            loader.cleanup()
      '';
  svgPath = "${
    lib.concatStringsSep "-" [
      "nixos"
      kind
      colorVariant
      (if colorGradient then "gradient" else "flat")
      clearSpace
    ]
  }.svg";
in
runCommandLocal "wallpaper-${toString width}-${toString height}.png"
  {
    buildInputs = [
      imagemagick
      coreutils
      script
    ];
    env = {
      NIXOS_LOGOTYPE_FONT_FILE = "${route159}/share/fonts/opentype/route159/Route159-Regular.otf";
      NIXOS_COLOR_PALETTE_FILE = "${nixos-branding.nixos-color-palette}/colors.toml";
      NIXOS_ANNOTATIONS_FONT_FILE = "${jura}/share/fonts/truetype/jura/Jura-Regular.ttf";
    };
  }
  ''
    ${lib.getExe script}
    convert -background "black" -fill "black" -flatten -resize ${
      width * scaling |> builtins.floor |> toString
    }x${height * scaling |> builtins.floor |> toString} -gravity center \
      -extent "${toString width}x${toString height}" ${svgPath} $out
  ''
