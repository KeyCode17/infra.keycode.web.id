{ username, ... }:
{
  home-manager.users.${username}.home.file.".hammerspoon/init.lua".text = ''
    -- Focus follows mouse: activate window under cursor without clicking
    local prevWindow = nil

    local function focusWindowUnderMouse()
      local pos = hs.mouse.absolutePosition()
      local win = hs.window.find(function(w)
        return w:isVisible() and w:frame():containsPoint(pos)
      end)
      if win and win ~= prevWindow then
        win:focus()
        prevWindow = win
      end
    end

    hs.timer.new(0.1, focusWindowUnderMouse):start()
  '';
}
