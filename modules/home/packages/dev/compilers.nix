{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    sqlite
    python3
    python3Packages.marimo
    python3Packages.pytest
    uv
    cargo
    rustc
    rustfmt
    clippy
    typst
    inputs.calepin.packages.${pkgs.stdenv.hostPlatform.system}.calepin
  ];
}
