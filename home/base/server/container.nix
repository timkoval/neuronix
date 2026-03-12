{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = with pkgs; [
    skopeo
    docker-compose
    dive # explore docker layers
    lazydocker # Docker terminal UI.

    # kubectl
    # istioctl
    # kubernetes-helm
  ];

  programs = {
    k9s = {
      enable = false;
    };
  };
}
