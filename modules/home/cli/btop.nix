{ ... }:
{
  programs.btop = {
    enable = true;

    # The rest of the current btop configuration matches upstream defaults.
    settings.cpu_bottom = true;
  };
}
