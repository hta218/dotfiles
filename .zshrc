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


# Upgrade dev environment: node (nvm), biome, opencode, claude code
dev-upgrade() {
  echo "🚀 Upgrading dev environment...\n"

  echo "📦 Upgrading Node via nvm"
  nvm install node --reinstall-packages-from=current --latest-npm && nvm use node && nvm alias default node

  echo "\n🍞 Upgrading bun & pnpm"
  npm i -g bun@latest pnpm@latest

  echo "\n🌿 Upgrading global Biome"
  npm i -g @biomejs/biome@latest

  echo "\n🤖 Upgrading opencode"
  opencode upgrade

  echo "\n🧠 Upgrading Claude Code"
  claude update

  echo "\n🐙 Upgrading GitHub Copilot CLI"
  copilot update

  echo "\n✨ Upgrading Gemini CLI"
  npm i -g @google/gemini-cli@latest

  echo "\n🌱 Upgrading Mintlify"
  npm i -g mint@latest

  echo "\n✅ Versions"
  echo "  📦 node:     $(node -v)"
  echo "  📦 npm:      $(npm -v)"
  echo "  🍞 bun:      $(bun --version)"
  echo "  📦 pnpm:     $(pnpm --version)"
  echo "  🌿 biome:    $(biome --version)"
  echo "  🤖 opencode: $(opencode --version)"
  echo "  🧠 claude:   $(claude --version)"
  echo "  🐙 copilot:  $(copilot --version 2>&1 | head -1)"
  echo "  ✨ gemini:   $(gemini --version)"
  echo "  🌱 mint:     $(mint --version)"
  echo "\n🎉 Done!"
}
alias dup="dev-upgrade"