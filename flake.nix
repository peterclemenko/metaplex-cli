

{
  description = "DevShell flake for ghost-datatype-support-lib using nixpkgs/nixos-unstable";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
      # Allow unfree packages when evaluating the devshell (needed for codeql)
      pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
      in {
        devShells = {
          default = pkgs.mkShell {
            name = "ghost-datatype-support-lib-dev";

            # Include the requested packages from nixpkgs (nixos-unstable)
            buildInputs = with pkgs; [ act fnm nodejs pnpm git docker sqlite pnpm coreutils nushell mise dependabot-cli codeql just ];

            # Common developer environment variables and helpful message
            shellHook = ''
              echo "Entering devshell for ghost-datatype-support-lib (${system})"
              just run
              echo "Available: act=$(command -v act >/dev/null && echo yes || echo no), fnm=$(command -v fnm >/dev/null && echo yes || echo no)"
            '';
          };
        };
      });
}


