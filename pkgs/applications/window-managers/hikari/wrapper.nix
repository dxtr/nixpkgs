{ lib, stdenv
, hikari-unwrapped, makeWrapper
, symlinkJoin, writeShellScriptBin
, withBaseWrapper ? true, extraSessionCommands ? "", dbus
, withGtkWrapper ? false, wrapGAppsHook, gdk-pixbuf, glib, gtk3
}:

assert extraSessionCommands != "" -> withBaseWrapper;

with lib;

let
  baseWrapper = writeShellScriptBin "hikari" ''
     set -o errexit
     if [ ! "$_HIKARI_WRAPPER_ALREADY_EXECUTED" ]; then
       ${extraSessionCommands}
       export _HIKARI_WRAPPER_ALREADY_EXECUTED=1
     fi
     if [ "$DBUS_SESSION_BUS_ADDRESS" ]; then
       export DBUS_SESSION_BUS_ADDRESS
       exec "${hikari-unwrapped}/bin/hikari" "$@"
     else
       exec "${dbus}/bin/dbus-run-session" "${hikari-unwrapped}/bin/hikari" "$@"
     fi
  '';
in symlinkJoin {
  name = "hikari-${hikari-unwrapped.version}";
  paths = (optional withBaseWrapper baseWrapper)
          ++ [ hikari-unwrapped ];

  nativeBuildInputs = [ makeWrapper ]
                      ++ (optional withGtkWrapper wrapGAppsHook);

  buildInputs = optionals withGtkWrapper [ gdk-pixbuf glib gtk3 ];

  dontWrapGApps = true;

  postBuild = ''
    ${optionalString withGtkWrapper "gappsWrapperArgsHook"}

    wrapProgram $out/bin/hikari \
      --prefix PATH \
      ${optionalString withGtkWrapper ''"''${gappsWrapperArgs[@]}"''} \
  '';

  passthru.providedSessions = [ "hikari" ];

  inherit (hikari-unwrapped) meta;
}
