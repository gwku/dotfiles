{ username, ... }: {
  # Mirrors the preferences this user actually has set on the machine,
  # rather than forcing typical-dev defaults. Audited from a live
  # `defaults read` dump across every customised domain.
  #
  # nix-darwin's typed schema covers a subset of NSGlobalDomain keys.
  # Anything outside the typed set goes through CustomUserPreferences,
  # which writes raw plist values via `defaults write`.

  system.defaults = {
    dock = {
      autohide = false;
      tilesize = 46;
      magnification = false;
      show-recents = false;
      mru-spaces = false;
      minimize-to-application = true;
      expose-group-apps = false;
      wvous-tr-corner = 14; # top-right hot corner = Lock Screen

      persistent-apps = [
        "/Applications/Zen.app"
        "/Applications/Thunderbird.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/App Store.app"
        "/System/Applications/System Settings.app"
        "/Applications/Nix Apps/WezTerm.app"
        "/Applications/Todoist.app"
        "/Users/${username}/Applications/Rider.app"
        "/Applications/Obsidian.app"
        "/System/Applications/Utilities/Activity Monitor.app"
        "/Applications/Bitwarden.app"
        "/Applications/Claude.app"
        "/Applications/ChatGPT.app"
        "/Applications/Slack.app"
        "/Applications/WhatsApp.app"
        "/Applications/Signal.app"
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "icnv";
    };

    WindowManager = {
      GloballyEnabled = false; # Stage Manager off
      AutoHide = false;
      EnableTiledWindowMargins = false;
      HideDesktop = true;
      StandardHideDesktopIcons = true;
    };

    # Typed NSGlobalDomain options only — the rest go in
    # CustomUserPreferences below.
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      "com.apple.swipescrolldirection" = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 0; # 0 = never show date in menu bar
      ShowDayOfWeek = true;
    };

    # Untyped plist keys — nix-darwin doesn't expose typed options
    # for these, so they go through CustomUserPreferences which writes
    # values directly via `defaults write`.
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleLanguages = [
          "en-US"
          "nl-NL"
        ];
        AppleLocale = "en_US@rg=nlzzzz";
        AppleMiniaturizeOnDoubleClick = false;
        NSWindowShouldDragOnGesture = false;
        WebAutomaticSpellingCorrectionEnabled = false;
        "com.apple.trackpad.scaling" = 0.6875;
        "com.apple.trackpad.forceClick" = true;
        "com.apple.mouse.tapBehavior" = 0;
        "com.apple.mouse.scaling" = 1.5;
        "com.apple.scrollwheel.scaling" = 0.3125;
        "com.apple.sound.beep.flash" = 0;
        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.5;
      };

      "com.apple.screencapture" = {
        showsClicks = true;
        showsCursor = true;
      };

      # Preserve the current system-wide shortcut choices. IDs are
      # Apple's stable symbolic-hotkey identifiers.
      "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
        "15".enabled = false;
        "16".enabled = false;
        "17".enabled = false;
        "18".enabled = false;
        "19".enabled = false;
        "20".enabled = false;
        "21".enabled = false;
        "22".enabled = false;
        "23".enabled = false;
        "24".enabled = false;
        "25".enabled = false;
        "26".enabled = false;
        "79".enabled = true;
        "80".enabled = true;
        "81".enabled = true;
        "82".enabled = true;
        "164" = {
          enabled = false;
          value = {
            parameters = [
              65535
              65535
              0
            ];
            type = "standard";
          };
        };
        "31" = {
          enabled = true;
          value = {
            parameters = [
              115
              1
              1179648
            ];
            type = "standard";
          };
        };
        "60" = {
          enabled = true;
          value = {
            parameters = [
              32
              49
              262144
            ];
            type = "standard";
          };
        };
        "61" = {
          enabled = true;
          value = {
            parameters = [
              32
              49
              786432
            ];
            type = "standard";
          };
        };
      };
    };

    # No screencapture override — user keeps screenshots on Desktop.
    # No key-repeat override — user uses macOS defaults.
    # No AppleInterfaceStyle override — user has Auto light/dark.
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
