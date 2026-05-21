{ ... }: {
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.4;
      tilesize = 42;
      orientation = "bottom";
      show-recents = false;
      mru-spaces = false;
      minimize-to-application = true;
      show-process-indicators = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "clmv";
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";

      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false;

      NSAutomaticCapitalizationEnabled    = false;
      NSAutomaticDashSubstitutionEnabled  = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled  = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      NSNavPanelExpandedStateForSaveMode  = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint  = true;
      PMPrintingExpandedStateForPrint2 = true;

      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.scaling"    = 1.5;
      "com.apple.mouse.tapBehavior"   = 1;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    screencapture.location = "~/Pictures/Screenshots";

    LaunchServices.LSQuarantine = false;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
