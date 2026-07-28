# syntax=docker/dockerfile:1

# AnoNvim in a container.
#
#   docker build -t anonvim .
#   docker run -it --rm anonvim
#
#   # work on a real project inside the container:
#   docker run -it --rm -v "$PWD:/work" -w /work anonvim
#
# Replaces the previous Dockerfile.arch / Dockerfile.ubuntu pair. Two distros
# meant maintaining two dependency lists for an identical result; mise supplies
# the toolchains, so the base distro no longer matters.
#
# Neovim tracks `latest` and Node tracks `lts` by request. Because those float,
# the build asserts the resolved Neovim satisfies this config's >= 0.12 floor
# (native vim.lsp.config, vim.lsp.codelens.enable, Mason 2.0) and fails loudly
# rather than shipping an image that breaks at runtime. Pin NVIM_VERSION to an
# explicit version if you need a reproducible image.

FROM debian:bookworm-slim

# Fail piped commands on the first non-zero exit (e.g. `curl | sh` where curl
# fails), instead of silently succeeding on the last command in the pipe.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Kept in sync with the config's own floors: lua/avim/health.lua requires
# node >= 20.18 and python >= 3.10; the Neovim floor is asserted at build time.
ARG NVIM_VERSION=latest
ARG NODE_VERSION=lts
ARG PYTHON_VERSION=3.12
ARG RUST_VERSION=stable

ENV MISE_DATA_DIR=/root/.local/share/mise \
    MISE_CONFIG_DIR=/root/.config/mise \
    MISE_CACHE_DIR=/root/.cache/mise \
    LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:${PATH}"

# Only what mise cannot provide:
#   - build-essential: plugins compile C on first launch (luasnip's jsregexp,
#     treesitter parsers). Not optional — without it those builds fail.
#   - git: lazy.nvim clones plugins, and the patch system (utilities/patch.lua)
#     shells out to `git apply`.
#   - curl/ca-certificates: bootstrap mise, fetch plugins over HTTPS.
#   - luarocks: not in mise's registry (unlike luajit/tree-sitter), so it comes
#     from apt. Used by plugins that pull Lua rocks via lazy.nvim's rocks support.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      luarocks \
      unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://mise.run | sh

# Toolchains the config's plugin `build` steps need at runtime:
# rust -> ecolog-lsp, node -> mcp-hub + tree-sitter-cli, python -> pynvim/vectorcode.
# luajit matches Neovim's own Lua runtime, for building/testing Lua modules.
# tree-sitter is the CLI used to compile parsers (treesitter.lua's build step).
# ripgrep/fd/fzf back the pickers and are checked by :checkhealth.
RUN mise use -g -y \
      "neovim@${NVIM_VERSION}" \
      "node@${NODE_VERSION}" \
      "python@${PYTHON_VERSION}" \
      "rust@${RUST_VERSION}" \
      luajit \
      tree-sitter \
      ripgrep \
      fd \
      fzf \
    && mise reshim

# Fail the build loudly if the pinned Neovim is below the config's floor, rather
# than shipping an image that breaks at runtime.
RUN nvim --headless -c "lua if vim.fn.has('nvim-0.12') ~= 1 then vim.cmd('cq') end" +qa \
    || { echo "ERROR: Neovim ${NVIM_VERSION} is older than the required 0.12" >&2; exit 1; }

# Ship this checkout rather than curl'ing the installer from GitHub, so the image
# reflects the tree it was built from instead of whatever main happens to be.
COPY . /root/.local/share/anonvim/avim

RUN ln -sf /root/.local/share/anonvim/avim/.install/avim /usr/local/bin/avim && \
    mkdir -p /root/.config/avim /root/.local/state/avim /root/.cache/avim

# Sync plugins at build time so the first interactive launch isn't a long install.
# Tolerant of failure: some plugin builds need network or optional SDKs (dotnet)
# that may be unavailable here, and those should not fail the whole image.
RUN avim --headless "+Lazy! sync" +qa 2>&1 | tail -20 || true

WORKDIR /root

CMD ["avim"]

# vim: ft=dockerfile:
