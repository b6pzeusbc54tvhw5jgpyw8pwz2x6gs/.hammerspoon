-- Hyper Key Overlay: shows keyboard layout with shortcut bindings while Hyper is held
-- Supports swappable keyboard layouts (see layouts/ directory)

local canvas = hs.canvas
local eventtap = hs.eventtap
local styledtext = hs.styledtext
local image = hs.image

-- Configuration
local LAYOUT_NAME = "magic_keyboard_us"  -- change this to switch keyboard layout
local KEY_SIZE = 144
local KEY_GAP = 8
local PADDING = 40
local TITLE_HEIGHT = 60
local CORNER_RADIUS = 16

-- Colors
local COLORS = {
    bg         = {red = 0.08, green = 0.08, blue = 0.08, alpha = 0.93},
    keyDefault = {red = 0.15, green = 0.15, blue = 0.15, alpha = 1},
    keyBound   = {red = 0.18, green = 0.22, blue = 0.35, alpha = 1},
    keyPressed = {red = 0.30, green = 0.50, blue = 0.85, alpha = 1},
    textDim    = {red = 0.35, green = 0.35, blue = 0.35, alpha = 1},
    textBright = {red = 0.95, green = 0.95, blue = 0.95, alpha = 1},
    textHint   = {red = 0.5,  green = 0.6,  blue = 0.8,  alpha = 1},
    title      = {red = 0.6,  green = 0.6,  blue = 0.6,  alpha = 1},
}

-- Load keyboard layout
local layout = require("modules.hyper_key_overlay.layouts." .. LAYOUT_NAME)

