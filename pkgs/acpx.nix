{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "acpx";
  version = "0.1.15";

  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "acpx";
    rev = "v${version}";
    hash = "sha256-ydUyxFuH5AOYpi0EdRszsHK9VP9OzbzbsNIJjKyvPNw=";
  };

  npmDepsHash = "sha256-mcP8Ei7cUGvkIDWGKnTWOv1I+irZI2Gpy/UMW62sRTA=";

  meta = with lib; {
    description = "Headless CLI client for the Agent Client Protocol";
    homepage = "https://github.com/openclaw/acpx";
    license = licenses.mit;
    mainProgram = "acpx";
  };
}
