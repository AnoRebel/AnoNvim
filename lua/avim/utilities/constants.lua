---@class avim.utilities.constants
---@field nonfile_bufs table
---@field mode_color table
---@field mode_colors table
---@field modes table
local M = {}

-- these are filetypes that are not actual files, but rather meta buffers
-- created by plugins or by neovim itself
M.nonfile_bufs = {
  "NvimTree",
  "Outline",
  "TelescopePrompt",
  "Trouble",
  "aerial",
  "alpha",
  "dashboard",
  "help",
  "NvimTree",
  "neo-tree",
  "neo-tree-popup",
  "neogitstatus",
  "notify",
  "lazy",
  "packer",
  "spectre_panel",
  "startify",
  "toggleterm",
  "noice",
  "vim",
}

M.mode_color = {
  n = "green",
  i = "red",
  v = "cyan",
  V = "cyan",
  [""] = "cyan",
  -- ["\22"] =  "cyan",
  c = "magenta",
  no = "purple",
  s = "orange",
  S = "orange",
  [""] = "orange",
  -- ["\19"] =  "purple",
  ic = "yellow",
  R = "violet",
  Rv = "violet",
  cv = "red",
  ce = "red",
  r = "blue",
  rm = "blue",
  ["r?"] = "blue",
  ["!"] = "red",
  t = "red",
}
M.mode_colors = {
  ["n"] = "#00FF00", --"green",
  ["i"] = "#FF0000", -- "red",
  ["v"] = "#00FFFF", -- "cyan",
  ["V"] = "#00FFFF", -- "cyan",
  [""] = "#00FFFF", -- "cyan",
  -- ["\22"] =  "#00FFFF",-- "cyan",
  ["c"] = "#FF00FF", --"magenta",
  ["no"] = "#800080", --"purple",
  ["s"] = "#FFC300", -- "orange",
  ["S"] = "#FFC300", -- "orange",
  [""] = "#FFC300", --"orange",
  -- ["\19"] =  "#800080",--"purple",
  ["ic"] = "#FFFF00", --"yellow",
  ["R"] = "#EE82EE", --"violet",
  ["Rv"] = "#EE82EE", --"violet",
  ["cv"] = "#FF0000", --"red",
  ["ce"] = "#FF0000", --"red",
  ["r"] = "#008080", --"blue",
  ["rm"] = "#008080", --"blue",
  ["r?"] = "#008080", --"blue",
  ["!"] = "#FF0000", --"red",
  ["t"] = "#FF0000", --"red",
}

M.modes = {
  ["n"] = "NORMAL",
  ["no"] = "  OP  ",
  ["nov"] = "  OP  ",
  ["noV"] = "  OP  ",
  ["no"] = "  OP  ",
  ["niI"] = "NORMAL",
  ["niR"] = "NORMAL",
  ["niV"] = "NORMAL",
  ["v"] = "VISUAL",
  ["V"] = "LINES ",
  [""] = "BLOCK ",
  ["s"] = "SELECT",
  ["S"] = "SELECT",
  [""] = "BLOCK ",
  ["i"] = "INSERT",
  ["ic"] = "INSERT",
  ["ix"] = "INSERT",
  ["R"] = "REPLACE",
  ["Rc"] = "REPLACE",
  ["Rv"] = "V-REPLACE",
  ["Rx"] = "REPLACE",
  ["c"] = "COMMAND",
  ["cv"] = "COMMAND",
  ["ce"] = "COMMAND",
  ["r"] = "ENTER ",
  ["rm"] = " MORE ",
  ["r?"] = "CONFIRM",
  ["!"] = "SHELL ",
  ["t"] = " TERM ",
  ["nt"] = " TERM ",
  ["null"] = " NONE ",
}

return M
