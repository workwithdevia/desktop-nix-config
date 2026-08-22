{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    profiles.workwithdevia = {
      id = 0;
      name = "Default";
      isDefault = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
      ];
      settings = {
        "browser.startup.homepage" = "https://notion.com";
        "browser.search.defaultenginename" = "DuckDuckGo";
        "privacy.resistFingerprinting" = true;
        "extensions.autoDisableScopes" = 0;
        "browser.tabs.inTitlebar" = 1;
        "browser.search.showOneOffButtons" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.position_start" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "signon.rememberSignons" = false;
        "browser.formfill.enable" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;
      };
    };
  };
}
