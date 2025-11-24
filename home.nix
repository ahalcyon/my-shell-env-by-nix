# home.nix
{ config, pkgs, ... }:

{
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -alF";
      gs = "git status -sb";
    };
    initExtra = ''
      source ${./zsh_extra.sh}
    '';
  };

  programs.neovim = {
    enable = true;
    # 以下の設定でNeovimの設定を記述できます
    # extraConfig = ''
    #   " Lua or Vimscript configuration goes here
    #   set number
    # '';
    #
    # extraLuaConfig = ''
    #   -- Lua configuration goes here
    #   vim.opt.tabstop = 2
    # '';
    #
    # plugins = with pkgs.vimPlugins; [
    #   dracula-nvim
    #   nvim-treesitter
    # ];
  };

  home.packages = with pkgs; [
    git
    fzf
  ];
}