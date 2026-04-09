/*
  modules/home/programs/zsh.nix

  part of der-home-server
  created 2026-04-07
*/

{
  userConfig,
  hostname,
  ...
}:
{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -la";
      gs = "git status";

      us = "sync-flake && sudo nixos-rebuild switch --upgrade-all --impure";
      uh = "sync-flake && home-manager switch --flake /etc/nixos#${userConfig.name}@${hostname}";

      sw-nix = "sudo nixos-rebuild switch --upgrade-all --impure";
      sw-nix-offline = "sudo nixos-rebuild switch --upgrade-all --impure --option substitute false";
      sw-home = "home-manager switch --flake /etc/nixos#${userConfig.name}@${hostname}";

      nus = "sync-flake && nh os switch /etc/nixos";
      nuus = "sync-flake && nh os switch /etc/nixos --update";
      nuh = "sync-flake && nh home switch /etc/nixos";
      nuuh = "sync-flake && nh home switch /etc/nixos --update";

      cns = "sudo sh -c 'nix-env -p /nix/var/nix/profiles/system --delete-generations old && nix-collect-garbage -d && nix-store --optimise --verify'";
      cnh = "nix-env --delete-generations old && nix profile wipe-history && home-manager expire-generations \"-0 seconds\" && nix-collect-garbage -d";

      nd = "cd /etc/nixos";

      gtop = "sudo intel_gpu_top";

      help = "bash -c 'help'";

      c = "clear";
    };

    initContent = ''
      bindkey -e
      export EDITOR=nvim

      # enable colors
      autoload -U colors && colors

      # set prompt style
      PROMPT='%F{green}%n%F{yellow}@%m%f:%~$ '
    '';

    history.size = 16384;
  };
}
