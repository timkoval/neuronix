{pkgs, ...}: {
  home.packages = with pkgs; [
    niri
    xwayland-satellite # XWayland support for X11 apps (IntelliJ, Android Studio, etc.)
  ];
}
