{
  buildNpmPackage,
  makeWrapper,
  nodejs_22,
}:

buildNpmPackage {
  pname = "dotfiles-node-tools";
  version = "1.0.0";
  src = ./.;

  npmDepsHash = "sha256-VZp7XNaoR8pXAlcb3gr5OHAqFr+mhbQe48eaYvM13Bs=";
  dontNpmBuild = true;

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
