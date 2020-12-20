{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.hikari;

  wrapperOptions = types.submodule {
    options =
      let
        mkWrapperFeature = default: description: mkOption {
          type = types.bool;
          inherit default;
          example = !default;
          description = "Whether to make use of the ${description}";
        };
      in {
        base = mkWrapperFeature true ''
          base wrapper to execute extra session commands and prepend a
          dbus-run-session to the hikari command.
        '';
        gtk = mkWrapperFeature false ''
          wrapGAppsHook wrapper to execute hikari with required environment
          variables for GTK applications.
        '';
      };
  };

  hikariPackage = pkgs.hikari.override {
    extraSessionCommands = cfg.extraSessionCommands;
    withBaseWrapper = cfg.wrapperFeatures.base;
    withGtkWrapper = cfg.wrapperFeatures.gtk;
  };
in {
  options.programs.hikari = {
    enable = mkEnableOption ''
      hikari [ja. Light] is a stacking Wayland compositor which is actively
      developed on FreeBSD but also supports Linux.
    '';

    wrapperFeatures = mkOption {
      type = wrapperOptions;
      default = { };
      example = { gtk = true; };
      description = ''
        Attribute set of features to enable in the wrapper.
      '';
    };

    extraSessionCommands = mkOption {
      type = types.lines;
      default = "";
      example = ''
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      description = ''
        Shell commands executed just before hikari is started.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = with pkgs; [ xwayland ];
      defaultText = literalExample ''
        with pkgs; [ xwayland ];
      '';
      example = literalExample ''
        with pkgs; [ xwayland alacritty dmenu ];
      '';
      description = ''
        Extra packages to be installed system wide.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.extraSessionCommands != "" -> cfg.wrapperFeatures.base;
        message = ''
          The extraSessionCommands for hikari will not be run if
          wrapperFeatures.base is disabled.
        '';
      }
    ];

    environment = {
      systemPackages = [ hikariPackage ] ++ cfg.extraPackages;
    };
    security.pam.services.hikari-unlocker = {
      text = "auth include login";
    };
    security.wrappers.hikari-unlocker.source = "${pkgs.hikari.out}/bin/hikari-unlocker";
    hardware.opengl.enable = mkDefault true;
    fonts.enableDefaultFonts = mkDefault true;
    programs.dconf.enable = mkDefault true;
    services.xserver.displayManager.sessionPackages = [ hikariPackage ];
  };

  meta.maintainers = with lib.maintainers; [ wjlroe ];
}
