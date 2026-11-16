# Homebrew's `dotnet-sdk` cask moved to .NET 11 in November 2026, and homebrew-cask
# has no `dotnet-sdk@10` yet. This mirrors upstream's `dotnet-sdk@9` so .NET 10
# installs into the same /usr/local/share/dotnet root. Drop it from the tap once
# homebrew-cask ships its own `dotnet-sdk@10`.
cask "dotnet-sdk@10" do
  arch arm: "arm64", intel: "x64"

  version "10.0.404"
  sha256 arm:   "2e0637ae0448bd8e3615cf31e0ad2a6dcb3fa0d3a78873f98fb1d25b39e858d6",
         intel: "7265f4960b6ff57c8f9df6061eac3fab0518d27b87562d946d50005efe0407bb"

  url "https://builds.dotnet.microsoft.com/dotnet/Sdk/#{version}/dotnet-sdk-#{version}-osx-#{arch}.pkg"
  name ".NET SDK 10"
  desc "Developer platform"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    url "https://builds.dotnet.microsoft.com/dotnet/release-metadata/#{version.major_minor}/releases.json"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :json do |json, regex|
      json["releases"]&.map do |release|
        version = release.dig("sdk", "version")
        next unless version&.match(regex)

        version
      end
    end
  end

  depends_on cask: "dotnet-sdk"
  depends_on macos: :monterey

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.*#{version.major_minor}*#{arch}"

  # No zap stanza: the SDK keeps no per-user state, and nix-homebrew pins a
  # Homebrew that predates upstream's `zap :not_required`.
end
