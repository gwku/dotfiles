{
  buildNpmPackage,
  lib,
  stdenv,
  python3,
  makeWrapper,
  nodejs_22,
}:

buildNpmPackage {
  nodejs = nodejs_22;
  pname = "dotfiles-node-tools";
  version = "1.0.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./package.json ./package-lock.json ];
  };

  npmDepsHash = "sha256-VZp7XNaoR8pXAlcb3gr5OHAqFr+mhbQe48eaYvM13Bs=";
  dontNpmBuild = true;

  # The pinned Darwin Bash crashes in the upstream FIFO-based classifier.
  # Keep temporary-path validation with the independent checker below.
  noAuditTmpdir = stdenv.hostPlatform.isDarwin;
  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    ${python3}/bin/python3 ${./audit-temporary-paths.py} "$out" "$TMPDIR"
  '';

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules" "$out/bin"
    cp -R node_modules/. "$out/lib/node_modules/"

    makeWrapper ${nodejs_22}/bin/node "$out/bin/shopify" \
      --add-flags "$out/lib/node_modules/@shopify/cli/bin/run.js"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/lighthouse" \
      --add-flags "$out/lib/node_modules/lighthouse/cli/index.js"

    runHook postInstall
  '';

  meta.mainProgram = "shopify";
}
