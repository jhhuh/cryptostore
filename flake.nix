{

  description = "Cryptostore flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    mach-nix.url = "github:DavHau/mach-nix";
  };

  outputs = inputs@{ self, nixpkgs, mach-nix }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
      myPython = forAllSystems (system: import mach-nix {
        pkgs = nixpkgsFor."${system}";
        python = "python38";
        pypiDataRev = "59d01c8e38a2508cad129d632e620de7a5b00988";
        pypiDataSha256 = "1gw7nbn5yfbq7h7phhcv88yfpa8878ykgr554ppy397wfxsr6aha";
      });
    in
      {
        inherit inputs;
        overlay = self: super: {};
        apps = forAllSystems (system: {
          cryptostore = myPython."${system}".buildPythonApplication {
              src = ./.;
              extras = ["redis" "zmq"];
            };
        });
        defaultApp = forAllSystems (system: self.apps."${system}".cryptostore);
        devShell = forAllSystems (system:
          let
            pyEnv = myPython."${system}".mkPython {
              requirements = builtins.readFile ./requirements.txt;
            };
          in nixpkgsFor."${system}".mkShell {
            buildInputs = [
              pyEnv
            ];
          });
      };

}
