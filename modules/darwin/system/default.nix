{ username, ... }:
{
  system.stateVersion = 5;

  # Disable memory compression — eliminates CPU overhead from compressor and
  # decompression latency; swap remains enabled as OOM safety net.
  # Requires reboot to take effect.
  launchd.daemons.set-boot-args = {
    serviceConfig = {
      Label = "com.local.set-boot-args";
      ProgramArguments = [
        "/usr/sbin/nvram"
        "boot-args=-arm64e_preview_abi vm_compressor=2"
      ];
      RunAtLoad = true;
    };
  };

  # AC: sleep after 30min; Battery: 10min — managed per-source by pmset-performance daemon
  power.sleep.computer = 30;
  power.sleep.display = 10;
  power.sleep.harddisk = 10;
  system.primaryUser = username;

  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771113;
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771113;
        HIDKeyboardModifierMappingDst = 30064771129;
      }
    ];
  };

  launchd.daemons.keyboard-remap = {
    serviceConfig = {
      Label = "com.local.keyboard-remap";
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771113},{"HIDKeyboardModifierMappingSrc":30064771113,"HIDKeyboardModifierMappingDst":30064771129}]}''
      ];
      RunAtLoad = true;
    };
  };
}
