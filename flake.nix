{
  description = "Zen Browser";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
    }:
    let
      mkZen =
        name: system: entry:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          variant = (builtins.fromJSON (builtins.readFile ./sources.json)).${entry}.${system};
          desktopFile = if name == "beta" then "zen.desktop" else "zen_${name}.desktop";
          isDarwin = pkgs.stdenv.isDarwin;
        in
        if isDarwin then
          pkgs.stdenv.mkDerivation {
            inherit (variant) version;
            pname = "zen-browser";

            src = builtins.fetchurl {
              inherit (variant) url sha256;
            };

            nativeBuildInputs = with pkgs; [
              undmg
            ];

            sourceRoot = ".";
            phases = ["unpackPhase" "installPhase"];

            unpackPhase = ''
              ${pkgs.undmg}/bin/undmg $src
            '';

            installPhase = ''
              mkdir -p $out/Applications
              cp -r "Zen Browser${if name != "beta" then " " + name else ""}.app" $out/Applications/

              # Create symbolic links to the binary
              mkdir -p $out/bin
              ln -s "$out/Applications/Zen Browser${if name != "beta" then " " + name else ""}.app/Contents/MacOS/zen" $out/bin/zen
              ln -s $out/bin/zen $out/bin/zen-${name}
            '';

            meta = {
              description = "Experience tranquillity while browsing the web without people tracking you!";
              homepage = "https://zen-browser.app";
              downloadPage = "https://zen-browser.app/download/";
              changelog = "https://github.com/zen-browser/desktop/releases";
              platforms = pkgs.lib.platforms.darwin;
              mainProgram = "zen";
            };
          }
        else
          pkgs.callPackage ./package.nix {
            inherit name desktopFile variant;
          };
      mkZenWrapped =
        name: system: entry:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.wrapFirefox entry {
          icon = "zen-${name}";
          wmClass = "zen-${name}";
          hasMozSystemDirPatch = false;
        };
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system: rec {
        beta-unwrapped = mkZen "beta" system "beta";
        twilight-unwrapped = mkZen "twilight" system "twilight";
        twilight-official-unwrapped = mkZen "twilight" system "twilight-official";
        beta = if nixpkgs.legacyPackages.${system}.stdenv.isDarwin then beta-unwrapped else mkZenWrapped "beta" system beta-unwrapped;
        twilight = if nixpkgs.legacyPackages.${system}.stdenv.isDarwin then twilight-unwrapped else mkZenWrapped "twilight" system twilight-unwrapped;
        twilight-official = if nixpkgs.legacyPackages.${system}.stdenv.isDarwin then twilight-official-unwrapped else mkZenWrapped "twilight" system twilight-official-unwrapped;
        default = beta;
      });
      homeModules = rec {
        beta = import ./hm-module.nix {
          inherit self home-manager;
          name = "beta";
        };
        twilight = import ./hm-module.nix {
          inherit self home-manager;
          name = "twilight";
        };
        twilight-official = import ./hm-module.nix {
          inherit self home-manager;
          name = "twilight-official";
        };
        default = beta;
      };
    };
}
