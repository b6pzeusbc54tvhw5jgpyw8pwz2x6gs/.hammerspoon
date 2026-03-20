local inputEnglish = "com.apple.keylayout.ABC"

hs.window.filter.new("iTerm2")
  :subscribe(hs.window.filter.windowFocused, function()
    hs.keycodes.currentSourceID(inputEnglish)
  end)
