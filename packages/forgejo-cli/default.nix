{ lib, stdenv, stdenvNoCC, fetchurl, autoPatchelfHook, openssl, zlib }:

# Official release fallback until the pinned nixpkgs supplies fj >= 0.6.
stdenvNoCC.mkDerivation {
  pname = "forgejo-cli";
  version = "0.7.0";

  src = fetchurl {
    url = "https://codeberg.org/forgejo-contrib/forgejo-cli/releases/download/v0.7.0/forgejo-cli-x86_64-linux.tar.gz";
    hash = "sha256-aAPBLu0Xv620C6ldoqarWPm0p9wQ6r/jUS/Ofi/mIW8=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ openssl zlib stdenv.cc.cc.lib ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 fj "$out/bin/fj"
    runHook postInstall
  '';

  meta = {
    description = "Official Forgejo CLI release compatible with T3 Code";
    homepage = "https://codeberg.org/forgejo-contrib/forgejo-cli";
    license = with lib.licenses; [ asl20 mit ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "fj";
  };
}
