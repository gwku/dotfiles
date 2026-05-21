{ ... }: {
  # Mirrors the preferences this user actually has set on the machine,
  # rather than forcing typical-dev defaults. Anything not declared
  # here is left to macOS / the user's manual System Settings choices.

  system.defaults = {
    dock = {
      autohide = false;
      tilesize = 46;
      magnification = false;
      show-recents = true;
      mru-spaces = false;
      minimize-to-application = true;

      # Hot corner: top-right = Lock Screen (13 in older macOS, 14
      # in modern macOS for Lock Screen action).
      wvous-tr-corner = 14;

      # Pinned dock apps, in order. Adjust freely — drag-to-reorder in
      # the dock will get clobbered on next switch.
      persistent-apps = [
        "/Applications/Zen.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/App Store.app"
        "/System/Applications/System Settings.app"
        "/Applications/WezTerm.app"
        "/Applications/Todoist.app"
        "/Users/gwku/Applications/Rider.app"
        "/Users/gwku/Applications/WebStorm.app"
        "/Users/gwku/Applications/PyCharm.app"
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

    NSGlobalDomain = {
      # Don't force AppleInterfaceStyle — user has automatic
      # light/dark switching enabled, and forcing "Dark" here would
      # lock it.

      AppleShowAllExtensions = true;
      AppleMiniaturizeOnDoubleClick = false;

      # Text editing — match user's choices (autocorrect off, but
      # autocapitalisation and period substitution are kept ON).
      NSAutomaticCapitalizationEnabled    = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = false;

      # Bilingual: English UI, Dutch region.
      AppleLanguages = [ "en-US" "nl-NL" ];
      AppleLocale = "en_US@rg=nlzzzz";

      # Trackpad / mouse — match this user's exact preferences.
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.scaling" = 0.6875;
      "com.apple.mouse.tapBehavior" = 0;

      # Expanded save and print panels by default — quality-of-life.
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

    # No screencapture override — user has it at the default location.
    # No key-repeat override — user uses macOS defaults.
    # No LSQuarantine override — user hasn't disabled it.
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
