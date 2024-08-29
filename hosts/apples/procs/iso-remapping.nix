{...}:
{
  system.keyboard.userKeyMapping = [
    # remap escape to caps lock
    # so we swap caps lock and escape, then we can use caps lock as escape
    {
    HIDKeyboardModifierMappingSrc = 30064771113;
    HIDKeyboardModifierMappingDst = 30064771129;
    }
    # remap tilde key for ISO
    { 
    HIDKeyboardModifierMappingSrc = 30064771172;
    HIDKeyboardModifierMappingDst = 30064771125;
    }
    # remap backslash to return for ISO
    {
    HIDKeyboardModifierMappingDst = 30064771112;
    HIDKeyboardModifierMappingSrc = 30064771121;
    }
    # remap ISO tilde to backslash
    {
    HIDKeyboardModifierMappingDst = 30064771121;
    HIDKeyboardModifierMappingSrc = 30064771125;
    }
  ];
}
