{ runCommand, fetchurl, unzip }:
let
  archive = fetchurl {
    url = "https://github.com/espanso/hub/releases/latest/download/all-emojis-0.1.0.zip";
    sha256 = "53be2281b59a237ecdcae1d2f92f1ecc57ffbbb8ac49a996561c9e495d6ef092";
  };
in
runCommand "espanso-all-emojis-0.1.0" { nativeBuildInputs = [ unzip ]; } ''
  mkdir -p "$out"
  unzip -q ${archive} -d "$out"
  printf 'hub\n' > "$out/_pkgsource.yml"
''
