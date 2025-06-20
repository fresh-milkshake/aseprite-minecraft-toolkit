
local Constants = load_mc_module("core/constants.lua")
local ColorUtils = load_mc_module("core/color_utils.lua")
local SelectionUtils = load_mc_module("core/selection_utils.lua")

local HueShift = {}

local hue_dialog = nil
local original_cell_image = nil
local current_bounds = nil
local variants = {}
local selected_variant = 0

local settings = {
    variants_count = 6,
    hue_shift = 45,
    saturation_boost = 0,
    lightness_adjust = 0,
    contrast = 0,
    accent_color_enabled = false,
    accent_color = Color { red = 255, green = 100, blue = 100 },
    accent_strength = 30,
    preserve_grays = false,
    color_temperature = 0,
    vibrance = 0
}

function HueShift.create_command(plugin)
    return plugin:newCommand {
        id = "MCToolkitHue",
        title = "Hue Shift",
        group = "mc_toolkit_menu_group",
        onenabled = function()
            return app.activeSprite ~= nil and SelectionUtils.is_valid_cell_selection()
        end,
        onclick = function()
            HueShift.show_dialog()
        end
    }
end

function HueShift.show_dialog()
    current_bounds = SelectionUtils.get_current_cell_selection()
    if not current_bounds then
        app.alert("Please select a 16x16 cell for hue shift")
        return
    end

    original_cell_image = SelectionUtils.create_cell_image(current_bounds)
    if not original_cell_image then
        app.alert("Cannot create image from selection")
        return
    end

    if hue_dialog then
        hue_dialog:close()
    end

    selected_variant = 0
    HueShift.generate_variants()

    hue_dialog = Dialog("Hue Shift Studio - " .. current_bounds.width .. "x" .. current_bounds.height .. " cell")

    hue_dialog:canvas {
        id = "preview_canvas",
        width = 384,
        height = 80,
        onpaint = function(ev)
            HueShift.draw_preview(ev.context)
        end,
        onmousedown = function(ev)
            local variant_width = 64
            local clicked_variant = math.floor(ev.x / variant_width)
            if clicked_variant >= 0 and clicked_variant < settings.variants_count then
                selected_variant = clicked_variant
                hue_dialog:repaint()
            end
        end
    }

    hue_dialog:newrow()

    hue_dialog:label { text = "Main settings" }
    hue_dialog:newrow()

    hue_dialog:slider {
        id = "variants_count",
        label = "Variants count:",
        min = 2,
        max = 8,
        value = settings.variants_count,
        onchange = function()
            settings.variants_count = hue_dialog.data.variants_count
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:slider {
        id = "hue_shift",
        label = "Hue shift:",
        min = 5,
        max = 180,
        value = settings.hue_shift,
        onchange = function()
            settings.hue_shift = hue_dialog.data.hue_shift
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:newrow()

    hue_dialog:label { text = "Color correction" }
    hue_dialog:newrow()

    hue_dialog:slider {
        id = "saturation_boost",
        label = "Saturation:",
        min = -50,
        max = 50,
        value = settings.saturation_boost,
        onchange = function()
            settings.saturation_boost = hue_dialog.data.saturation_boost
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:slider {
        id = "lightness_adjust",
        label = "Lightness:",
        min = -30,
        max = 30,
        value = settings.lightness_adjust,
        onchange = function()
            settings.lightness_adjust = hue_dialog.data.lightness_adjust
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:slider {
        id = "contrast",
        label = "Contrast:",
        min = -20,
        max = 20,
        value = settings.contrast,
        onchange = function()
            settings.contrast = hue_dialog.data.contrast
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:slider {
        id = "vibrance",
        label = "Vibrance:",
        min = -30,
        max = 30,
        value = settings.vibrance,
        onchange = function()
            settings.vibrance = hue_dialog.data.vibrance
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:newrow()

    hue_dialog:label { text = "Accent colors" }
    hue_dialog:newrow()

    hue_dialog:check {
        id = "accent_color_enabled",
        text = "Use accent color",
        selected = settings.accent_color_enabled,
        onclick = function()
            settings.accent_color_enabled = hue_dialog.data.accent_color_enabled
            hue_dialog:modify{id = "accent_color", visible = settings.accent_color_enabled}
            hue_dialog:modify{id = "accent_strength", visible = settings.accent_color_enabled}
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:color {
        id = "accent_color",
        label = "Accent color:",
        color = settings.accent_color,
        visible = settings.accent_color_enabled,
        onchange = function()
            settings.accent_color = hue_dialog.data.accent_color
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:slider {
        id = "accent_strength",
        label = "Accent strength:",
        min = 0,
        max = 100,
        value = settings.accent_strength,
        visible = settings.accent_color_enabled,
        onchange = function()
            settings.accent_strength = hue_dialog.data.accent_strength
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:newrow()

    hue_dialog:label { text = "Additional options" }
    hue_dialog:newrow()

    hue_dialog:check {
        id = "preserve_grays",
        text = "Preserve grays",
        selected = settings.preserve_grays,
        onclick = function()
            settings.preserve_grays = hue_dialog.data.preserve_grays
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:slider {
        id = "color_temperature",
        label = "Color temperature:",
        min = -50,
        max = 50,
        value = settings.color_temperature,
        onchange = function()
            settings.color_temperature = hue_dialog.data.color_temperature
            HueShift.generate_variants()
            hue_dialog:repaint()
        end
    }

    hue_dialog:newrow()

    hue_dialog:label {
        id = "selection_info",
        text = "Selected variant: " .. (selected_variant + 1) .. " (click to select)"
    }

    hue_dialog:newrow()

    hue_dialog:button {
        text = "Apply selected",
        onclick = function()
            HueShift.apply_variant()
            hue_dialog:close()
            hue_dialog = nil
        end
    }

    hue_dialog:button {
        text = "Reset settings",
        onclick = function()
            HueShift.reset_settings()
            hue_dialog:close()
            HueShift.show_dialog()
        end
    }

    hue_dialog:button {
        text = "Close",
        onclick = function()
            hue_dialog:close()
            hue_dialog = nil
        end
    }

    hue_dialog:show { wait = false }
end

function HueShift.generate_variants()
    variants = {}

    for variant = 0, settings.variants_count - 1 do
        local variant_image = Image(Constants.GRID_SIZE, Constants.GRID_SIZE)
        local shift_amount = variant * settings.hue_shift

        for y = 0, Constants.GRID_SIZE - 1 do
            for x = 0, Constants.GRID_SIZE - 1 do
                local pixel = original_cell_image:getPixel(x, y)

                if pixel ~= 0 then
                    if variant == 0 then
                        variant_image:putPixel(x, y, pixel)
                    else
                        local new_pixel = HueShift.process_pixel(pixel, shift_amount)
                        variant_image:putPixel(x, y, new_pixel)
                    end
                end
            end
        end

        variants[variant + 1] = variant_image
    end
end

function HueShift.process_pixel(pixel, hue_shift_amount)
    local color = Color(pixel)
    local h, s, l = ColorUtils.rgb_to_hsl(color.red, color.green, color.blue)

    if settings.preserve_grays and s < 10 then
        return pixel
    end

    h = (h + hue_shift_amount) % 360

    s = math.max(0, math.min(100, s + settings.saturation_boost))

    l = math.max(0, math.min(100, l + settings.lightness_adjust))

    if settings.vibrance ~= 0 then
        local vibrance_factor = (100 - s) / 100
        s = s + (settings.vibrance * vibrance_factor)
        s = math.max(0, math.min(100, s))
    end

    if settings.color_temperature ~= 0 then
        if settings.color_temperature > 0 then
            h = h + (settings.color_temperature * 0.2)
        else
            h = h + (settings.color_temperature * 0.3)
        end
        h = h % 360
    end

    local r, g, b = ColorUtils.hsl_to_rgb(h, s, l)

    if settings.contrast ~= 0 then
        local contrast_factor = (settings.contrast + 100) / 100
        r = math.max(0, math.min(255, ((r - 128) * contrast_factor) + 128))
        g = math.max(0, math.min(255, ((g - 128) * contrast_factor) + 128))
        b = math.max(0, math.min(255, ((b - 128) * contrast_factor) + 128))
    end

    if settings.accent_color_enabled and settings.accent_strength > 0 then
        local accent_factor = settings.accent_strength / 100
        r = r + (settings.accent_color.red - r) * accent_factor * 0.3
        g = g + (settings.accent_color.green - g) * accent_factor * 0.3
        b = b + (settings.accent_color.blue - b) * accent_factor * 0.3
        r = math.max(0, math.min(255, r))
        g = math.max(0, math.min(255, g))
        b = math.max(0, math.min(255, b))
    end

    local new_color = Color { red = math.floor(r), green = math.floor(g), blue = math.floor(b), alpha = color.alpha }
    return new_color.rgbaPixel
end

function HueShift.draw_preview(ctx)
    local variant_width = 64
    local variant_height = 64
    local margin = 2

    ctx.color = Color { red = 40, green = 40, blue = 40 }
    ctx:fillRect(Rectangle(0, 0, ctx.width, ctx.height))

    for i = 1, settings.variants_count do
        local x = (i - 1) * variant_width
        local y = 8

        if (i - 1) == selected_variant then
            ctx.color = Color { red = 255, green = 255, blue = 0 }
            ctx:fillRect(Rectangle(x - margin, y - margin, variant_width + margin * 2, variant_height + margin * 2))
        end

        ctx.color = Color { red = 60, green = 60, blue = 60 }
        ctx:fillRect(Rectangle(x, y, variant_width, variant_height))

        if variants[i] then
            local scale = variant_width / Constants.GRID_SIZE
            for py = 0, Constants.GRID_SIZE - 1 do
                for px = 0, Constants.GRID_SIZE - 1 do
                    local pixel = variants[i]:getPixel(px, py)
                    if pixel ~= 0 then
                        ctx.color = Color(pixel)
                        ctx:fillRect(Rectangle(
                            x + px * scale,
                            y + py * scale,
                            scale,
                            scale
                        ))
                    end
                end
            end
        end

        ctx.color = Color { red = 255, green = 255, blue = 255 }
        ctx:fillText(tostring(i), x + 4, y + variant_height + 4)
    end

    if hue_dialog then
        hue_dialog:modify{id = "selection_info", text = "Selected variant: " .. (selected_variant + 1) .. " (click to select)"}
    end
end

function HueShift.apply_variant()
    if not variants[selected_variant + 1] or not current_bounds then
        app.alert("No variant selected for application")
        return
    end

    local sprite = app.activeSprite
    if not sprite or not app.activeCel then
        app.alert("No active sprite or layer")
        return
    end

    local cel_image = app.activeCel.image
    local selected_image = variants[selected_variant + 1]

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = selected_image:getPixel(x, y)
            cel_image:putPixel(current_bounds.x + x, current_bounds.y + y, pixel)
        end
    end

    app.refresh()
    app.alert("Variant " .. (selected_variant + 1) .. " applied!")
end

function HueShift.reset_settings()
    settings = {
        variants_count = 6,
        hue_shift = 45,
        saturation_boost = 0,
        lightness_adjust = 0,
        contrast = 0,
        accent_color_enabled = false,
        accent_color = Color { red = 255, green = 100, blue = 100 },
        accent_strength = 30,
        preserve_grays = false,
        color_temperature = 0,
        vibrance = 0
    }
    selected_variant = 0
end

return HueShift