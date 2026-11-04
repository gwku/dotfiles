{ lib, buildGoModule, tailscale }:
buildGoModule {
  pname = "tailscale-systray";
  inherit (tailscale) version src vendorHash;
  subPackages = [ "cmd/systray" ];
  env.CGO_ENABLED = 1;
  doCheck = false;
  postInstall = ''
    mkdir -p "$out/Applications/Tailscale Menu.app/Contents/MacOS"
    mv "$out/bin/systray" "$out/Applications/Tailscale Menu.app/Contents/MacOS/tailscale-menu"
    ln -s "$out/Applications/Tailscale Menu.app/Contents/MacOS/tailscale-menu" "$out/bin/tailscale-menu"
    cat > "$out/Applications/Tailscale Menu.app/Contents/Info.plist" <<'PLIST'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
      <key>CFBundleExecutable</key><string>tailscale-menu</string>
      <key>CFBundleIdentifier</key><string>nl.gkloud.tailscale-menu</string>
      <key>CFBundleName</key><string>Tailscale Menu</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleShortVersionString</key><string>${tailscale.version}</string>
      <key>LSUIElement</key><true/>
      <key>NSHighResolutionCapable</key><true/>
    </dict></plist>
    PLIST
  '';
  meta = {
    description = "Official Tailscale systray controller for the existing macOS tailscaled daemon";
    homepage = "https://tailscale.com/docs/features/client/linux-systray";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.darwin;
    mainProgram = "tailscale-menu";
  };
}
