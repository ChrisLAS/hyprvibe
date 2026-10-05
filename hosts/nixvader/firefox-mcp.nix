{
  config,
  lib,
  pkgs,
  ...
}:
let
  firefoxMcpStart = pkgs.writeShellApplication {
    name = "nixvader-firefox-mcp-start";
    runtimeInputs = [
      pkgs.netcat-openbsd
      pkgs.procps
    ];
    text = ''
      if nc -z -w 1 127.0.0.1 2828 && nc -z -w 1 127.0.0.1 9223; then
        echo "Nixvader Firefox is already available for MCP." >&2
        exit 0
      fi
      if pgrep -u "$(id -u)" -f '(^|/)(firefox|\.firefox-wrapped)( |$)' >/dev/null; then
        echo "Quit Firefox on Nixvader, then run nixvader-firefox-mcp-start to reopen your existing profile with MCP enabled." >&2
        exit 1
      fi
      exec ${lib.getExe config.programs.firefox.finalPackage} --marionette --remote-debugging-port=9223 "$@"
    '';
  };
  firefoxMcp = pkgs.writeShellApplication {
    name = "nixvader-firefox-mcp";
    runtimeInputs = [
      pkgs.netcat-openbsd
      pkgs.util-linux
    ];
    text = ''
      if ! nc -z -w 1 127.0.0.1 2828 || ! nc -z -w 1 127.0.0.1 9223; then
        echo "firefox-nixvader: Nixvader is online, but Firefox MCP is unavailable. In its graphical session, quit Firefox and run nixvader-firefox-mcp-start (or use Firefox — Nixvader MCP)." >&2
        exit 1
      fi
      # Marionette supports one controlling WebDriver session at a time.
      state_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      exec 9>"$state_dir/nixvader-firefox-mcp.lock"
      if ! flock -n 9; then
        echo "firefox-nixvader: another MCP connection is already controlling Firefox on Nixvader." >&2
        exit 1
      fi
      exec ${lib.getExe pkgs.firefox-devtools-mcp} --connect-existing --marionette-port 2828 --enable-script
    '';
  };
in
{
  environment.systemPackages = [
    firefoxMcpStart
    firefoxMcp
    (pkgs.makeDesktopItem {
      name = "nixvader-firefox-mcp";
      desktopName = "Firefox — Nixvader MCP";
      comment = "Open your existing Firefox profile for remote OpenCode control from Nomad";
      exec = "${lib.getExe firefoxMcpStart} %U";
      icon = "firefox";
      categories = [
        "Network"
        "WebBrowser"
      ];
      terminal = false;
    })
  ];
  # Firefox's default Marionette and Remote Agent listeners are loopback-only.
  # Transport MCP stdio over authenticated SSH; no browser ports are opened.
}
