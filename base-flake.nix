{
  nixConfig.extra-substituters = [
    "https://programmerino.cachix.org"
    "https://hyprland.cachix.org"
  ];

  nixConfig.extra-trusted-public-keys = [
    "programmerino.cachix.org-1:v8UWI2QVhEnoU71CDRNS/K1CcW3yzrQxJc604UiijjA="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pipewire = {
      url = "git+https://gitlab.freedesktop.org/pipewire/pipewire.git?ref=master";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-repo = {
      url = github:nix-community/NUR;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    unsilence-repo = {
      url = "github:Programmerino/unsilence";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nur-repo,
    pipewire,
    unsilence-repo,
    hyprland,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.firefox.enablePlasmaBrowserIntegration = true;
      config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) ["vscode-extension-ms-vscode-cpptools" "microsoft-edge-dev" "gfx-wrap-nvidia-libs" "intel-ocl" "ripcord" "obsidian"];
    };

    dehash = pkgs.lib.strings.removePrefix "#";
    nur = import nur-repo {
      inherit pkgs;
      nurpkgs = pkgs;
    };

    blackBg = pkgs.writeShellApplication {
      name = "blackBg";
      text = ''
        swaybg --color "#000000"
      '';
    };

    unsilence = pkgs.python3Packages.buildPythonApplication {
      pname = "unsilence";
      version = "1.0.8";
      src = unsilence-repo;
      propagatedBuildInputs = with pkgs.python3Packages; [
        rich
        setuptools
      ];
      buildInputs = with pkgs; [ffmpeg];
      doCheck = false;
    };
  in rec {
    home.stateVersion = "22.05";

    home.username = builtins.getEnv "USER";
    home.homeDirectory = builtins.toPath (builtins.getEnv "HOME");

    home.activation = {
      mpv-config = ''
        ln -sf ~/.config/mpv/mpv.conf ~/.var/app/io.mpv.Mpv/config/mpv/mpv.conf
      '';
      orchis-theme = ''
        if [ ! -f ~/.themes/Orchis-oled/index.theme ]
        then
          cd ~/Downloads
          git clone https://github.com/depau/Orchis-theme-OLED.git
          cd Orchis-theme-OLED
          ./install.sh -c dark -t all
        fi
      '';
      pywalfox = ''
        pip install pywalfox
        python3 -m pywalfox install
      '';
      hushlogin = ''
        touch ~/.hushlogin
      '';
    };

    programs.home-manager.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = null;
      extraConfig = ''
        exec-once=systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        exec-once=${blackBg}/bin/blackBg
        exec-once=/usr/bin/lxqt-policykit-agent
        exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        #exec-once=sudo ${pkgs.ananicy}/bin/ananicy start
        exec-once=dunst
        exec-once=${pkgs.batsignal}/bin/batsignal
        exec-once=swayidle -w timeout 60 'systemctl suspend'
        exec-once=foot -s
        exec-once=wlsunset -t 0 -l 40.0150 -L -105.2705
        exec=oled-protection

        monitor=,highrr,auto,1

        input {
            follow_mouse=1
        }

        general {
            #main_mod=ALT
            gaps_in=5
            gaps_out=20
            border_size=3
            col.active_border=0xff1a1a1a
            col.inactive_border=0xff0d0d0d
        }

        decoration {
            #multisample_edges = 0
            blur = 0
            drop_shadow = 0
            rounding=10
            #inactive_opacity=0.9
            #blur=1
            #blur_size=10 # minimum 1
            #blur_passes=3 # minimum 1
            blur_new_optimizations=1
            blur_ignore_opacity=1
            # dim_inactive=1
            # dim_strength=0.9
        }

        animations {
            enabled=1
            # animation=windows,1,7,default
            # animation=border,1,10,default
            # animation=fade,1,10,default
            # animation=workspaces,1,6,default
        }

        dwindle {
            pseudotile=0 # enable pseudotiling on dwindle
        }

        gestures {
           workspace_swipe=1
        }

        blurls=launcher

        misc {
            disable_hyprland_logo=1
            disable_splash_rendering=1
            animate_manual_resizes=1
        }

        # example window rules
        # for windows named/classed as abc and xyz
        #windowrule=move 69 420,abc
        #windowrule=size 420 69,abc
        #windowrule=tile,xyz
        #windowrule=float,abc
        #windowrule=pseudo,abc
        #windowrule=monitor 0,xyz

        # example binds
        bind=ALT,return,exec,footclient
        bind=ALTSHIFT,Q,killactive,
        bind=ALTSHIFT,E,exit,
        bind=ALT,D,exec,fuzzel --no-icons --terminal footclient --horizontal-pad=1920 --vertical-pad=1080 --font=monospace:pixelsize=18 --border-width=0 --border-radius=0 --match-color=5E0000ff --background-color=000000AA --selection-color=000000AA --text-color=FF9869ff --selection-text-color=FF8054ff --selection-match-color=D30000ff
        bind=SUPER,V,togglefloating,

        bind=ALT,V,togglefloating,
        bind=ALT,P,pin,
        bind=SUPER,P,pin,
        bind=ALT,left,movefocus,l
        bind=ALT,right,movefocus,r
        bind=ALT,up,movefocus,u
        bind=ALT,down,movefocus,d
        bindm=ALT,mouse:273,resizewindow
        bindm=ALT,mouse:272,movewindow
        bind=,Print,exec,amixer set Capture cap
        bindr=,Print,exec,amixer set Capture nocap

        bind=ALT,1,workspace,1
        bind=ALT,2,workspace,2
        bind=ALT,3,workspace,3
        bind=ALT,4,workspace,4
        bind=ALT,5,workspace,5
        bind=ALT,6,workspace,6
        bind=ALT,7,workspace,7
        bind=ALT,8,workspace,8
        bind=ALT,9,workspace,9
        bind=ALT,0,workspace,10

        bind=ALTSHIFT,1,movetoworkspace,1
        bind=ALTSHIFT,2,movetoworkspace,2
        bind=ALTSHIFT,3,movetoworkspace,3
        bind=ALTSHIFT,4,movetoworkspace,4
        bind=ALTSHIFT,5,movetoworkspace,5
        bind=ALTSHIFT,6,movetoworkspace,6
        bind=ALTSHIFT,7,movetoworkspace,7
        bind=ALTSHIFT,8,movetoworkspace,8
        bind=ALTSHIFT,9,movetoworkspace,9
        bind=ALTSHIFT,0,movetoworkspace,10

        bind=ALT,mouse_down,workspace,e+1
        bind=ALT,mouse_up,workspace,e-1

        bind=,F10,exec,grim -g "$(slurp -d)" - | wl-copy
        bind=SHIFT,F10,exec,FILE="$HOME/Pictures/sc_$(date +"%F_%I_%M_%S").png"; ${pkgs.wl-clipboard}/bin/wl-copy "$FILE"; grim -g "$(slurp -d)" "$FILE"
        bindle=,XF86AudioRaiseVolume,exec,inc_volume
        bindle=,XF86AudioLowerVolume,exec,dec_volume
        bindle=,KP_Multiply,exec,inc_volume
        bindle=,KP_Prior,exec,dec_volume
        bindle=,KP_Up,exec,inc_volume
        bindle=,KP_Down,exec,dec_volume
        bind=,XF86AudioMute,exec,amixer set Master toggle
        bind=,XF86AudioNext,exec,${pkgs.playerctl}/bin/playerctl next
        bind=,XF86Forward,exec,${pkgs.playerctl}/bin/playerctl next
        bind=,KP_Right,exec,${pkgs.playerctl}/bin/playerctl next
        bind=,XF86AudioPrev,exec,${pkgs.playerctl}/bin/playerctl previous
        bind=,KP_Left,exec,${pkgs.playerctl}/bin/playerctl previous
        bind=,XF86Back,exec,${pkgs.playerctl}/bin/playerctl previous
        bind=,XF86AudioPause,exec,${pkgs.playerctl}/bin/playerctl play-pause
        bind=,XF86AudioPlay,exec,${pkgs.playerctl}/bin/playerctl play-pause
        bind=,KP_Next,exec,${pkgs.playerctl}/bin/playerctl play-pause
        bind=,KP_Begin,exec,${pkgs.playerctl}/bin/playerctl play-pause
        bindle=,XF86MonBrightnessDown,exec,sudo ${pkgs.light}/bin/light -U 5%
        bindle=,XF86MonBrightnessUp,exec,sudo ${pkgs.light}/bin/light -A 5%
      '';
    };

    manual.manpages.enable = false;
    nix = {
      package = pkgs.nixUnstable;
      registry = {
        nixpkgs = {
          exact = true;
          flake = nixpkgs;
        };
      };
      settings = {
        trusted-users = ["davis"];
        max-jobs = 8;
      };
      extraOptions = ''
        builders-use-substitutes = true
        experimental-features = nix-command flakes
        accept-flake-config = true
        auto-optimise-store = true
        keep-going = true
      '';
    };

    programs.nix-index = {
      enable = true;
    };

    programs.foot = {
      enable = true;
      package = pkgs.hello;
      settings = {
        main = {
          font = "monospace:size=14";
        };
        cursor = {
          color = "111111 cccccc";
        };
        colors = {
          foreground = "dddddd";
          background = "000000";
          regular0 = "000000";
          regular1 = "cc0403";
          regular2 = "19cb00";
          regular3 = "cecb00";
          regular4 = "0d73cc";
          regular5 = "cb1ed1";
          regular6 = "0dcdcd";
          regular7 = "dddddd";
          bright0 = "767676";
          bright1 = "f2201f";
          bright2 = "23fd00";
          bright3 = "fffd00";
          bright4 = "1a8fff";
          bright5 = "fd28ff";
          bright6 = "14ffff";
          bright7 = "ffffff";
        };
      };
    };

    programs.pidgin = {
      enable = true;
      plugins = with pkgs; [
        purple-discord
      ];
    };

    programs.aria2 = {
      enable = true;
      settings = {
        split = 16;
        file-allocation = "falloc";
        bt-save-metadata = true;
        bt-prioritize-piece = "head,tail";
        bt-max-open-files = 999999;
        bt-max-peers = 999999;
        bt-load-saved-metadata = true;
        bt-enable-lpd = true;
        http-accept-gzip = true;
        uri-selector = "adaptive";
        continue = true;
        max-concurrent-downloads = 16;
        check-integrity = true;
        max-connection-per-server = 16;
        min-split-size = 1048576;
        enable-dht = true;
        optimize-concurrent-downloads = true;
        daemon = true;
        enable-rpc = true;
        rpc-listen-all = true;
        rpc-secret = "a";
        enable-dht6 = true;
        bt-tracker = "udp://tracker.opentrackr.org:1337/announce,http://tracker.opentrackr.org:1337/announce,udp://9.rarbg.com:2810/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker.dler.org:6969/announce,udp://p4p.arenabg.com:1337/announce,udp://opentracker.i2p.rocks:6969/announce,udp://open.stealth.si:80/announce,udp://open.demonii.com:1337/announce,udp://ipv4.tracker.harry.lu:80/announce,udp://explodie.org:6969/announce,udp://exodus.desync.com:6969/announce,https://tracker.nanoha.org:443/announce,https://tracker.lilithraws.org:443/announce,https://tr.burnabyhighstar.com:443/announce,https://opentracker.i2p.rocks:443/announce,http://tracker.dler.org:6969/announce,udp://zecircle.xyz:6969/announce,udp://www.peckservers.com:9000/announce,udp://wepzone.net:6969/announce,udp://vibe.sleepyinternetfun.xyz:1738/announce,udp://v2.iperson.xyz:6969/announce,udp://v1046920.hosted-by-vdsina.ru:6969/announce,udp://uploads.gamecoast.net:6969/announce,udp://trackerb.jonaslsa.com:6969/announce,udp://tracker2.dler.org:80/announce,udp://tracker1.myporn.club:9337/announce,udp://tracker1.bt.moack.co.kr:80/announce,udp://tracker.theoks.net:6969/announce,udp://tracker.tcp.exchange:6969/announce,udp://tracker.srv00.com:6969/announce,udp://tracker.skyts.net:6969/announce,udp://tracker.skynetcloud.site:6969/announce,udp://tracker.qu.ax:6969/announce,udp://tracker.publictracker.xyz:6969/announce,udp://tracker.pimpmyworld.to:6969/announce,udp://tracker.openbtba.com:6969/announce,udp://tracker.monitorit4.me:6969/announce,udp://tracker.moeking.me:6969/announce,udp://tracker.leech.ie:1337/announce,udp://tracker.joybomb.tw:6969/announce,udp://tracker.jonaslsa.com:6969/announce,udp://tracker.ddunlimited.net:6969/announce,udp://tracker.bitsearch.to:1337/announce,udp://tracker.auctor.tv:6969/announce,udp://tracker.artixlinux.org:6969/announce,udp://tracker.altrosky.nl:6969/announce,udp://tracker.4.babico.name.tr:3131/announce,udp://tracker-udp.gbitt.info:80/announce,udp://tr.cili001.com:8070/announce,udp://tr.bangumi.moe:6969/announce,udp://torrents.artixlinux.org:6969/announce,udp://thouvenin.cloud:6969/announce,udp://themaninashed.com:6969/announce,udp://thagoat.rocks:6969/announce,udp://tamas3.ynh.fr:6969/announce,udp://slicie.icon256.com:8000/announce,udp://sanincode.com:6969/announce,udp://run.publictracker.xyz:6969/announce,udp://run-2.publictracker.xyz:6969/announce,udp://rep-art.ynh.fr:6969/announce,udp://qtstm32fan.ru:6969/announce,udp://public.tracker.vraphim.com:6969/announce,udp://public.publictracker.xyz:6969/announce,udp://public-tracker.ml:6969/announce,udp://psyco.fr:6969/announce,udp://private.anonseed.com:6969/announce,udp://open.tracker.ink:6969/announce,udp://open.free-tracker.ga:6969/announce,udp://open.dstud.io:6969/announce,udp://open.4ever.tk:6969/announce,udp://new-line.net:6969/announce,udp://movies.zsw.ca:6969/announce,udp://moonburrow.club:6969/announce,udp://mirror.aptus.co.tz:6969/announce,udp://mail.zasaonsk.ga:6969/announce,udp://mail.artixlinux.org:6969/announce,udp://laze.cc:6969/announce,udp://htz3.noho.st:6969/announce,udp://freedom.1776.ga:6969/announce,udp://free.publictracker.xyz:6969/announce,udp://fh2.cmp-gaming.com:6969/announce,udp://epider.me:6969/announce,udp://download.nerocloud.me:6969/announce,udp://dht.bt251.com:6969/announce,udp://cutscloud.duckdns.org:6969/announce,udp://concen.org:6969/announce,udp://chouchou.top:8080/announce,udp://carr.codes:6969/announce,udp://camera.lei001.com:6969/announce,udp://bt2.archive.org:6969/announce,udp://bt1.archive.org:6969/announce,udp://bt.ktrackers.com:6666/announce,udp://black-bird.ynh.fr:6969/announce,udp://bedro.cloud:6969/announce,udp://astrr.ru:6969/announce,udp://aegir.sexy:6969/announce,udp://admin.52ywp.com:6969/announce,udp://acxx.de:6969/announce,udp://aarsen.me:6969/announce,udp://6ahddutb1ucc3cp.ru:6969/announce,https://tracker.tamersunion.org:443/announce,https://tracker.moeblog.cn:443/announce,https://tracker.mlsub.net:443/announce,https://tracker.kuroy.me:443/announce,https://tracker.imgoingto.icu:443/announce,https://tracker.gbitt.info:443/announce,https://tracker.foreverpirates.co:443/announce,https://tracker.expli.top:443/announce,https://t1.hloli.org:443/announce,http://wepzone.net:6969/announce,http://vps02.net.orel.ru:80/announce,http://tracker3.ctix.cn:8080/announce,http://tracker2.dler.org:80/announce,http://tracker1.bt.moack.co.kr:80/announce,http://tracker.skyts.net:6969/announce,http://tracker.qu.ax:6969/announce,http://tracker.gbitt.info:80/announce,http://tracker.files.fm:6969/announce,http://tracker.edkj.club:6969/announce,http://tracker.bt4g.com:2095/announce,http://tr.cili001.com:8070/announce,http://t.acg.rip:6699/announce,http://p2p.0g.cx:6969/announce,http://open.tracker.ink:6969/announce,http://open.acgnxtracker.com:80/announce,http://incine.ru:6969/announce,http://fosstorrents.com:6969/announce,http://bt.okmp3.ru:2710/announce";
      };
    };

    programs.alacritty = {
      enable = false;
      settings = {
        import = [
          "~/.eendroroy-colorschemes/themes/hyper.yaml"
        ];
        window.opacity = 1.0;
        font = {
          normal = {
            family = "Fira Code";
          };
          size = 13;
        };
      };
    };

    programs.vscode = {
      enable = true;
      package = pkgs.hello // {pname = "vscodium";};
      mutableExtensionsDir = true;
      haskell = {
        enable = true;
        hie.enable = false;
      };
      extensions = with pkgs.vscode-extensions;
        [
          james-yu.latex-workshop
          ionide.ionide-fsharp
          haskell.haskell
          ms-vscode.cpptools
          llvm-vs-code-extensions.vscode-clangd
          jnoortheen.nix-ide
          bbenoist.nix
          arrterian.nix-env-selector
          usernamehw.errorlens
          kamadorueda.alejandra
          ms-dotnettools.csharp
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "cpp-checker";
            publisher = "ebikelabs";
            version = "1.4.8";
            sha256 = "sha256-frOC/gr0HJIt6qXAbRPkehfeCJJooHOlPQ4WvasIkPg=";
          }
          {
            name = "vscode-pitch-black-theme";
            publisher = "viktorqvarfordt";
            version = "1.3.0";
            sha256 = "sha256-1JDm/cWNWwxa1gNsHIM/DIvqjXsO++hAf0mkjvKyi4g=";
          }
          {
            name = "vscodeintellicode";
            publisher = "visualstudioexptteam";
            version = "1.2.21";
            sha256 = "sha256-2zYiAh5unAIjl0fjQtUCO/cPheh/vy2V36xiQfkXU58=";
          }
          {
            name = "wal-theme";
            publisher = "dlasagno";
            version = "1.2.0";
            sha256 = "sha256-X16N5ClNVLtWST64ybJUEIRo6WgDCzODhBA9ScAHI5w=";
          }
        ];
      userSettings = {
        "C_Cpp.default.cppStandard" = "c++23";
        "clangd.fallbackFlags" = [
          "-std=c++2a"
        ];
        "C_Cpp.codeAnalysis.clangTidy.args" = [
          "--checks=* --format-style=google --warnings-as-errors=*"
        ];
        # // Pitch black - Title bar (Allow the title bar to be styled by the color theme)
        # "window.titleBarStyle": "custom",
        # // Pitch plack - Hide border next to scroll bar that separates panes
        # "editor.overviewRulerBorder": false,
        "editor.overviewRulerBorder" = false;
        "C_Cpp.codeAnalysis.clangTidy.enabled" = true;
        "cpp-checker.cppcheck.--enable=" = "all";
        "cpp-checker.cppcheck.--inconclusive" = true;
        "cpp-checker.cppcheck.--std_c++=" = "c++20";
        "editor.formatOnSave" = true;
        "cpp-checker.cpplint.--filter=" = "-whitespace/comments";
        "clangd.path" = "/usr/bin/clangd";
        "workbench.colorTheme" = "Pitch Black";
        "terminal.external.linuxExec" = "/usr/bin/zsh";
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "security.workspace.trust.untrustedFiles" = "open";
        "editor.inlineSuggest.enabled" = true;
        "github.copilot.enable" = {
          "*" = true;
          "yaml" = true;
          "plaintext" = true;
          "markdown" = true;
          "haskell" = false;
        };
        "github.copilot.advanced" = {
          "length" = 1000;
        };
        "window.menuBarVisibility" = "toggle";
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "explorer.confirmDragAndDrop" = false;
        "explorer.confirmDelete" = false;
        "wal.tokenColorTheme" = "Wal Bordered";
        "C_Cpp.intelliSenseEngineFallback" = "Enabled";
        "C_Cpp.default.intelliSenseMode" = "linux-clang-x64";
        "editor.formatOnType" = true;
        "git.enableSmartCommit" = true;
        "files.watcherExclude" = {
          "**/.bloop" = true;
          "**/.metals" = true;
          "**/.ammonite" = true;
        };
        "git.followTagsWhenSync" = true;
        "terminal.integrated.enableMultiLinePasteWarning" = false;
        "FSharp.addFsiWatcher" = true;
        "C_Cpp.intelliSenseEngine" = "Disabled";
        "VisualNuGet.sources" = [
          "{\"name\": \"nuget.org\",\"url\": \"https://api.nuget.org/v3/index.json\"}"
          "{\"name\":\"dotnet7\",\"url\":\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet7/nuget/v3/index.json\"}"
        ];
        "workbench.editorAssociations" = {
          "*.actual" = "default";
        };
        "http.systemCertificates" = false;
        "editor.largeFileOptimizations" = false;
        "editor.suggest.preview" = true;
        "FSharp.msbuildAutoshow" = true;
        "FSharp.smartIndent" = true;
        "FSharp.trace.server" = "verbose";
        "FSharp.verboseLogging" = true;
        "omnisharp.enableDecompilationSupport" = true;
        "omnisharp.enableAsyncCompletion" = true;
        "kotlin.debugAdapter.enabled" = false;
        "kotlin.externalSources.autoConvertToKotlin" = true;
        "java.implementationsCodeLens.enabled" = true;
        "java.maxConcurrentBuilds" = 8;
        "java.referencesCodeLens.enabled" = true;
        "java.configuration.runtimes" = [
          {
            "default" = true;
            "name" = "JavaSE-17";
            #"path" = "${pkgs.jdk}/lib/openjdk";
          }
        ];
        #"java.jdt.ls.java.home" = "${pkgs.jdk}";
        #"python.linting.vulturePath" = "${pkgs.python3Packages.vulture}/bin/vulture";
        # "python.formatting.autopep8Path" = "${pkgs.python3Packages.autopep8}/bin/autopep8";
        #"python.formatting.blackPath" = "${pkgs.python3Packages.black}/bin/black";
        # "python.formatting.yapfPath" = "${pkgs.yapf}/bin/yapf";
        # "python.linting.banditPath" = "${pkgs.python3Packages.bandit}/bin/bandit";
        #"python.linting.flake8Path" = "${pkgs.python3Packages.flake8}/bin/flake8";
        #"python.linting.mypyPath" = "${pkgs.python3Packages.mypy}/bin/mypy";
        #"python.linting.prospectorPath" = "${pkgs.prospector}/bin/prospector";
        #"python.linting.pycodestylePath" = "${pkgs.python3Packages.pycodestyle}/bin/pycodestyle";
        #"python.linting.pydocstylePath" = "${pkgs.python3Packages.pep257}/bin/pydocstyle";
        # "python.linting.pylamaPath" = "${pkgs.python3Packages.pylama}/bin/pylama";
        #"python.linting.pylintPath" = "${pkgs.python3Packages.pylint}/bin/pylint";
        # "python.formatting.autopep8Args" = [
        #   "-j 8"
        #   "-a"
        #   "-a"
        #   "-a"
        #   "--experimental"
        # ];
        "python.formatting.blackArgs" = [
          "--preview"
          "--fast"
        ];
        "python.formatting.provider" = "black";
        # "python.linting.banditEnabled" = true;
        "python.linting.flake8Enabled" = true;
        "python.linting.mypyArgs" = [
          "--follow-imports=silent"
          "--ignore-missing-imports"
          "--show-column-numbers"
          "--no-pretty"
          "--disallow-any-unimported"
          "--disallow-any-expr"
          "--disallow-any-decorated"
          "--disallow-any-explicit"
          "--disallow-any-generics"
          "--disallow-subclassing-any"
          "--disallow-untyped-calls"
          "--disallow-untyped-defs"
          "--disallow-incomplete-defs"
          "--check-untyped-defs"
          "--disallow-untyped-decorators"
          "--warn-redundant-casts"
          "--warn-unused-ignores"
          "--warn-no-return"
          "--warn-return-any"
          "--warn-unreachable"
          "--disallow-untyped-globals"
          "--allow-redefinition"
          "--strict"
        ];
        "python.linting.mypyEnabled" = true;
        "python.linting.prospectorArgs" = [
          "-F"
          "--tool dodgy, pyflakes, pyroma, vulture"
          "--strictness veryhigh"
        ];
        "python.linting.prospectorEnabled" = true;
        "python.linting.pycodestyleEnabled" = true;
        "python.linting.pydocstyleEnabled" = true;
        "python.linting.pylintArgs" = [
          "-j0"
        ];
        # "python.linting.banditArgs" = [
        #   "--confidence-level high"
        # ];
        "python.linting.pylintEnabled" = true;
        "[python]" = {
          "editor.formatOnType" = true;
        };
        # "python.condaPath" = "${pkgs.python3Packages.conda}/bin/conda";
      };
    };

    programs.zathura = {
      enable = true;
      package = pkgs.hello;
      options = {
        selection-clipboard = "clipboard";
      };
    };

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      enableVteIntegration = true;
      plugins = [
        {
          name = "auto-notify";
          src = pkgs.fetchFromGitHub {
            owner = "MichaelAquilina";
            repo = "zsh-auto-notify";
            rev = "1f64cb654473d7208f46534bc3df47ac919d4a72";
            sha256 = "sha256-4/2wQC+kYH8gZZZZTfoioW64h+z7AF8xSPZPKc6qI3U=";
          };
        }
      ];
      autocd = true;
      history = {
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = false;
        save = 100000;
        size = 100000;
        share = false;
      };
      initExtra = ''
        if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
            exec dbus-run-session Hyprland --config ~/.config/hypr/hyprland.conf 2>&1 | tee /tmp/Hyprland.out
        fi
        #eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        export LD_LIBRARY_PATH="/usr/lib64/R/lib:/usr/lib:$LD_LIBRARY_PATH"
        bindkey '^[[1;5C' emacs-forward-word
        bindkey '^[[1;5D' emacs-backward-word
        bindkey '^[[3~' delete-char
        #(cat $HOME/.config/wpg/sequences &)
        bracketed-paste() {
          zle .$WIDGET && LBUFFER=''${LBUFFER%$'\n'}
        }
        zle -N bracketed-paste
      '';
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    services.syncthing.enable = true;
    services.gnome-keyring.enable = true;
    services.mpris-proxy.enable = true;

    targets.genericLinux.enable = true;

    accounts.email.accounts = let
      commonFn = id: {
        "mail.smtpserver.smtp_${id}.authMethod" = 10;
        "mail.receipt.request_return_receipt_on" = true;
        "mail.server.server_${id}.spamLevel" = 0;
        "mail.server.server_${id}.offline_download" = false;
        "mail.server.server_${id}.autosync_max_age_days" = 7;
        "mail.server.server_${id}.directory" = "${home.homeDirectory}/.thunderbird/default/ImapMail/lmao-${id}";
        "mail.server.server_${id}.directory-rel" = "[ProfD]ImapMail/lmao-${id}";
        "mail.server.server_${id}.authMethod" = 10;
        "mail.mdn.report.enabled" = false;
        "mailnews.start_page.enabled" = false;
        "mailnews.message_display.disable_remote_image" = false;
        "mailnews.default_news_sort_order" = 2;
        "mailnews.default_news_sort_type" = 18;
        "mailnews.default_sort_order" = 2;
      };
    in {
      "davis.davalos.delosh@gmail.com" = rec {
        address = "davis.davalos.delosh@gmail.com";
        thunderbird = {
          enable = true;
          settings = commonFn;
        };
        gpg = {
          key = "AD9ABD1908BF063E";
          signByDefault = true;
        };
        flavor = "gmail.com";
        imap = {
          host = "imap.gmail.com";
          tls = {
            enable = true;
          };
        };
        aliases = [
          "davis@0bit.dev"
          "davis@skyrisbactera.com"
        ];
        primary = true;
        realName = "Davis Davalos-DeLosh";
        smtp = {
          host = "smtp.gmail.com";
          tls = {
            useStartTls = true;
          };
        };
        userName = address;
      };
      "dada9807@colorado.edu" = rec {
        address = "dada9807@colorado.edu";
        aliases = [
          "Davis.Davalos-delosh@colorado.edu"
        ];
        thunderbird = {
          enable = true;
          settings = commonFn;
        };
        gpg = {
          key = "F5313F5CA3207988";
          signByDefault = true;
        };
        flavor = "gmail.com";
        imap = {
          host = "imap.gmail.com";
          tls = {
            enable = true;
          };
        };
        realName = "Davis Davalos-DeLosh";
        smtp = {
          host = "smtp.gmail.com";
          port = 465;
          tls = {
            useStartTls = false;
          };
        };
        userName = address;
      };
    };

    xdg.configFile = {
      "greetd.toml" = {
        text = ''
          [default_session]
          command = "dbus-run-session ${home.homeDirectory}/.nix-profile/bin/Hyprland --config ${home.homeDirectory}/.config/hypr/hyprland.conf 2>&1 | tee --append ${home.homeDirectory}/Hyprland.out"
          user = "davis"

          [initial_session]
          command = "dbus-run-session ${home.homeDirectory}/.nix-profile/bin/Hyprland --config ${home.homeDirectory}/.config/hypr/hyprland.conf 2>&1 | tee --append ${home.homeDirectory}/Hyprland.out"
          user = "davis"

          [terminal]
          vt = 1
        '';
      };
    };

    systemd.user.services = {
      aria2cd = {
        Unit = {
          Description = "aria2 Daemon";
        };

        Service = {
          Type = "forking";
          ExecStart = "${pkgs.aria2}/bin/aria2c --conf-path=${home.homeDirectory}/.config/aria2/aria2.conf";
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
      pipewire-pulse = {
        Unit = {
          Description = "PipeWire PulseAudio";
          Requires = "pipewire-pulse.socket";
          ConditionUser = "!root";
          Wants = ["pipewire.service" "pipewire-session-manager.service"];
          After = ["pipewire.service" "pipewire-session-manager.service"];
          Conflicts = "pulseaudio.service";
        };
        Service = {
          LockPersonality = "yes";
          MemoryDenyWriteExecute = "yes";
          NoNewPrivileges = "yes";
          RestrictNamespaces = "yes";
          SystemCallArchitectures = "native";
          SystemCallFilter = "@system-service";
          Type = "simple";
          ExecStart = "${pkgs.pipewire.pulse}/bin/pipewire-pulse";
          Restart = "on-failure";
          Slice = "session.slice";
        };
        Install = {
          Also = "pipewire-pulse.socket";
          WantedBy = ["default.target"];
        };
      };
    };

    xdg.enable = true;
    xdg.mime.enable = true;
    xdg.mimeApps = {
      enable = true;
      associations.added = {
        "text/plain" = "org.gnome.gedit.desktop";
        "application/pdf" = "org.pwmt.zathura.desktop";
        "x-scheme-handler/http" = "com.microsoft.Edge.desktop";
        "x-scheme-handler/https" = "com.microsoft.Edge.desktop";
        "x-scheme-handler/chrome" = "com.microsoft.Edge.desktop";
        "text/html" = "com.microsoft.Edge.desktop";
        "application/x-extension-htm" = "com.microsoft.Edge.desktop";
        "application/x-extension-html" = "com.microsoft.Edge.desktop";
        "application/x-extension-shtml" = "com.microsoft.Edge.desktop";
        "application/xhtml+xml" = "com.microsoft.Edge.desktop";
        "application/x-extension-xhtml" = "com.microsoft.Edge.desktop";
        "application/x-extension-xht" = "com.microsoft.Edge.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
        "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
        "image/png" = "swayimg.desktop";
      };

      defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
        "x-scheme-handler/http" = "com.microsoft.Edge.desktop";
        "x-scheme-handler/https" = "com.microsoft.Edge.desktop";
        "x-scheme-handler/chrome" = "com.microsoft.Edge.desktop";
        "text/html" = "com.microsoft.Edge.desktop";
        "application/x-extension-htm" = "com.microsoft.Edge.desktop";
        "application/x-extension-html" = "com.microsoft.Edge.desktop";
        "application/x-extension-shtml" = "com.microsoft.Edge.desktop";
        "application/xhtml+xml" = "com.microsoft.Edge.desktop";
        "application/x-extension-xhtml" = "com.microsoft.Edge.desktop";
        "application/x-extension-xht" = "com.microsoft.Edge.desktop";
        "image/png" = "swayimg.desktop";
      };
    };
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    programs.starship = {
      enable = true;
    };

    programs.mpv = {
      enable = true;
      package = pkgs.writeShellApplication {
        name = "mpv";
        text = ''
          exec /usr/bin/flatpak run --branch=stable --arch=x86_64 io.mpv.Mpv "$@"
        '';
      };
      #package = pkgs.mpv;
      bindings = {
        "ALT+k" = "add sub-scale +0.1";
        "ALT+j" = "add sub-scale -0.1";
      };
      config = {
        #profile = "gpu-hq";
        save-position-on-quit = "yes";
        hwdec-codecs = "all";
        vd-lavc-software-fallback = "no";
        vd-lavc-dr = "yes";
        vd-lavc-show-all = "yes";
        ad-lavc-threads = 0;
        #audio-channels = "auto";
        demuxer-max-bytes = "1400MiB";
        demuxer-max-back-bytes = 0;
        #vo = "gpu-next";
        hwdec = "vaapi";
        #scale = "ewa_lanczos";
        #scale-blur = "0.981251";
        #cscale = "ewa_lanczos";
        #cscale-blur = "0.981251";
        #tscale = "oversample";
        #video-sync = "display-resample";
        #interpolation = "yes";
        #correct-downscaling = "yes";
        #gpu-context = "wayland";
        #ao = "pipewire";
        # #opengl-es = "yes";
        # #opengl-swapinterval = "0";
        # wayland-disable-vsync = "yes";
        # scale-antiring = "0";
        # cscale-antiring = "0";
        # dither-depth = "no";
        # correct-downscaling = "no";
        # sigmoid-upscaling = "no";
        # deband = "no";
        # vd-lavc-skiploopfilter = "all";
        # script-opts-append = "ytdl_hook-ytdl_path=ytdownload";
        # ytdl_path = "ytdownload";
      };
    };

    programs.man.enable = false;

    dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";
        default-sort-order = "mtime";
        search-filter-time-type = "last_modified";
        search-view = "list-view";
        show-hidden-files = true;
      };
      "org/gnome/nautilus/compression" = {
        default-compression-format = "tar.xz";
      };
      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "small";
      };
      "org/gnome/desktop/interface" = {
        gtk-enable-primary-paste = false;
      };
    };

    programs.chromium = {
      enable = true;
      package = pkgs.hello;
      #package = pkgs.writeShellApplication {
      #  name = "edge";

      #  text = ''
      #    ${pkgs.microsoft-edge-dev}/bin/microsoft-edge-dev --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy
      #	--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,UseOzonePlatform,Vulkan,UseChromeOSDirectVideoDecoder --disable-features=UseSkiaRenderer
      #	--ozone-platform=wayland --password-store=basic "$@"
      #  '';
      #};
      commandLineArgs = ["--ignore-gpu-blocklist" "--enable-gpu-rasterization" "--enable-zero-copy"];
      extensions = [
        {
          id = "dcpihecpambacapedldabdbpakmachpb";
          updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
        }
        {id = "nngceckbapebfimnlniiiahkandclblb";}
        {id = "ekhagklcjbdpajgpjgmbionohlpdbjgc";}
      ];
    };

    programs.firefox = {
      enable = true;
      package = pkgs.firefox.override {
        cfg = {
          enablePlasmaBrowserIntegration = true;
        };
      };
      #extensions = with nur.repos.rycee.firefox-addons; [
      #  bitwarden
      #  pywalfox
      #  translate-web-pages
      #  auto-tab-discard
      #  #darkreader
      #  plasma-integration
      #];
      profiles = {
        "default" = {
          isDefault = true;
          name = "Default";
          settings = {
            "media.ffmpeg.vaapi.enabled" = true;
            "widget.dmabuf.force-enabled" = true;
            "media.rdd-ffmpeg.enabled" = true;
            "media.av1.enabled" = false;
            "gfx.webrender.all" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "layers.acceleration.force-enabled" = true;
            "gfx.webrender.enabled" = true;
            "layout.css.backdrop-filter.enabled" = true;
            "svg.context-properties.content.enabled" = true;
            "ui.systemUsesDarkTheme" = "1";
            "layout.css.prefers-color-scheme.content-override" = "0";
            "dom.ipc.processCount.file" = "4";
            "dom.ipc.processCount" = "8";
            "browser.preferences.defaultPerformanceSettings.enabled" = false;
            "browser.cache.memory.enable" = true;
            "browser.cache.disk.parent_directory" = "/run/user/1000/firefox";
            "browser.sessionstore.interval" = "600000";
            "extensions.pocket.enabled" = false;
            "media.hardware-video-decoding.force-enabled" = true;
            "webgl.msaa-force" = true;
            "font.name.monospace.x-western" = "Fira Code";
            "font.name.sans-serif.x-western" = "Jost*";
            "font.name.serif.x-western" = "CMU Serif";
          };
          userChrome = ''
            #TabsToolbar, #titlebar, #main-window, #navigator-toolbox {
              -moz-appearance: none !important;
              background-color: rgba(255,255,255,0) !important;
              background-image: none !important;
            }
          '';
        };
      };
    };

    programs.gh = {
      enable = true;
      settings.editor = "code";
      settings.prompt = "enabled";
    };

    programs.gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
      publicKeys = [
        {
          text = ''
            -----BEGIN PGP PUBLIC KEY BLOCK-----

            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
            TgTa3TsO3rasWquU2yOIKxuR4l7JehMj/tGKICM=
            =nF+M
            -----END PGP PUBLIC KEY BLOCK-----
          '';
          trust = "ultimate";
        }
        {
          text = ''
            -----BEGIN PGP PUBLIC KEY BLOCK-----

            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
            Bni03Qbc8dmE2dxH1IUvnb3io/W7Y3gy9uA=
            =y8tV
            -----END PGP PUBLIC KEY BLOCK-----
          '';
          trust = "ultimate";
        }
      ];
    };

    programs.git = {
      enable = true;
      delta.enable = true;
      lfs.enable = true;
      userEmail = "davis.davalos.delosh@gmail.com";
      userName = "Davis Davalos-DeLosh";
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fonts.fontconfig.enable = true;

    services.playerctld.enable = true;

    home.packages = with pkgs; [
      powercap

      wl-clipboard-x11.out

      gst_all_1.gstreamer
      gst_all_1.gst-vaapi
      gst_all_1.gst-libav
      gst_all_1.gstreamermm
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-base
      clapper
      jost
      fira-code
      cm_unicode
      ipafont
      #ananicy

      cachix

      #tlpuipkgs.tlpui

      (pkgs.writeShellApplication {
        name = "nixsize";
        text = ''
          nix why-depends path:${home.homeDirectory}/.config/nixpkgs#homeConfigurations.davis.activationPackage "nixpkgs#$1"
          nix-store -q --requisites "$(nix-build --no-out-link '<nixpkgs>' -A "$1")" | sort -uf | xargs du -ch | tail -1
        '';
      })

      (pkgs.writeShellApplication {
        name = "obsidian";
        text = ''
          obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
        '';
      })

      (pkgs.writeShellApplication {
        name = "update";
        text = ''
          sudo swupd update --3rd-party --update-search-file-index
          flatpak update -u
          flatpak update --system
          sudo flatpak update -u
          sudo flatpak update --system
          sudo npm update -g
          stack upgrade
          cabal update
          cd ~/.config/nixpkgs
          nix flake update
          home-manager switch --flake '.#davis' --keep-going -b backup --show-trace
          nix-channel --update
          nix profile upgrade '.*' --impure
        '';
      })
      #obsidian

      (pkgs.writeShellApplication {
        name = "process_lecture";
        runtimeInputs = [ffmpeg-full unsilence];
        text = ''
          MYTMP=$(mktemp -d)
          echo "$MYTMP"
          ${pkgs.ffmpeg-full}/bin/ffmpeg -i "$1" -c:v copy -af arnndn="${pkgs.boca}/lib/boca/boca.dsp.rnnoise/sh.rnnn" "$MYTMP/$1.rnn.mkv"
          unsilence --non-interactive-mode --threads 8 -ss 99 -st 0 -sit 0 -stt 0.256 "$MYTMP/$1.rnn.mkv" "$1_ALTERED.mkv"
          rm -rf "$MYTMP"
        '';
      })

      (pkgs.writeShellApplication {
        name = "process_multiple_lectures";
        text = ''
          mkdir -p Complete; find . -maxdepth 1 -type f -exec process_lecture {} \; -exec mv {}_ALTERED.mkv Complete \;
        '';
      })

      i7z
      playerctl

      greetd.greetd
      ronn
      pavucontrol

      #python2
      #(pkgs.writeShellApplication {
      #  name = "zotero";
      #  runtimeInputs = with pkgs; [zotero cage];
      #  text = ''
      #    cage zotero
      #  '';
      #})
      winetricks
      wineWowPackages.stagingFull

      # gfx.run

      dotnet-sdk
      #brave

      (pkgs.writeShellApplication {
        name = "cacheBuild";
        runtimeInputs = [cachix];
        text = ''
          pkill cachix || true

          nix flake archive --json \
            | jq -r '.path,(.inputs|to_entries[].value.path)' \
            | cachix push programmerino

          cachix watch-store programmerino &
          pid=$!

          nix build --json \
            | jq -r '.[].outputs | to_entries[].value' \
            | cachix push programmerino

          echo Type exit in the next shell
          nix develop --profile dev-profile -c date
          cachix push programmerino dev-profile
          rm dev-profile*

          nix build -L

          rm dev-profile*
          pkill cachix
          wait $pid
        '';
      })

      (pkgs.writeShellApplication {
        name = "cleanup";
        text = ''
          sudo rm -rf ~/.local/share/Trash/*
          sudo journalctl --vacuum-size=0M
          nix-env --delete-generations old
          nix-collect-garbage -d
          nix-store --optimise
          sudo nix-collect-garbage -d
          sudo nix-store --optimise
        '';
      })

      (pkgs.writeShellApplication {
        name = "convert_md";
        text = ''
          pandoc -s "$1" -t markdown_mmd+raw_tex+smart+auto_identifiers+tex_math_dollars+tex_math_single_backslash+tex_math_double_backslash+raw_html+header_attributes+implicit_header_references+simple_tables -t markdown_mmd+raw_tex+smart+auto_identifiers+tex_math_dollars+tex_math_single_backslash+tex_math_double_backslash+raw_html+header_attributes+implicit_header_references+simple_tables -o "$1.md"
          cat ~/Documents/frontmatter "$1.md" > temp && mv temp "$1.md"
        '';
      })

      (pkgs.writeShellApplication {
        name = "download";
        runtimeInputs = [aria];
        text = ''
          aria2c --bt-tracker="udp://tracker.opentrackr.org:1337/announce,http://tracker.opentrackr.org:1337/announce,udp://9.rarbg.com:2810/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker.dler.org:6969/announce,udp://p4p.arenabg.com:1337/announce,udp://opentracker.i2p.rocks:6969/announce,udp://open.stealth.si:80/announce,udp://open.demonii.com:1337/announce,udp://ipv4.tracker.harry.lu:80/announce,udp://explodie.org:6969/announce,udp://exodus.desync.com:6969/announce,https://tracker.nanoha.org:443/announce,https://tracker.lilithraws.org:443/announce,https://tr.burnabyhighstar.com:443/announce,https://opentracker.i2p.rocks:443/announce,http://tracker.dler.org:6969/announce,udp://zecircle.xyz:6969/announce,udp://www.peckservers.com:9000/announce,udp://wepzone.net:6969/announce,udp://vibe.sleepyinternetfun.xyz:1738/announce,udp://v2.iperson.xyz:6969/announce,udp://v1046920.hosted-by-vdsina.ru:6969/announce,udp://uploads.gamecoast.net:6969/announce,udp://trackerb.jonaslsa.com:6969/announce,udp://tracker2.dler.org:80/announce,udp://tracker1.myporn.club:9337/announce,udp://tracker1.bt.moack.co.kr:80/announce,udp://tracker.theoks.net:6969/announce,udp://tracker.tcp.exchange:6969/announce,udp://tracker.srv00.com:6969/announce,udp://tracker.skyts.net:6969/announce,udp://tracker.skynetcloud.site:6969/announce,udp://tracker.qu.ax:6969/announce,udp://tracker.publictracker.xyz:6969/announce,udp://tracker.pimpmyworld.to:6969/announce,udp://tracker.openbtba.com:6969/announce,udp://tracker.monitorit4.me:6969/announce,udp://tracker.moeking.me:6969/announce,udp://tracker.leech.ie:1337/announce,udp://tracker.joybomb.tw:6969/announce,udp://tracker.jonaslsa.com:6969/announce,udp://tracker.ddunlimited.net:6969/announce,udp://tracker.bitsearch.to:1337/announce,udp://tracker.auctor.tv:6969/announce,udp://tracker.artixlinux.org:6969/announce,udp://tracker.altrosky.nl:6969/announce,udp://tracker.4.babico.name.tr:3131/announce,udp://tracker-udp.gbitt.info:80/announce,udp://tr.cili001.com:8070/announce,udp://tr.bangumi.moe:6969/announce,udp://torrents.artixlinux.org:6969/announce,udp://thouvenin.cloud:6969/announce,udp://themaninashed.com:6969/announce,udp://thagoat.rocks:6969/announce,udp://tamas3.ynh.fr:6969/announce,udp://slicie.icon256.com:8000/announce,udp://sanincode.com:6969/announce,udp://run.publictracker.xyz:6969/announce,udp://run-2.publictracker.xyz:6969/announce,udp://rep-art.ynh.fr:6969/announce,udp://qtstm32fan.ru:6969/announce,udp://public.tracker.vraphim.com:6969/announce,udp://public.publictracker.xyz:6969/announce,udp://public-tracker.ml:6969/announce,udp://psyco.fr:6969/announce,udp://private.anonseed.com:6969/announce,udp://open.tracker.ink:6969/announce,udp://open.free-tracker.ga:6969/announce,udp://open.dstud.io:6969/announce,udp://open.4ever.tk:6969/announce,udp://new-line.net:6969/announce,udp://movies.zsw.ca:6969/announce,udp://moonburrow.club:6969/announce,udp://mirror.aptus.co.tz:6969/announce,udp://mail.zasaonsk.ga:6969/announce,udp://mail.artixlinux.org:6969/announce,udp://laze.cc:6969/announce,udp://htz3.noho.st:6969/announce,udp://freedom.1776.ga:6969/announce,udp://free.publictracker.xyz:6969/announce,udp://fh2.cmp-gaming.com:6969/announce,udp://epider.me:6969/announce,udp://download.nerocloud.me:6969/announce,udp://dht.bt251.com:6969/announce,udp://cutscloud.duckdns.org:6969/announce,udp://concen.org:6969/announce,udp://chouchou.top:8080/announce,udp://carr.codes:6969/announce,udp://camera.lei001.com:6969/announce,udp://bt2.archive.org:6969/announce,udp://bt1.archive.org:6969/announce,udp://bt.ktrackers.com:6666/announce,udp://black-bird.ynh.fr:6969/announce,udp://bedro.cloud:6969/announce,udp://astrr.ru:6969/announce,udp://aegir.sexy:6969/announce,udp://admin.52ywp.com:6969/announce,udp://acxx.de:6969/announce,udp://aarsen.me:6969/announce,udp://6ahddutb1ucc3cp.ru:6969/announce,https://tracker.tamersunion.org:443/announce,https://tracker.moeblog.cn:443/announce,https://tracker.mlsub.net:443/announce,https://tracker.kuroy.me:443/announce,https://tracker.imgoingto.icu:443/announce,https://tracker.gbitt.info:443/announce,https://tracker.foreverpirates.co:443/announce,https://tracker.expli.top:443/announce,https://t1.hloli.org:443/announce,http://wepzone.net:6969/announce,http://vps02.net.orel.ru:80/announce,http://tracker3.ctix.cn:8080/announce,http://tracker2.dler.org:80/announce,http://tracker1.bt.moack.co.kr:80/announce,http://tracker.skyts.net:6969/announce,http://tracker.qu.ax:6969/announce,http://tracker.gbitt.info:80/announce,http://tracker.files.fm:6969/announce,http://tracker.edkj.club:6969/announce,http://tracker.bt4g.com:2095/announce,http://tr.cili001.com:8070/announce,http://t.acg.rip:6699/announce,http://p2p.0g.cx:6969/announce,http://open.tracker.ink:6969/announce,http://open.acgnxtracker.com:80/announce,http://incine.ru:6969/announce,http://fosstorrents.com:6969/announce,http://bt.okmp3.ru:2710/announce" --enable-dht6 --optimize-concurrent-downloads=true --enable-dht -k 1048576 -x16 -V -j16 -c --uri-selector=adaptive --http-accept-gzip=true --bt-enable-lpd --bt-load-saved-metadata --bt-max-peers=999999 --bt-max-open-files=999999 --bt-prioritize-piece=head,tail --bt-save-metadata --file-allocation=falloc -s16 "$@"
        '';
      })

      (pkgs.writeShellApplication {
        name = "ipfsdownload";
        text = ''
          download "https://ipfs.io/ipfs/$1" "https://cloudflare-ipfs.com/ipfs/$1" "https://gateway.ipfs.io/ipfs/$1" "https://dweb.link/ipfs/$1" "https://ipfs-gateway.cloud/ipfs/$1" "https://gateway.pinata.cloud/ipfs/$1" "https://4everland.io/ipfs/$1" "https://cf-ipfs.com/ipfs/$1" "https://w3s.link/ipfs/$1" "https://ipfs.fleek.co/ipfs/$1" "https://hardbin.com/ipfs/$1" "https://hub.textile.io/ipfs/$1" "https://ipfs.joaoleitao.org/ipfs/$1" "https://jorropo.net/ipfs/$1" "https://ipfs.eth.aragon.network/ipfs/$1" "https://c4rex.co/ipfs/$1"
        '';
      })

      (pkgs.writeShellApplication {
        name = "md_to_html";
        text = ''
          rm "$1.tmp.tex"
          rm "$1.html"
          pandoc -s "$1" -o "$1.tmp.tex"
          pandoc -s "$1.tmp.tex" -o "$1.html"
        '';
      })

      (pkgs.writeShellApplication {
        name = "find_bin";
        text = ''
          sudo swupd search-file -B --order=size "$1" || true
                      nix-locate "/bin/$1" --at-root --whole-name | grep -v \)
        '';
      })

      (pkgs.writeShellApplication {
        name = "youtube-dl";
        runtimeInputs = [yt-dlp];
        text = ''
          yt-dlp -i --sponsorblock-remove all --mark-watched --no-abort-on-error -N 8 -R "infinite" --xattr-set-filesize --hls-use-mpegts --external-downloader aria2c --external-downloader-args "--enable-dht6 --enable-dht -k 1048576 -x16 -j16 -c --file-allocation=falloc -s16 --allow-overwrite=true" -c --no-part --write-thumbnail --video-multistreams --audio-multistreams --write-auto-subs --audio-quality 0 --embed-subs --embed-thumbnail --embed-metadata --embed-info-json --embed-chapters --cookies-from-browser firefox --xattrs "$@"
        '';
      })

      (pkgs.writeShellApplication {
        name = "dec_volume";
        runtimeInputs = [playerctl pamixer];
        text = ''
          set +o errexit
          prev=$(playerctl volume)
          echo Previous "$prev" "$(pamixer --get-volume)"
          playerctl volume 0.05- || true
          if [ "$prev" == "$(playerctl volume)" ]; then
            echo Adjusting system volume...
            pamixer -ud 2
          fi
          echo Now "$(playerctl volume)" "$(pamixer --get-volume)"
        '';
      })

      (pkgs.writeShellApplication {
        name = "inc_volume";
        runtimeInputs = [playerctl pamixer];
        text = ''
          set +o errexit
          prev=$(playerctl volume)
          echo Previous "$prev" "$(pamixer --get-volume)"
          if (( $(echo "($prev + 0.05) > 1.0" | bc -l) )); then
            echo Adjusting system volume to avoid clipping...
            pamixer -ui 2
          else
            playerctl volume 0.05+ || true
            if [ "$prev" == "$(playerctl volume)" ]; then
              echo Adjusting system volume because application cannot change volume...
              pamixer -ui 2
            fi
          fi
          echo Now "$(playerctl volume)" "$(pamixer --get-volume)"
        '';
      })
      (pkgs.writeShellApplication {
        name = "oled-protection";
        text = ''
          gaps_in_list=(0 2 5 8)
          gaps_out_list=(0 2 5 8 11 14 17 20 23)
          border_size_list=(0 3)
          hyprctl keyword general:gaps_in "''${gaps_in_list[$RANDOM % ''${#gaps_in_list[@]} ]}"
          hyprctl keyword general:gaps_out "''${gaps_out_list[$RANDOM % ''${#gaps_out_list[@]} ]}"
          hyprctl keyword general:border_size "''${border_size_list[$RANDOM % ''${#border_size_list[@]} ]}"
        '';
      })
    ];

    home.keyboard = {
      layout = "us";
    };

    home.language.base = "en_US.UTF-8";
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      gtk.enable = true;
    };

    home.sessionVariables = {
      #NIXOS_OZONE_WL = 1;
      SDL_VIDEODRIVER = "wayland";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      #QT_QPA_PLATFORMTHEME = "qt5ct";
      __GLX_GSYNC_ALLOWED = 1;
      __GL_GSYNC_ALLOWED = 1;
      __GL_VRR_ALLOWED = 1;
      MOZ_DISABLE_RDD_SANDBOX = 1;
      EGL_PLATFORM = "wayland";
      __NV_PRIME_RENDER_OFFLOAD = 1;
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      DOTNET_CLI_TELEMETRY_OPTOUT = 1;
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = 1;
      DOTNET_ROOT = "${pkgs.dotnet-sdk}";
      _JAVA_AWT_WM_NONREPARENTING = 1;
      #XDG_DATA_DIRS = "/nix/var/nix/profiles/default/share:${home.homeDirectory}/.nix-profile/share:/usr/share/ubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop:/var/lib/flatpak/exports/share:/usr/local/share/:/usr/share/:${home.homeDirectory}/.local/share/flatpak/exports/share";
      SUDO_EDITOR = "code";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      R_HOME = "/usr/lib64/R";
      GST_VAAPI_ALL_DRIVERS = 1;
      #WLR_NO_HARDWARE_CURSORS = 1;
      NO_XWAYLAND = 0;
      MOZ_WEBRENDER = 1;
      MOZ_ENABLE_WAYLAND = 1;
      skip_global_compinit = 1;
      ZSH_DISABLE_COMPFIX = "true";
      VSCODE_GALLERY_SERVICE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery";
      VSCODE_GALLERY_CACHE_URL = "https://vscode.blob.core.windows.net/gallery/index";
    };

    gtk = {
      enable = true;
      cursorTheme = {
        name = "Bibata-Modern-Classic";
      };
      font = {
        package = pkgs.jost;
        name = "Jost* Light";
        size = 12;
      };
      iconTheme = {
        name = "flattrcolor-dark";
      };
      theme = {
        name = "Orchis-grey-oled";
      };
    };
  };
}
