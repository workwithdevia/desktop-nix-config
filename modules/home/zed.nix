{
  pkgs,
  lib,
  ...
}: {
  programs.zed-editor = {
    enable = true;

    extensions = [
      "nix"
      "toml"
      "elixir"
      "make"
    ];

    userSettings = {
      # ============================================================
      # AI
      # ============================================================
      assistant = {
        enabled = true;
        version = "2";
        default_open_ai_model = null;

        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };
      };

      # ============================================================
      # NODE
      # ============================================================
      node = {
        path = lib.getExe pkgs.nodejs;
        npm_path = lib.getExe' pkgs.nodejs "npm";
      };

      # ============================================================
      # GENERAL
      # ============================================================
      hour_format = "hour24";
      auto_update = false;

      # Muy importante para una experiencia tipo Neovim
      hide_mouse = "on_typing_and_action";

      # Cursor estable, sin parpadeo
      cursor_blink = false;

      # No mostrar scrollbar
      scrollbar = {
        show = "never";
        axes = {
          horizontal = false;
          vertical = false;
        };
      };

      # Navegación más tipo Vim
      relative_line_numbers = "enabled";

      # No permitir scroll infinito debajo del buffer
      scroll_beyond_last_line = "off";

      # Mantener el cursor cerca del centro
      vertical_scroll_margin = 8;

      # No envolver líneas automáticamente
      soft_wrap = "none";

      # Sin rulers
      show_wrap_guides = false;

      # No mostrar espacios excepto cuando sean necesarios
      show_whitespaces = "selection";

      # ============================================================
      # EDITOR / GUTTER
      # ============================================================
      gutter = {
        line_numbers = true;

        # Oculta botones que normalmente no necesitas en modo Vim
        runnables = false;
        breakpoints = true;
        folds = true;

        # Similar a Neovim con una columna razonablemente estable
        min_line_number_digits = 3;
      };

      # Guías de indentación
      indent_guides = {
        enabled = true;
        coloring = "indent_aware";
        background_coloring = "disabled";
      };

      # No mostrar scopes pegados arriba
      sticky_scroll = {
        enabled = false;
      };

      # ============================================================
      # TERMINAL
      # ============================================================
      terminal = {
        alternate_scroll = "off";
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";

        detect_venv = {
          on = {
            directories = [
              ".env"
              "env"
              ".venv"
              "venv"
            ];

            activate_script = "default";
          };
        };

        env = {
          TERM = "wezterm";
        };

        font_family = "FiraCode Nerd Font";
        font_features = null;
        font_size = null;

        line_height = "comfortable";

        option_as_meta = false;

        button = false;

        shell = "system";

        toolbar = {
          title = false;
        };

        working_directory = "current_project_directory";
      };

      # ============================================================
      # LSP
      # ============================================================
      lsp = {
        rust-analyzer.binary.path_lookup = true;
        nix.binary.path_lookup = true;

        elixir-ls = {
          binary.path_lookup = true;

          settings = {
            dialyzerEnabled = true;
          };
        };
      };

      # ============================================================
      # LANGUAGES
      # ============================================================
      languages = {
        "Elixir" = {
          language_servers = [
            "!lexical"
            "elixir-ls"
            "!next-ls"
          ];

          format_on_save.external = {
            command = "mix";

            arguments = [
              "format"
              "--stdin-filename"
              "{buffer_path}"
              "-"
            ];
          };
        };

        "HEEX" = {
          language_servers = [
            "!lexical"
            "elixir-ls"
            "!next-ls"
          ];

          format_on_save.external = {
            command = "mix";

            arguments = [
              "format"
              "--stdin-filename"
              "{buffer_path}"
              "-"
            ];
          };
        };
      };

      # ============================================================
      # VIM
      # ============================================================
      vim_mode = true;

      vim = {
        # Arrancar siempre en NORMAL
        default_mode = "normal";

        # Clipboard del sistema como en Neovim
        use_system_clipboard = "always";

        # Buscar con smartcase
        use_smartcase_find = true;

        # Regex para /
        use_regex_search = true;

        # :s/foo/bar reemplaza todas las coincidencias
        gdefault = true;

        # Números relativos en NORMAL y absolutos en INSERT
        toggle_relative_line_numbers = true;

        # Feedback rápido después de yank
        highlight_on_yank_duration = 100;
      };

      # ============================================================
      # KEYMAP
      # ============================================================
      # Puedes cambiar esto a "None" si quieres construir todo desde
      # Vim/Zed keybindings, pero VSCode conserva algunos atajos útiles.
      base_keymap = "VSCode";

      # ============================================================
      # DIRenv
      # ============================================================
      load_direnv = "shell_hook";

      # ============================================================
      # THEME
      # ============================================================
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };

      # ============================================================
      # FONTS
      # ============================================================
      ui_font_size = 16;
      buffer_font_size = 16;
    };
  };
}
