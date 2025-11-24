# bootstrap.sh
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Nixがインストールされていない場合、クリーンアップしてからインストールを実行
if ! command -v nix >/dev/null 2>&1; then
  echo "Nix not found. Cleaning up previous Nix installations and installing..."
  
  # 冪等性を確保するために既存のNix関連ファイルを削除
  sudo rm -rf /nix
  rm -rf "$HOME/.nix-profile"
  rm -rf "$HOME/.nix-defexpr"
  rm -rf "$HOME/.nix-channels"
  rm -rf "$HOME/.local/state/nix"

  (
    sh <(curl -L https://nixos.org/nix/install) --no-daemon
  )
  echo "Nix installation process finished."
fi

# Nix環境のセットアップを読み込む (インストール後に必須)
if [ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
else
  echo "Error: Nix profile script not found after installation." >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "nix command still unavailable after installation; aborting." >&2
  exit 1
fi

# Nixの設定ファイルを作成し、実験的機能を永続的に有効にする
echo "Configuring Nix to enable experimental features..."
mkdir -p "$HOME/.config/nix"
echo "experimental-features = nix-command flakes" > "$HOME/.config/nix/nix.conf"

# Nixでインストールしたパッケージのパスを明示的に追加
export PATH="$HOME/.nix-profile/bin:$PATH"

# スクリプトのあるディレクトリに移動
cd "$SCRIPT_DIR"

# home-managerを使って環境設定を適用 (ビルド & 適用方式)
echo "Building home-manager activation package..."
nix build ".#homeManagerConfigurations.ubuntu.activationPackage"

echo "Activating home-manager configuration..."
./result/activate

# 一時的なビルド結果を削除
rm ./result

# デフォルトシェルをzshに変更
echo "Changing default shell to zsh..."
# /etc/shellsにzshのパスを追記する必要がある場合がある
ZSH_PATH="$(which zsh)"
if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi
sudo chsh -s "$ZSH_PATH" "$(whoami)" || echo "Warning: Failed to change default shell."

echo "Setup complete. Starting zsh..."
# home-managerで設定されたzshを起動
exec zsh -l