-- Load bindings from JSON by modifier name
local function loadBindings(modName)
    local path = hs.configdir .. "/modules/hyper_key_overlay/bindings_" .. modName .. ".json"
    local f = io.open(path, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    return hs.json.decode(content) or {}
end

-- Get app icon from binding
local function getIcon(binding)
    if binding.icon then
        local img = image.imageFromAppBundle(binding.icon)
        if img then return img end
    end
    if binding.appPath then
        local expanded = binding.appPath:gsub("^~", os.getenv("HOME"))
        local img = image.iconForFile(expanded)
        if img then return img end
    end
    return nil
end

-- Compute pixel positions from layout rows
local function computePositions(rows)
    local positions = {}
    local y = TITLE_HEIGHT
    for _, row in ipairs(rows) do
        local x = 0
        for _, keyDef in ipairs(row) do
            local w = keyDef.w or 1
            local pixelW = w * KEY_SIZE + math.max(0, w - 1) * KEY_GAP
            table.insert(positions, {
                key = keyDef.key:lower(),
                label = keyDef.label or keyDef.key:upper(),
                modifier = keyDef.modifier,
                x = x,
                y = y,
                w = pixelW,
                h = KEY_SIZE,
            })
            x = x + pixelW + KEY_GAP
        end
        y = y + KEY_SIZE + KEY_GAP
    end
    return positions
end

-- Overlay title per mode
local MODE_TITLES = {
    hyper     = "\u{2303}\u{2325}\u{21E7}\u{2318} Hyper Key Shortcuts",
    option    = "\u{2325} Option Key Shortcuts",
    cmd_shift = "\u{2318}\u{21E7} Command+Shift Shortcuts",
}

-- Build and show the overlay canvas
local overlayCanvas = nil
local currentMode = nil

local function showOverlay(flags, mode)
    if overlayCanvas then return end

    flags = flags or {}
    mode = mode or "hyper"
    currentMode = mode
    local bindings = loadBindings(mode)
    local positions = computePositions(layout.rows)

    -- Calculate canvas size
    local maxX, maxY = 0, 0
    for _, pos in ipairs(positions) do
        maxX = math.max(maxX, pos.x + pos.w)
        maxY = math.max(maxY, pos.y + pos.h)
    end
    local cw = maxX + PADDING * 2
    local ch = maxY + PADDING * 2

    -- Center on main screen
    local screen = hs.screen.mainScreen():frame()
    overlayCanvas = canvas.new({
        x = screen.x + (screen.w - cw) / 2,
        y = screen.y + (screen.h - ch) / 2,
        w = cw, h = ch,
    })

    local idx = 1

    -- Background
    overlayCanvas[idx] = {
        type = "rectangle",
        roundedRectRadii = {xRadius = 16, yRadius = 16},
        fillColor = COLORS.bg,
    }
    idx = idx + 1

    -- Title
    overlayCanvas[idx] = {
        type = "text",
        frame = {x = PADDING, y = 12, w = cw - PADDING * 2, h = TITLE_HEIGHT},
        text = styledtext.new(MODE_TITLES[mode] or "Shortcuts", {
            font = {name = ".AppleSystemUIFont", size = 30},
            color = COLORS.title,
            paragraphStyle = {alignment = "center"},
        }),
    }
    idx = idx + 1

    -- Which left-side modifiers to highlight per mode
    local pressedMods = {}
    if mode == "hyper" then
        pressedMods = {shift_l = true, ctrl_l = true, alt_l = true, cmd_l = true}
    elseif mode == "option" then
        pressedMods = {alt_l = true}
    elseif mode == "cmd_shift" then
        pressedMods = {cmd_l = true, shift_l = true}
    end

    -- Keys
    for _, pos in ipairs(positions) do
        local binding = bindings[pos.key]
        local isBound = binding ~= nil
        local isPressed = pos.modifier and pressedMods[pos.modifier]

        -- Key background
        local keyColor = COLORS.keyDefault
        if isPressed then
            keyColor = COLORS.keyPressed
        elseif isBound then
            keyColor = COLORS.keyBound
        end

        overlayCanvas[idx] = {
            type = "rectangle",
            frame = {x = pos.x + PADDING, y = pos.y + PADDING, w = pos.w, h = pos.h},
            roundedRectRadii = {xRadius = CORNER_RADIUS, yRadius = CORNER_RADIUS},
            fillColor = keyColor,
        }
        idx = idx + 1

        if isPressed then
            -- Modifier key label (pressed state)
            overlayCanvas[idx] = {
                type = "text",
                frame = {x = pos.x + PADDING, y = pos.y + PADDING + 45, w = pos.w, h = 54},
                text = styledtext.new(pos.label, {
                    font = {name = ".AppleSystemUIFont", size = 34},
                    color = COLORS.textBright,
                    paragraphStyle = {alignment = "center"},
                }),
            }
            idx = idx + 1
        elseif isBound then
            local icon = getIcon(binding)
            if icon then
                -- App icon
                local iconSize = 72
                overlayCanvas[idx] = {
                    type = "image",
                    frame = {
                        x = pos.x + PADDING + (pos.w - iconSize) / 2,
                        y = pos.y + PADDING + 8,
                        w = iconSize, h = iconSize,
                    },
                    image = icon,
                }
                idx = idx + 1

                -- Label below icon
                overlayCanvas[idx] = {
                    type = "text",
                    frame = {x = pos.x + PADDING + 2, y = pos.y + PADDING + 84, w = pos.w - 4, h = 50},
                    text = styledtext.new(binding.label, {
                        font = {name = ".AppleSystemUIFont", size = 20},
                        color = COLORS.textBright,
                        paragraphStyle = {alignment = "center", lineBreak = "truncateTail"},
                    }),
                }
                idx = idx + 1
            else
                -- Command label (no icon)
                overlayCanvas[idx] = {
                    type = "text",
                    frame = {x = pos.x + PADDING + 4, y = pos.y + PADDING + 15, w = pos.w - 8, h = 60},
                    text = styledtext.new(binding.label, {
                        font = {name = ".AppleSystemUIFont", size = 22},
                        color = COLORS.textBright,
                        paragraphStyle = {alignment = "center", lineBreak = "truncateTail"},
                    }),
                }
                idx = idx + 1

                -- Key hint below
                overlayCanvas[idx] = {
                    type = "text",
                    frame = {x = pos.x + PADDING, y = pos.y + PADDING + 86, w = pos.w, h = 44},
                    text = styledtext.new(pos.label, {
                        font = {name = ".AppleSystemUIFont", size = 22},
                        color = COLORS.textHint,
                        paragraphStyle = {alignment = "center"},
                    }),
                }
                idx = idx + 1
            end
        else
            -- Unbound key
            overlayCanvas[idx] = {
                type = "text",
                frame = {x = pos.x + PADDING, y = pos.y + PADDING + 45, w = pos.w, h = 54},
                text = styledtext.new(pos.label, {
                    font = {name = ".AppleSystemUIFont", size = 34},
                    color = COLORS.textDim,
                    paragraphStyle = {alignment = "center"},
                }),
            }
            idx = idx + 1
        end
    end

    overlayCanvas:level(canvas.windowLevels.overlay)
    overlayCanvas:behavior(canvas.windowBehaviors.canJoinAllSpaces)
    overlayCanvas:show()
end

local function hideOverlay()
    if overlayCanvas then
        overlayCanvas:delete()
        overlayCanvas = nil
    end
end

-- Detect modifier holds to show overlay
_hyperOverlayTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    local isHyper = flags.cmd and flags.alt and flags.ctrl and flags.shift
    local isOptionOnly = flags.alt and not flags.cmd and not flags.ctrl and not flags.shift
    local isCmdShift = flags.cmd and flags.shift and not flags.alt and not flags.ctrl

    -- Determine desired mode (most specific first)
    local desiredMode = nil
    if isHyper then
        desiredMode = "hyper"
    elseif isCmdShift then
        desiredMode = "cmd_shift"
    elseif isOptionOnly then
        desiredMode = "option"
    end

    if desiredMode then
        if overlayCanvas and currentMode ~= desiredMode then
            pcall(hideOverlay)
        end
        if not overlayCanvas then
            local ok, err = pcall(showOverlay, flags, desiredMode)
            if not ok then print("[hyper_overlay] show error: " .. tostring(err)) end
        end
    elseif overlayCanvas then
        pcall(hideOverlay)
    end
    return false
end)
_hyperOverlayTap:start()


print("[hyper_overlay] module loaded")

return {}
