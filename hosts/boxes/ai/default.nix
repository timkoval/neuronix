{
  config,
  pkgs,
  pkgs-unstable,
  ...
} @ args:
#############################################################
#
#  Ai - my main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
#
#############################################################
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    #  ../../../secrets/nixos.nix
  ];

  nixpkgs.overlays = import ../../../overlays args;

  # Enable binfmt emulation of aarch64-linux, this is required for cross compilation.
  boot.binfmt.emulatedSystems = ["aarch64-linux" "riscv64-linux"];
  # supported fil systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    #"zfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    systemd-boot.enable = true;
  };

  networking = {
    hostName = "ai";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;
  };

  #  virtualisation.docker.storageDriver = "btrfs";

  # for Nvidia GPU
  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  hardware.nvidia = {
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is needed for most Wayland compositors
    modesetting.enable = true;
    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    open = false;

    powerManagement.enable = true;
  };
  # Use docker_29 (docker 28.x is unmaintained; overlay makes pkgs.docker point to docker_29)
  hardware.nvidia-container-toolkit.enable = true; # for nvidia-docker

  hardware.graphics = {
    enable = true;
    # needed by nvidia-docker
    enable32Bit = true;
  };

  # Make NVIDIA driver libraries discoverable by PyTorch, vLLM, etc.
  environment.sessionVariables.LD_LIBRARY_PATH = args.lib.mkBefore ["/run/opengl-driver/lib"];

  # Hermes Agent (LLM agent from Nous Research) — container mode
  # Local Ollama integration: points to host's ollama via Docker bridge IP
  services.hermes-agent = {
    enable = true;
    settings = {
      model = {
        default = "35b-64k:latest";
        provider = "custom";
        base_url = "http://172.17.0.1:11434/v1";
      };
      display.final_response_markdown = "render";
      display.streaming = false;
    };
    extraDependencyGroups = ["messaging"];

    # Non-secret env vars (ollama API endpoint)
    environment = {
      OPENAI_BASE_URL = "http://172.17.0.1:11434/v1";
      OPENAI_API_KEY = "dummy";
    };
    # Secret env vars (via age)
    environmentFiles = [
      config.age.secrets."hermes-env".path
    ];

    container = {
      enable = true;
      backend = "docker";
      hostUsers = ["tkoval"];
      # Mount personal projects into the container.
      # Safety: all projects are in git; unwanted changes can be reviewed and reverted.
      extraVolumes = [
        "/home/tkoval/git-local:/git-local:rw"
        "/home/tkoval/.opencode:/home/hermes/.opencode:rw"
        "/home/tkoval/.config/opencode:/home/hermes/.config/opencode:rw"
        "/home/tkoval/.local/share/opencode:/home/hermes/.local/share/opencode:rw"
        "/home/tkoval/.cache/opencode:/home/hermes/.cache/opencode:rw"
        "/home/tkoval/.local/state/opencode:/home/hermes/.local/state/opencode:rw"
      ];
    };
    workingDirectory = "/git-local";
  };

  # Hermes Web UI — standalone dashboard (runs outside the container)
  systemd.services.hermes-webui = {
    description = "Hermes Web UI";
    after = ["hermes-agent.service"];
    wants = ["hermes-agent.service"];
    path = [pkgs.python3 pkgs.nodejs pkgs.coreutils pkgs.bash pkgs.git pkgs.openssh config.services.hermes-agent.package];
    serviceConfig = {
      Type = "exec";
      User = "tkoval";
      WorkingDirectory = "/home/tkoval/git-local/hermes-webui";
      ExecStart = "/home/tkoval/git-local/hermes-webui/start.sh";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = ["multi-user.target"];
  };

  # Provide /bin/bash for tools that hardcode it (bootstrap.py, etc.)
  services.envfs.enable = true;

  # Ollama — local LLM server with NVIDIA CUDA acceleration
  # Using official GitHub release (includes llama-server in lib/ollama/)
  services.ollama = {
    enable = true;
    package = pkgs.stdenv.mkDerivation {
      pname = "ollama";
      version = "0.30.3";

      src = pkgs.fetchurl {
        url = "https://github.com/ollama/ollama/releases/download/v0.30.3/ollama-linux-amd64.tar.zst";
        sha256 = "sha256-6Dd8aq9yfUWQe4R8PnprzeDTRVSxWM4jJ7AI38NOHI8=";
      };

      nativeBuildInputs = [pkgs.zstd pkgs.makeWrapper];

      sourceRoot = ".";

      installPhase = ''
        mkdir -p $out/bin $out/lib
        cp -r bin/ollama $out/bin/ollama
        cp -r lib/ollama $out/lib/ollama
        chmod +x $out/bin/ollama
        chmod +x $out/lib/ollama/llama-server

        # Wrap ollama with LD_LIBRARY_PATH so it can find libcuda.so on NixOS
        wrapProgram $out/bin/ollama \
          --suffix LD_LIBRARY_PATH : "/run/opengl-driver/lib"
      '';

      meta = {
        description = "Get up and running with large language models locally";
        homepage = "https://github.com/ollama/ollama";
        license = pkgs.lib.licenses.mit;
        platforms = ["x86_64-linux"];
        mainProgram = "ollama";
      };
    };
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
  };

  boot.kernelModules = ["88x2bu"];
  boot.extraModulePackages = [
    (config.boot.kernelPackages.rtl88x2bu.overrideAttrs (old: {
      prePatch =
        old.prePatch
        + ''
          substituteInPlace Makefile --replace "CONFIG_CONCURRENT_MODE = n" "CONFIG_CONCURRENT_MODE = y"
        '';
    }))
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
