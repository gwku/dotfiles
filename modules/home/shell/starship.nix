{ ... }: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      add_newline = true;

      format = "$directory$git_branch$git_status$nodejs$python$rust$dotnet$kubernetes$cmd_duration$line_break$character";

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol   = "[✗](bold red)";
      };

      directory = {
        truncation_length = 4;
        truncate_to_repo  = true;
      };

      git_branch.symbol = " ";
      git_status.disabled = false;

      kubernetes = {
        disabled = false;
        format = "[$symbol$context( \\($namespace\\))]($style) ";
      };

      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
      };
    };
  };
}
