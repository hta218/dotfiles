# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="sobole" # set by `omz`

plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# opencode
export PATH=$HOME/.opencode/bin:$PATH
alias oc='opencode'


# Upgrade dev environment: npm globals, opencode, claude code, brew CLIs
# Note: Node itself is NOT upgraded here — do that manually with `nvm install node`
dev-upgrade() {
  _has() { command -v "$1" >/dev/null 2>&1 }
  _ver() { _has "$1" && "$@" 2>&1 | head -1 || echo "not installed" }

  echo "🚀 Upgrading dev environment...\n"

  echo "📦 Upgrading npm globals (bun, pnpm, biome, gemini)"
  npm i -g bun@latest pnpm@latest @biomejs/biome@latest @google/gemini-cli@latest

  # mint is installed on its own: it pulls puppeteer, whose postinstall is
  # flaky, and a failure there would abort the whole npm command above
  echo "\n🌱 Upgrading Mintlify"
  npm i -g mint@latest || echo "⚠️  mint upgrade failed — skipped"

  _has opencode && { echo "\n🤖 Upgrading opencode"; opencode upgrade; }
  _has claude   && { echo "\n🧠 Upgrading Claude Code"; claude update; }

  # copilot self-updates in place (the brew cask `copilot-cli` lags behind,
  # so `brew upgrade --cask copilot-cli` would roll it back)
  _has copilot && { echo "\n🐙 Upgrading GitHub Copilot CLI"; copilot update; }

  echo "\n🐱 Upgrading GitHub CLI"
  brew upgrade gh

  echo "\n✅ Versions"
  echo "  📦 node:     $(_ver node -v)"
  echo "  📦 npm:      $(_ver npm -v)"
  echo "  🍞 bun:      $(_ver bun --version)"
  echo "  📦 pnpm:     $(_ver pnpm --version)"
  echo "  🌿 biome:    $(_ver biome --version)"
  echo "  🤖 opencode: $(_ver opencode --version)"
  echo "  🧠 claude:   $(_ver claude --version)"
  echo "  🐙 copilot:  $(_ver copilot --version)"
  echo "  ✨ gemini:   $(_ver gemini --version)"
  echo "  🌱 mint:     $(_ver mint --version)"
  echo "  🐱 gh:       $(_ver gh --version)"
  echo "\n🎉 Done!"

  unset -f _has _ver
}
alias dup="dev-upgrade"