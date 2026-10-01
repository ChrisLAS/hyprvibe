{
  buildNpmPackage,
  fetchurl,
  lib,
  nodejs_22,
}:
let
  source = builtins.fromJSON (builtins.readFile ./opencode-goal-plugin-source.json);
  tarball = fetchurl {
    inherit (source) url hash;
  };
in
buildNpmPackage {
  pname = "opencode-goal-plugin";
  inherit (source) version;

  src = tarball;
  nodejs = nodejs_22;
  npmDepsHash = source.npmDepsHash;
  npmInstallFlags = ["--ignore-scripts"];

  postPatch = ''
    cp ${./opencode-goal-plugin-package-lock.json} package-lock.json
    node -e 'const fs = require("fs"); const p = JSON.parse(fs.readFileSync("package.json", "utf8")); delete p.devDependencies; delete p.scripts; fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");'
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    cp -R ./. "$out/"
    runHook postInstall
  '';

  meta = {
    description = "OpenCode goal mode server and TUI plugin";
    homepage = "https://github.com/prevalentWare/opencode-goal-plugin";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
