{ lib, stdenv, stdenvNoCC, fetchurl, autoPatchelfHook }:
let
  distributions = {
    aarch64-darwin = {
      name = "darwin-arm64";
      hash = "sha256-yeHbx0izPtLRT0JEUZHsrxTFYlnHqaJtAELEnsK2ZCg=";
    };
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha256-uEkihMdqVLr1jWFmjdDkHuD8mK2r+VA9MPBdCPVbRAY=";
    };
  };
  distribution = distributions.${stdenv.hostPlatform.system};
in

stdenvNoCC.mkDerivation {
  pname = "nodejs-security";
  version = "22.23.4";

  src = fetchurl {
    url = "https://nodejs.org/dist/v22.23.4/node-v22.23.4-${distribution.name}.tar.gz";
    inherit (distribution) hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  dontBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R bin include lib share "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Official Node.js 22 security release";
    homepage = "https://nodejs.org";
    license = lib.licenses.mit;
    platforms = builtins.attrNames distributions;
    mainProgram = "node";
  };
}
