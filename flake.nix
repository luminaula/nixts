{
  description = "Node project with TypeScript and Docker";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    nodejs = pkgs.nodejs;
    node2nixOutput = import ./nix { inherit pkgs nodejs; };
    nodeDeps = node2nixOutput.nodeDependencies;
  in {

    packages.x86_64-linux = rec {
      proj = pkgs.stdenv.mkDerivation {
        pname = "typeshit";
        name = "typeshit";
        src = ./.;
        buildInputs = with pkgs; [
          pkgs.nodejs
          pkgs.nodePackages.typescript
        ];

        buildPhase = ''
          runHook preBuild
          ln -sf ${nodeDeps}/lib/node_modules ./node_modules
          export PATH="${nodeDeps}/bin:$PATH"
          npm run build
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r dist $out
          cp -r node_modules $out
          cp -r package.json $out
          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Node + TypeScript Express Docker container via Nix DockerTools";
          license = licenses.mit;
          maintainers = [ "Lumi" ];
        };
      };
      dockerImage = pkgs.dockerTools.buildImage {
        name = "typeshit-image";
        tag = "latest";

        copyToRoot = with pkgs; [
          proj
          nodejs
          bash
        ];

        config = {
          Env = [];
          Cmd = [ "${pkgs.nodejs}/bin/npm" "run" "start" ];
        };
      };
    default = dockerImage;
    };
  };
}
