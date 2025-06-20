
local Constants = load_mc_module("core/constants.lua")
local ColorUtils = load_mc_module("core/color_utils.lua")
local SelectionUtils = load_mc_module("core/selection_utils.lua")

local IntermediateColors = {}

local intermediate_dialog = nil
local current_bounds = nil
local original_cell_image = nil
local preview_image = nil
local current_timer = nil
local last_bounds_hash = nil
local last_frame_number = nil
local last_layer_id = nil

local settings = {
    algorithm = "edge_smoothing",
    intensity = 50,
    threshold = 30,
    brightness = 0,
    contrast = 0,
    preserve_transparency = true,
    color_reduction = false,
    target_colors = 16
}

function IntermediateColors.create_command(plugin)
    return plugin:newCommand {
        id = "MCToolkitIntermediateColors",
        title = "Add Intermediate Colors",
        group = "mc_toolkit_menu_group",
        onenabled = function()
            return app.activeSprite ~= nil and SelectionUtils.is_valid_cell_selection()
        end,
        onclick = function()
            IntermediateColors.show_dialog()
        end
    }
end

function IntermediateColors.get_bounds_hash(bounds)
    if not bounds then return nil end
    return bounds.x .. "," .. bounds.y .. "," .. bounds.width .. "," .. bounds.height
end

function IntermediateColors.check_for_updates()
    if not intermediate_dialog or not app.activeSprite then
        return
    end

    local current_frame = app.activeFrame.frameNumber
    local current_layer = app.activeLayer.id
    local new_bounds = SelectionUtils.get_current_cell_selection()
    local new_bounds_hash = IntermediateColors.get_bounds_hash(new_bounds)

    if new_bounds_hash and new_bounds_hash ~= last_bounds_hash then
        last_bounds_hash = new_bounds_hash
        current_bounds = new_bounds

        original_cell_image = SelectionUtils.create_cell_image(current_bounds)
        if original_cell_image then
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end

        last_frame_number = current_frame
        last_layer_id = current_layer
        return
    end

    if current_frame ~= last_frame_number or current_layer ~= last_layer_id then
        last_frame_number = current_frame
        last_layer_id = current_layer

        if current_bounds then
            original_cell_image = SelectionUtils.create_cell_image(current_bounds)
            if original_cell_image then
                IntermediateColors.generate_preview()
                intermediate_dialog:repaint()
            end
        end
    end
end

function IntermediateColors.start_timer()
    if current_timer then
        current_timer:stop()
    end

    current_timer = Timer{
        interval = 0.01,
        ontick = function()
            IntermediateColors.check_for_updates()
        end
    }
    current_timer:start()
end

function IntermediateColors.stop_timer()
    if current_timer then
        current_timer:stop()
        current_timer = nil
    end
end

