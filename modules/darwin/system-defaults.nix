{ username, ... }: {
  # Mirrors the preferences this user actually has set on the machine,
  # rather than forcing typical-dev defaults. Audited from a live
  # `defaults read` dump across every customised domain.

  system.defaults = {
    dock = {
      autohide = false;
      tilesize = 46;
      magnification = false;
      show-recents = true;
      mru-spaces = false;
      minimize-to-application = true;
      expose-group-apps = false;

      # Hot corner: top-right = Lock Screen.
      wvous-tr-corner = 14;

      # Pinned dock apps, in order. Drag-to-reorder is clobbered on
      # next switch — edit this list instead.
      persistent-apps = [
        "/Applications/Zen.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/App Store.app"
        "/System/Applications/System Settings.app"
        "/Applications/WezTerm.app"
        "/Applications/Todoist.app"
        "/Users/${username}/Applications/Rider.app"
        "/Users/${username}/Applications/WebStorm.app"
        "/Users/${username}/Applications/PyCharm.app"
        "/Applications/Obsidian.app"
        "/System/Applications/Utilities/Activity Monitor.app"
        "/Applications/Bitwarden.app"
        "/Applications/Slack.app"
        "/Applications/WhatsApp.app"
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "icnv";
    };

    # Stage Manager off, but desktop icons hidden (cleaner desktop).
    WindowManager = {
      GloballyEnabled = false;
      AutoHide = false;
      EnableTiledWindowMargins = false;
      HideDesktop = true;
      StandardHideDesktopIcons = true;
    };

    NSGlobalDomain = {
      # AppleInterfaceStyle deliberately not set — user runs automatic
      # light/dark switching, declaring "Dark" would lock it.

      AppleShowAllExtensions = true;
      AppleMiniaturizeOnDoubleClick = false;
      NSWindowShouldDragOnGesture = false;

      # Text editing — autocorrect off, everything else stays default.
      NSAutomaticCapitalizationEnabled    = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = false;
      WebAutomaticSpellingCorrectionEnabled = false;

      # Bilingual: English UI, Dutch region.
      AppleLanguages = [ "en-US" "nl-NL" ];
      AppleLocale = "en_US@rg=nlzzzz";

      # Trackpad / mouse — match user's exact tuning.
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.scaling" = 0.6875;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.mouse.tapBehavior" = 0;
      "com.apple.mouse.scaling" = 1.5;
      "com.apple.scrollwheel.scaling" = 0.3125;

      # No screen flash on system beep.
      "com.apple.sound.beep.flash" = 0;

      # Spring-loaded folders.
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;

      # Expanded save / print panels.
      NSNavPanelExpandedStateForSaveMode  = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint  = true;
      PMPrintingExpandedStateForPrint2 = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 0;        # 0 = never show date in menu bar
      ShowDayOfWeek = true;
    };

    # No screencapture override — user keeps screenshots on Desktop.
    # No key-repeat override — user uses macOS defaults.
    # No LSQuarantine override — user hasn't disabled it.
    # No AppleInterfaceStyle override — user has Auto switching.
    # NSAutomaticDashSubstitutionEnabled / NSAutomaticQuoteSubstitutionEnabled
    # left default (true) — user wants smart quotes.
    # NSAutomaticInlinePredictionEnabled / NSAutomaticTextCompletionEnabled
    # left default — user hasn't customised.
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
