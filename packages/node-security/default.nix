{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "nodejs-security";
  version = "22.23.4";

  src = fetchurl {
    url = "https://nodejs.org/dist/v22.23.4/node-v22.23.4-darwin-arm64.tar.gz";
    hash = "sha256-yeHbx0izPtLRT0JEUZHsrxTFYlnHqaJtAELEnsK2ZCg=";
  };

  dontBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R bin include lib share "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Official Node.js 22 security release for Apple Silicon";
    homepage = "https://nodejs.org";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "node";
  };
}
