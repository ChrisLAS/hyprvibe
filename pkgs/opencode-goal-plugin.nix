{
  buildNpmPackage,
  fetchurl,
  lib,
  nodejs_22,
}: let
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
    patches = [./opencode-goal-plugin-resume-budget.patch];

    postPatch = ''
      # OpenCode 2.0.29 aliases "effect" to its Effect 4 runtime. Keep the
      # plugin's Effect 3 schemas isolated, matching upstream's compatibility fix.
      substituteInPlace dist/server.js --replace-fail 'from "effect"' 'from "effect-goal-state"'
      cp ${./opencode-goal-plugin-package-lock.json} package-lock.json
      ${nodejs_22}/bin/node -e 'const fs = require("fs"); const p = JSON.parse(fs.readFileSync("package.json", "utf8")); delete p.devDependencies; delete p.scripts; delete p.dependencies.effect; p.dependencies["effect-goal-state"] = "npm:effect@3.22.2"; fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");'
    '';

    dontNpmBuild = true;

    doCheck = true;
    checkPhase = ''
      runHook preCheck
      ${nodejs_22}/bin/node --test ${./opencode-goal-plugin.test.mjs}
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      cp -R ./. "$out/"
      cat > "$out/index.ts" <<'EOF'
      export { default } from "./dist/server.js"
      EOF
      cat > "$out/tui.ts" <<'EOF'
      export { default } from "./src/tui.ts"
      EOF
      runHook postInstall
    '';

    meta = {
      description = "OpenCode goal mode server and TUI plugin";
      homepage = "https://github.com/prevalentWare/opencode-goal-plugin";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  }
