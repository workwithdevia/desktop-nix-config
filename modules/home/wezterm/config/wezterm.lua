local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Configuración de inicio para clases específicas
wezterm.on('gui-startup', function(cmd)
  local mux = wezterm.mux
  local args = {}
  if cmd then
    args = cmd.args
  end

  -- Detectar si estamos lanzando btop-float
  local is_btop = false
  for _, arg in ipairs(args) do
    if arg == 'btop-float' then
      is_btop = true
    end
  end

  if is_btop then
    local _, _, window = mux.spawn_window(cmd or {domain = 'DefaultDomain'})
    window:gui_window():maximize() -- <--- Aquí está el truco
  end
end)

-- --- CONFIGURACIÓN GENERAL Y ESTILO ---

local tabline = wezterm.plugin.require(
  "https://github.com/michaelbrusegard/tabline.wez"
)

tabline.setup({
  options = {
    theme = 'nord',
    icons_enabled = true,
    tabs_enabled = true,
  },
  sections = {
    tabline_a = {  },
    tabline_b = {  },
    tab_active = {
      'process',
    },
    tab_inactive = {
      { 'process', padding = 1 },
    },
    tabline_x = {  },
    tabline_y = {  },
    tabline_z = { 'domain' },
  }
})

config.tab_bar_at_bottom = false

-- 🔥 ESTA LÍNEA ES OBLIGATORIA
tabline.apply_to_config(config)

config.color_scheme = 'nord'

-- Ventana: Opacidad y padding interno
config.window_background_opacity = 0.85
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.window_decorations = "NONE"
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.enable_tab_bar = false
config.enable_scroll_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 50

-- Historial de scroll (100,000 líneas)
config.scrollback_lines = 100000

-- Cursor: Estilo barra (Beam) y parpadeo continuo
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- --- FUENTES ---
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' })
config.font_size = 11.5

-- Habilitar ligaduras de texto
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }


-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                            NEOVIM OPTIMIZATIONS                              │
-- └──────────────────────────────────────────────────────────────────────────────┘

-- Terminal & Colors
-- WSL doesn't have wezterm terminfo, so we use xterm-256color there
-- See: https://github.com/Gentleman-Programming/Gentleman.Dots/issues/117
if wezterm.target_triple:find("windows") then
  config.term = "xterm-256color"
else
  config.term = "wezterm"
end
config.enable_csi_u_key_encoding = true

-- Undercurl support (LSP diagnostics, spelling)
config.underline_thickness = 2
config.underline_position = -2

-- Scrollback
config.scrollback_lines = 10000

-- Performance
config.max_fps = 240

-- Image support
config.enable_kitty_graphics = true

-- Input handling
config.use_dead_keys = false
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false


-- --- KEYBINDINGS (Atajos de teclado) ---
config.keys = {
  -- EL SPLIT: Ctrl+Alt+Enter envía la secuencia de escape F6 para Tmux
  {
    key = 'Enter',
    mods = 'CTRL|ALT',
    action = wezterm.action.SendString '\u{001b}[17~',
  },

  -- F1: Copiar al portapapeles
  {
    key = 'F1',
    action = wezterm.action.CopyTo 'Clipboard',
  },

  -- F2: Pegar desde el portapapeles
  {
    key = 'F2',
    action = wezterm.action.PasteFrom 'Clipboard',
  },

  -- Ctrl+Shift+C: Copiar
  {
    key = 'C',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'Clipboard',
  },

  -- Ctrl+Shift+V: Pegar
  {
    key = 'V',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },

  -- Ctrl+Shift+Enter: Abrir nueva ventana
  {
    key = 'Enter',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnCommandInNewWindow {
      cwd = wezterm.cwd,
    },
  },
}

return config
