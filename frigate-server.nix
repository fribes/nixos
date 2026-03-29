# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib,... }:

let
  ov-xml = pkgs.fetchurl {
    url = "https://huggingface.co/katuni4ka/ssdlite_mobilenet_v2_fp16/resolve/main/ssdlite_mobilenet_v2_fp16.xml";
    hash = "sha256-fj4qmst8eAx1lD2pgnQMNyo3RZ15DScKmGNfOnZjFHo=";
  };

  ov-bin = pkgs.fetchurl {
    url = "https://huggingface.co/katuni4ka/ssdlite_mobilenet_v2_fp16/resolve/main/ssdlite_mobilenet_v2_fp16.bin";
    hash = "sha256-6a5hSZtAEUT2+jvAh4XVW9+7ircGtYyHB1WDDMBGY9M=";
  };

  ov-labels = pkgs.fetchurl {
    url = "https://github.com/openvinotoolkit/open_model_zoo/raw/master/data/dataset_classes/coco_91cl_bkgr.txt";
    hash = "sha256-5Cj2vEiWR8Z9d2xBmVoLZuNRv4UOuxHSGZQWTJorXUQ=";
  };

  ov-model-dir = pkgs.runCommand "frigate-openvino-model" {} ''
    mkdir -p $out
    cp ${ov-xml} $out/ssdlite_mobilenet_v2.xml
    cp ${ov-bin} $out/ssdlite_mobilenet_v2.bin
    cp ${ov-labels} $out/coco_91cl_bkgr.txt
    sed -i 's/truck/car/g' $out/coco_91cl_bkgr.txt
  '';
  rtsp_creds = lib.trim (builtins.readFile /home/fribes/rtsp_creds);
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "i915.enable_guc=3" # Active la soumission GuC et le HuC pour le N100
  ];

  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = -1;
  };

  networking.hostName = "frigate-server"; 
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.fribes = {
    isNormalUser = true;
    description = "Fabien Ribes";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    btop
    ncdu
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 
    80 #  
    443 # https reverse proxy
    22 # ssh
    8080 # frigate 
    8123 # web home assistant
    8555 # go2rtc WebRTC
  ];

  networking.firewall.allowedUDPPorts = [ 
    5353
    1900
    8555  # go2rtc WebRTC (Le flux vidéo passe principalement par UDP)
   ];
  
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime 
    ];
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD"; # Force le pilote Intel Media Driver
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        address = "127.0.0.1"; 
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

# --- Reverse Proxy Caddy ---
  services.caddy = {
    enable = true;
    virtualHosts."fribes.freeboxos.fr".extraConfig = ''
      reverse_proxy 127.0.0.1:8123
    '';
  };

  services.frigate = {
     enable = true;
     hostname = "192.168.1.250";
     settings = {
        detectors.ov = {
          type = "openvino";
          device = "GPU";
        };
        
        model = {
          path = "${ov-model-dir}/ssdlite_mobilenet_v2.xml";
          width = 300;
          height = 300;
          input_tensor = "nhwc";
          input_pixel_format = "bgr";
	  labelmap_path = "${ov-model-dir}/coco_91cl_bkgr.txt";
        };
        
      mqtt = {
	enabled = true;
        host = "127.0.0.1";
        port = 1883;
      };
      ffmpeg = {
        hwaccel_args = [
          "-hwaccel" "vaapi"
          "-hwaccel_device" "/dev/dri/renderD128"
          "-hwaccel_output_format" "yuv420p"
        ];
      };
      record = {
        enabled = true;
        retain = {
          days = 3;
          mode = "motion";
        };
      };

      detect = {
        enabled = true;
        width = 1280;
        height = 720;
      };

      cameras."Boulette" = {
        ffmpeg.inputs = [ {
          path = "rtsp://${rtsp_creds}@192.168.1.201:554/Streaming/Channels/101";
          roles = [
            "record"
          ];
          input_args = [
            "-avoid_negative_ts" "make_zero"
            "-fflags" "+genpts+discardcorrupt"
            "-rtsp_transport" "tcp"
            "-timeout" "5000000"
            "-use_wallclock_as_timestamps" "1"
          ];
        }
        {
          path = "rtsp://${rtsp_creds}@192.168.1.201:554/Streaming/Channels/102";
          roles = [
            "detect"
          ];
          input_args = [
            "-avoid_negative_ts" "make_zero"
            "-fflags" "+genpts+discardcorrupt"
            "-rtsp_transport" "tcp"
            "-timeout" "5000000"
            "-use_wallclock_as_timestamps" "1"
          ];
        }
	];
        motion = {
          mask = [
            "0.19,0.001,0.001,0,0.002,0.996,0.184,0.999"
            "0.455,0.135,0.46,0.284,0.476,0.286,0.488,0.135"
            "0.771,0.313,0.715,0.623,0.857,0.917,0.98,0.563"
          ];
        };
      };
      cameras."Tourette" = {
        ffmpeg.inputs = [ {
          path = "rtsp://${rtsp_creds}@192.168.1.202:554/Streaming/Channels/101";
          roles = [
            "record"
          ];
          input_args = [
            "-avoid_negative_ts" "make_zero"
            "-fflags" "+genpts+discardcorrupt"
            "-rtsp_transport" "tcp"
            "-timeout" "5000000"
            "-use_wallclock_as_timestamps" "1"
          ];
        }
        {
          path = "rtsp://${rtsp_creds}@192.168.1.202:554/Streaming/Channels/102";
          roles = [
            "detect"
          ];
          input_args = [
            "-avoid_negative_ts" "make_zero"
            "-fflags" "+genpts+discardcorrupt"
            "-rtsp_transport" "tcp"
            "-timeout" "5000000"
            "-use_wallclock_as_timestamps" "1"
          ];
        }
	];
        motion = {
          mask = [
            "0,1,0.263,1,0.267,0.364,0.475,0.076,0.555,0.183,0.652,0,0,0"
          ];
        };
      };
    };
  };

  # Overide nginx service packaged with frigate to free port 80 for caddy
  services.nginx = {
    enable = true;
    defaultHTTPListenPort = 8080; # Nginx lâche totalement le port 80
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Paris";
      # Note: The image will not be updated on rebuilds, unless the version label changes
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [ 
        # Use the host network namespace for all sockets
        "--network=host"
        # Pass devices into the container, so Home Assistant can discover and make use of them
        #"--device=/dev/ttyACM0:/dev/ttyACM0"
      ];
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
