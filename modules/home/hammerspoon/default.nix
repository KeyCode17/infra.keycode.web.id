{ username, ... }:
{
  home-manager.users.${username}.home.file.".hammerspoon/init.lua".text = ''
    -- Focus follows mouse: focus window under cursor on hover, no click needed
    local prevWindow = nil

    local mouseWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
      local pos = hs.mouse.absolutePosition()
      local win = hs.window.find(function(w)
        return w:isVisible() and not w:isMinimized() and w:frame():containsPoint(pos)
      end)
      if win and win ~= prevWindow then
        win:focus()
        prevWindow = win
      end
    end)
    mouseWatcher:start()

    -- 3-finger horizontal swipe → Aerospace workspace prev/next
    local swipeDX   = 0
    local swipeDY   = 0
    local lastSwipe = 0

    local function switchWorkspace(dir)
      local now = hs.timer.secondsSinceEpoch()
      if now - lastSwipe < 0.4 then return end
      lastSwipe = now
      hs.task.new(
        "/Applications/Nix Apps/AeroSpace.app/Contents/MacOS/AeroSpace",
        nil, { "workspace", dir }
      ):start()
    end

    local scrollWatcher = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, function(e)
      local phase = e:getProperty(hs.eventtap.event.properties.scrollWheelEventScrollPhase)
      local dx    = e:getProperty(hs.eventtap.event.properties.scrollWheelEventFixedPtDeltaAxis2)
      local dy    = e:getProperty(hs.eventtap.event.properties.scrollWheelEventFixedPtDeltaAxis1)

      if phase == 1 then
        swipeDX = 0
        swipeDY = 0
      elseif phase == 4 then
        swipeDX = swipeDX + dx
        swipeDY = swipeDY + dy
      elseif phase == 8 then
        if math.abs(swipeDX) > 50 and math.abs(swipeDX) > math.abs(swipeDY) * 1.5 then
          if swipeDX > 0 then switchWorkspace("prev")
          else               switchWorkspace("next")
          end
        end
        swipeDX = 0
        swipeDY = 0
      end
      return false
    end)
    scrollWatcher:start()
  '';
}
