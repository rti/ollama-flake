{
  description =
    "ollama: Get up and running with Llama 2, Mistral, and other large language models locally";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unfree, ... }:
    let
      inherit (nixpkgs) lib;

      forAllSystems = systems: function:
        lib.genAttrs systems (system:
          function
            nixpkgs.legacyPackages.${system}
            nixpkgs-unfree.legacyPackages.${system});

      buildOllama = pkgs: overrides: pkgs.callPackage ./build-ollama.nix overrides;

      unixPackages = (forAllSystems lib.platforms.unix (pkgs: _: {
        default = buildOllama pkgs { buildGoModule = pkgs.buildGo122Module; };
      }));

      linuxPackages = (forAllSystems lib.platforms.linux (pkgs: pkgsUnfree: {
        default = buildOllama pkgsUnfree { buildGoModule = pkgs.buildGo122Module; enableRocm = true; enableCuda = true; };
        gpu = buildOllama pkgsUnfree { buildGoModule = pkgs.buildGo122Module; enableRocm = true; enableCuda = true; };
        rocm = buildOllama pkgs { buildGoModule = pkgs.buildGo122Module; enableRocm = true; };
        cuda = buildOllama pkgsUnfree { buildGoModule = pkgs.buildGo122Module; enableCuda = true; };
        cpu = buildOllama pkgs { buildGoModule = pkgs.buildGo122Module; };
      }));
    in
    {
      packages = unixPackages // linuxPackages;
    };
}