function IntermediateColors.show_dialog()
    current_bounds = SelectionUtils.get_current_cell_selection()
    if not current_bounds then
        app.alert("Please select a 16x16 cell for intermediate colors processing")
        return
    end

    original_cell_image = SelectionUtils.create_cell_image(current_bounds)
    if not original_cell_image then
        app.alert("Cannot create image from selection")
        return
    end

    if intermediate_dialog then
        intermediate_dialog:close()
    end

    last_bounds_hash = IntermediateColors.get_bounds_hash(current_bounds)
    last_frame_number = app.activeFrame.frameNumber
    last_layer_id = app.activeLayer.id

    IntermediateColors.generate_preview()

    intermediate_dialog = Dialog("Add Intermediate Colors")

    intermediate_dialog:canvas {
        id = "preview_canvas",
        width = 256,
        height = 140,
        onpaint = function(ev)
            IntermediateColors.draw_preview(ev.context)
        end
    }

    intermediate_dialog:newrow()

    intermediate_dialog:combobox {
        id = "algorithm",
        label = "Algorithm:",
        option = settings.algorithm,
        options = {"edge_smoothing", "bilinear", "anti_aliasing", "selective_smooth", "smart_dither"},
        onchange = function()
            settings.algorithm = intermediate_dialog.data.algorithm
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:slider {
        id = "intensity",
        label = "Intensity:",
        min = 0,
        max = 100,
        value = settings.intensity,
        onchange = function()
            settings.intensity = intermediate_dialog.data.intensity
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:newrow()

    intermediate_dialog:slider {
        id = "threshold",
        label = "Color Threshold:",
        min = 1,
        max = 150,
        value = settings.threshold,
        onchange = function()
            settings.threshold = intermediate_dialog.data.threshold
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:slider {
        id = "brightness",
        label = "Brightness:",
        min = -50,
        max = 50,
        value = settings.brightness,
        onchange = function()
            settings.brightness = intermediate_dialog.data.brightness
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:newrow()

    intermediate_dialog:slider {
        id = "contrast",
        label = "Contrast:",
        min = -50,
        max = 50,
        value = settings.contrast,
        onchange = function()
            settings.contrast = intermediate_dialog.data.contrast
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:check {
        id = "preserve_transparency",
        text = "Preserve Transparency",
        selected = settings.preserve_transparency,
        onclick = function()
            settings.preserve_transparency = intermediate_dialog.data.preserve_transparency
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:newrow()

    intermediate_dialog:check {
        id = "color_reduction",
        text = "Color Reduction",
        selected = settings.color_reduction,
        onclick = function()
            settings.color_reduction = intermediate_dialog.data.color_reduction
            intermediate_dialog:modify{id = "target_colors", visible = settings.color_reduction}
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:slider {
        id = "target_colors",
        label = "Target Colors:",
        min = 4,
        max = 64,
        value = settings.target_colors,
        visible = settings.color_reduction,
        onchange = function()
            settings.target_colors = intermediate_dialog.data.target_colors
            IntermediateColors.generate_preview()
            intermediate_dialog:repaint()
        end
    }

    intermediate_dialog:newrow()

    intermediate_dialog:button {
        id = "apply",
        text = "Apply to Selection",
        onclick = function()
            IntermediateColors.apply_to_selection()
        end
    }

    intermediate_dialog:button {
        id = "reset",
        text = "Reset All",
        onclick = function()
            IntermediateColors.reset_settings()
        end
    }

    intermediate_dialog:button {
        id = "update",
        text = "Manual Update",
        onclick = function()
            current_bounds = SelectionUtils.get_current_cell_selection()
            if current_bounds then
                last_bounds_hash = IntermediateColors.get_bounds_hash(current_bounds)
                original_cell_image = SelectionUtils.create_cell_image(current_bounds)
                if original_cell_image then
                    IntermediateColors.generate_preview()
                    intermediate_dialog:repaint()
                end
            else
                app.alert("Please select a valid 16x16 cell")
            end
        end
    }

    intermediate_dialog:button {
        id = "close",
        text = "Close",
        onclick = function()
            IntermediateColors.stop_timer()
            intermediate_dialog:close()
            intermediate_dialog = nil
        end
    }

    IntermediateColors.start_timer()

    intermediate_dialog:show{wait = false}
end

function IntermediateColors.generate_preview()
    if not original_cell_image then return end

    preview_image = Image(Constants.GRID_SIZE, Constants.GRID_SIZE, original_cell_image.colorMode)

    if settings.algorithm == "edge_smoothing" then
        IntermediateColors.apply_edge_smoothing(original_cell_image, preview_image)
    elseif settings.algorithm == "bilinear" then
        IntermediateColors.apply_bilinear(original_cell_image, preview_image)
    elseif settings.algorithm == "anti_aliasing" then
        IntermediateColors.apply_anti_aliasing(original_cell_image, preview_image)
    elseif settings.algorithm == "selective_smooth" then
        IntermediateColors.apply_selective_smoothing(original_cell_image, preview_image)
    elseif settings.algorithm == "smart_dither" then
        IntermediateColors.apply_smart_dither(original_cell_image, preview_image)
    end

    IntermediateColors.apply_post_processing(preview_image)
end

function IntermediateColors.draw_preview(ctx)
    if not original_cell_image or not preview_image then return end

    local scale = 8

    ctx:fillText("Original", 8, 8)
    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = original_cell_image:getPixel(x, y)
            if pixel ~= 0 then
                local color = Color(pixel)
                ctx.color = color
                ctx:fillRect(Rectangle(8 + x * scale, 20 + y * scale, scale, scale))
            end
        end
    end

    ctx:fillText("Preview", 140, 8)
    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = preview_image:getPixel(x, y)
            if pixel ~= 0 then
                local color = Color(pixel)
                ctx.color = color
                ctx:fillRect(Rectangle(140 + x * scale, 20 + y * scale, scale, scale))
            end
        end
    end
end

function IntermediateColors.calculate_delta_e(color1, color2)
    local dr = color1.red - color2.red
    local dg = color1.green - color2.green
    local db = color1.blue - color2.blue
    return math.sqrt(dr * dr + dg * dg + db * db)
end

function IntermediateColors.interpolate_colors(color1, color2, factor)
    return Color{
        red = math.floor(color1.red + (color2.red - color1.red) * factor),
        green = math.floor(color1.green + (color2.green - color1.green) * factor),
        blue = math.floor(color1.blue + (color2.blue - color1.blue) * factor),
        alpha = color1.alpha
    }
end

function IntermediateColors.apply_edge_smoothing(source, target)
    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            target:putPixel(x, y, source:getPixel(x, y))
        end
    end

    for y = 1, Constants.GRID_SIZE - 2 do
        for x = 1, Constants.GRID_SIZE - 2 do
            local center_pixel = source:getPixel(x, y)
            if center_pixel == 0 and settings.preserve_transparency then goto continue end

            local center_color = Color(center_pixel)

            for dy = -1, 1 do
                for dx = -1, 1 do
                    if dx == 0 and dy == 0 then goto skip end

                    local nx, ny = x + dx, y + dy
                    if nx >= 0 and nx < Constants.GRID_SIZE and ny >= 0 and ny < Constants.GRID_SIZE then
                        local neighbor_pixel = source:getPixel(nx, ny)
                        if neighbor_pixel ~= 0 then
                            local neighbor_color = Color(neighbor_pixel)
                            local delta_e = IntermediateColors.calculate_delta_e(center_color, neighbor_color)

                            if delta_e > settings.threshold then
                                local factor = (settings.intensity / 100.0) * 0.5
                                local intermediate = IntermediateColors.interpolate_colors(center_color, neighbor_color, factor)
                                target:putPixel(x, y, intermediate.rgbaPixel)
                                goto continue
                            end
                        end
                    end

                    ::skip::
                end
            end

            ::continue::
        end
    end
end

function IntermediateColors.apply_bilinear(source, target)
    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = source:getPixel(x, y)
            if pixel == 0 then
                target:putPixel(x, y, 0)
                goto continue
            end

            local colors = {}
            local count = 0

            for dy = -1, 1 do
                for dx = -1, 1 do
                    local nx, ny = x + dx, y + dy
                    if nx >= 0 and nx < Constants.GRID_SIZE and ny >= 0 and ny < Constants.GRID_SIZE then
                        local neighbor_pixel = source:getPixel(nx, ny)
                        if neighbor_pixel ~= 0 then
                            local color = Color(neighbor_pixel)
                            colors[count + 1] = color
                            count = count + 1
                        end
                    end
                end
            end

            if count > 1 then
                local r, g, b = 0, 0, 0
                for i = 1, count do
                    r = r + colors[i].red
                    g = g + colors[i].green
                    b = b + colors[i].blue
                end

                local avg = Color{
                    red = math.floor(r / count),
                    green = math.floor(g / count),
                    blue = math.floor(b / count),
                    alpha = colors[1].alpha
                }

                local original = Color(pixel)
                local factor = settings.intensity / 100.0
                local blended = Color{
                    red = math.floor(original.red + (avg.red - original.red) * factor),
                    green = math.floor(original.green + (avg.green - original.green) * factor),
                    blue = math.floor(original.blue + (avg.blue - original.blue) * factor),
                    alpha = original.alpha
                }

                target:putPixel(x, y, blended.rgbaPixel)
            else
                target:putPixel(x, y, pixel)
            end

            ::continue::
        end
    end
end

function IntermediateColors.apply_anti_aliasing(source, target)
    IntermediateColors.apply_bilinear(source, target)
end

function IntermediateColors.apply_selective_smoothing(source, target)
    IntermediateColors.apply_edge_smoothing(source, target)
end

function IntermediateColors.apply_smart_dither(source, target)
    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = source:getPixel(x, y)
            target:putPixel(x, y, pixel)
        end
    end

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            if (x + y) % 2 == 0 then
                local pixel = target:getPixel(x, y)
                if pixel ~= 0 then
                    local color = Color(pixel)
                    local factor = settings.intensity / 200.0
                    local adjusted = Color{
                        red = math.max(0, math.min(255, math.floor(color.red * (1 + factor)))),
                        green = math.max(0, math.min(255, math.floor(color.green * (1 + factor)))),
                        blue = math.max(0, math.min(255, math.floor(color.blue * (1 + factor)))),
                        alpha = color.alpha
                    }
                    target:putPixel(x, y, adjusted.rgbaPixel)
                end
            end
        end
    end
end

function IntermediateColors.apply_post_processing(image)
    if settings.brightness ~= 0 or settings.contrast ~= 0 then
        IntermediateColors.apply_brightness_contrast(image)
    end

    if settings.color_reduction then
        IntermediateColors.apply_color_reduction(image)
    end
end

function IntermediateColors.apply_brightness_contrast(image)
    local brightness = settings.brightness / 100.0
    local contrast = (settings.contrast + 100) / 100.0

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = image:getPixel(x, y)
            if pixel ~= 0 then
                local color = Color(pixel)

                local r = ((color.red / 255.0 - 0.5) * contrast + 0.5 + brightness) * 255
                local g = ((color.green / 255.0 - 0.5) * contrast + 0.5 + brightness) * 255
                local b = ((color.blue / 255.0 - 0.5) * contrast + 0.5 + brightness) * 255

                local new_color = Color{
                    red = math.max(0, math.min(255, math.floor(r))),
                    green = math.max(0, math.min(255, math.floor(g))),
                    blue = math.max(0, math.min(255, math.floor(b))),
                    alpha = color.alpha
                }

                image:putPixel(x, y, new_color.rgbaPixel)
            end
        end
    end
end

function IntermediateColors.apply_color_reduction(image)
    local colors = {}
    local color_map = {}

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local pixel = image:getPixel(x, y)
            if pixel ~= 0 then
                local color = Color(pixel)
                local key = color.red .. "," .. color.green .. "," .. color.blue
                if not color_map[key] then
                    color_map[key] = color
                    table.insert(colors, color)
                end
            end
        end
    end

    if #colors > settings.target_colors then
        local reduced_colors = IntermediateColors.reduce_color_palette(colors, settings.target_colors)

        for y = 0, Constants.GRID_SIZE - 1 do
            for x = 0, Constants.GRID_SIZE - 1 do
                local pixel = image:getPixel(x, y)
                if pixel ~= 0 then
                    local color = Color(pixel)
                    local nearest = IntermediateColors.find_nearest_color(color, reduced_colors)
                    image:putPixel(x, y, nearest.rgbaPixel)
                end
            end
        end
    end
end

function IntermediateColors.reduce_color_palette(colors, target_count)
    if #colors <= target_count then return colors end

    local step = math.floor(#colors / target_count)
    local reduced = {}

    for i = 1, target_count do
        local index = math.min(i * step, #colors)
        table.insert(reduced, colors[index])
    end

    return reduced
end

function IntermediateColors.find_nearest_color(target, palette)
    local min_distance = math.huge
    local nearest = palette[1]

    for _, color in ipairs(palette) do
        local distance = IntermediateColors.calculate_delta_e(target, color)
        if distance < min_distance then
            min_distance = distance
            nearest = color
        end
    end

    return nearest
end

function IntermediateColors.reset_settings()
    settings.algorithm = "edge_smoothing"
    settings.intensity = 50
    settings.threshold = 30
    settings.brightness = 0
    settings.contrast = 0
    settings.preserve_transparency = true
    settings.color_reduction = false
    settings.target_colors = 16

    if intermediate_dialog then
        intermediate_dialog:modify{id = "algorithm", option = settings.algorithm}
        intermediate_dialog:modify{id = "intensity", value = settings.intensity}
        intermediate_dialog:modify{id = "threshold", value = settings.threshold}
        intermediate_dialog:modify{id = "brightness", value = settings.brightness}
        intermediate_dialog:modify{id = "contrast", value = settings.contrast}
        intermediate_dialog:modify{id = "preserve_transparency", selected = settings.preserve_transparency}
        intermediate_dialog:modify{id = "color_reduction", selected = settings.color_reduction}
        intermediate_dialog:modify{id = "target_colors", value = settings.target_colors, visible = settings.color_reduction}

        IntermediateColors.generate_preview()
        intermediate_dialog:repaint()
    end
end

function IntermediateColors.apply_to_selection()
    if not preview_image or not current_bounds then
        app.alert("No preview available")
        return
    end

    local sprite = app.activeSprite
    if not sprite then return end

    local cel = app.activeCel
    if not cel then return end

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local src_x = current_bounds.x + x
            local src_y = current_bounds.y + y

            if src_x >= 0 and src_x < cel.image.width and src_y >= 0 and src_y < cel.image.height then
                local pixel = preview_image:getPixel(x, y)
                cel.image:putPixel(src_x, src_y, pixel)
            end
        end
    end

    app.refresh()
    app.alert("Intermediate colors applied to selection")
end

return IntermediateColors