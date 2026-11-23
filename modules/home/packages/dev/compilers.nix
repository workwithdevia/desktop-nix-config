{
  inputs,
  pkgs,
  ...
}: let
  python315 = pkgs.python315.override {
    packageOverrides = pyFinal: pyPrev: {
      parso = pyPrev.parso.overridePythonAttrs (old: {
        src = inputs.parso-py315;

        meta =
          (old.meta or {})
          // {
            changelog = "https://github.com/davidhalter/parso/commit/512e78c1a8f4968086af652394a9cd0a91c16e54";
          };
      });
      marimo = pyPrev.marimo.overridePythonAttrs (old: {
        version = "0.25.2";

        src = pkgs.fetchPypi {
          pname = "marimo";
          version = "0.25.2";
          hash = "sha256-PPo4rITGZiXh98t9yBpB69WSJEAA/+N+/7KKkXZQVrA=";
        };

        # Python 3.15 no utiliza Loro.
        dependencies =
          builtins.filter
          (dep: (dep.pname or null) != "loro")
          old.dependencies;

        meta =
          old.meta
          // {
            changelog = "https://github.com/marimo-team/marimo/releases/tag/0.25.2";
          };
      });
      valkey = pyPrev.valkey.overridePythonAttrs (old: {
        nativeCheckInputs =
          builtins.filter
          (pkg: (pkg.pname or "") != "libvalkey")
          (old.nativeCheckInputs or []);
      });
      exceptiongroup = pyPrev.exceptiongroup.overridePythonAttrs (old: {
        disabledTests =
          (old.disabledTests or [])
          ++ [
            "test_nameerror_suggestions_in_group"
          ];
      });
      jiter = pyPrev.jiter.overridePythonAttrs (old: {
        version = "0.18.0";

        src = inputs.jiter;

        # Utilizar el Cargo.lock de la nueva versión.
        postPatch = "";

        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = "${inputs.jiter}/Cargo.lock";
        };
      });
      "pure-eval" = pyPrev."pure-eval".overridePythonAttrs (old: {
        version = "0.2.4";

        src = pkgs.fetchPypi {
          pname = "pure_eval";
          version = "0.2.4";
          hash = "sha256-JgwndGhuZRt5+Ljn/J2As1mepqZjNLR9X0q7afwsDqE=";
        };
      });
      toolz = pyPrev.toolz.overridePythonAttrs (old: rec {
        version = "1.2.0";

        src = pkgs.fetchPypi {
          pname = "toolz";
          inherit version;
          hash = "sha256-lmegOOnW7Lo3mV4myy9Z7GQgtq2N2Wd95Z25uVawhJA=";
        };
      });
      tkinter = pyPrev.tkinter.overridePythonAttrs (old: {
        # CPython 3.15.0: los tests de tkinter asumen regrtest. Mismo workaround
        # que nixpkgs aplica a 3.13 y 3.14.
        preCheck =
          (old.preCheck or "")
          + ''
            substituteInPlace \
              test/test_tcl.py \
              test/test_ttk/__init__.py \
              test/test_tkinter/__init__.py \
              test/test_tkinter/support.py \
                --replace-fail "support.get_resource_value('wantobjects')" "1"
          '';
      });
    };
  };
in {
  home.packages = with pkgs; [
    /*
      (python315.withPackages (ps: [
      ps.marimo
      ps.pytest
    ]))
    */
    (python314.withPackages (ps: [
      ps.marimo
      ps.pytest
    ]))
    sqlite
    uv
    cargo
    rustc
    rustfmt
    clippy
    typst
  ];
}
