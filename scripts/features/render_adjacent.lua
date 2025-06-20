
local Constants = load_mc_module("core/constants.lua")
local SelectionUtils = load_mc_module("core/selection_utils.lua")

local RenderAdjacent = {}

local adjacent_dialog = nil
local current_bounds = nil
local cell_image = nil
local update_timer = nil
local last_image_data = nil
local last_frame_number = nil
local last_layer_name = nil

local settings = {
    show_grid = false,
    background_color = Color { red = 128, green = 128, blue = 128, alpha = 0 },
    grid_color = Color { red = 64, green = 64, blue = 64 },
    zoom_level = 2
}

function RenderAdjacent.create_command(plugin)
    return plugin:newCommand {
        id = "MCToolkitRenderAdjacent",
        title = "Render Adjacent",
        group = "mc_toolkit_menu_group",
        onenabled = function()
            return app.activeSprite ~= nil and SelectionUtils.is_valid_cell_selection()
        end,
        onclick = function()
            RenderAdjacent.show_dialog()
        end
    }
end

function RenderAdjacent.show_dialog()
    current_bounds = SelectionUtils.get_current_cell_selection()
    if not current_bounds then
        app.alert("Please select a 16x16 cell for adjacent rendering")
        return
    end

    cell_image = SelectionUtils.create_cell_image(current_bounds)
    if not cell_image then
        app.alert("Cannot create image from selection")
        return
    end

    if adjacent_dialog then
        RenderAdjacent.stop_update_timer()
        adjacent_dialog:close()
        adjacent_dialog = nil
    end

    adjacent_dialog = Dialog("Render Adjacent - " .. current_bounds.width .. "x" .. current_bounds.height .. " cell [" .. current_bounds.x .. "," .. current_bounds.y .. "]")

    local cell_size = Constants.GRID_SIZE * settings.zoom_level
    local canvas_size = cell_size * 3

    adjacent_dialog:canvas {
        id = "adjacent_canvas",
        width = canvas_size,
        height = canvas_size,
        onpaint = function(ev)
            RenderAdjacent.draw_adjacent_grid(ev.context)
        end
    }

    adjacent_dialog:newrow()

    adjacent_dialog:label { text = "Display settings" }
    adjacent_dialog:newrow()

    adjacent_dialog:slider {
        id = "zoom_level",
        label = "Zoom:",
        min = 1,
        max = 8,
        value = settings.zoom_level,
        onchange = function()
            settings.zoom_level = adjacent_dialog.data.zoom_level
            RenderAdjacent.show_dialog()
        end
    }

    adjacent_dialog:check {
        id = "show_grid",
        text = "Show grid",
        selected = settings.show_grid,
        onclick = function()
            settings.show_grid = adjacent_dialog.data.show_grid
            adjacent_dialog:repaint()
        end
    }

    adjacent_dialog:newrow()

    adjacent_dialog:color {
        id = "background_color",
        label = "Background color:",
        color = settings.background_color,
        onchange = function()
            settings.background_color = adjacent_dialog.data.background_color
            adjacent_dialog:repaint()
        end
    }

    adjacent_dialog:color {
        id = "grid_color",
        label = "Grid color:",
        color = settings.grid_color,
        onchange = function()
            settings.grid_color = adjacent_dialog.data.grid_color
            adjacent_dialog:repaint()
        end
    }

    adjacent_dialog:newrow()

    adjacent_dialog:button {
        id = "manual_update",
        text = "Manual Update",
        onclick = function()
            local updated_bounds = SelectionUtils.get_current_cell_selection()
            if updated_bounds then
                current_bounds = updated_bounds
                cell_image = SelectionUtils.create_cell_image(current_bounds)
                if cell_image then
                    last_image_data = RenderAdjacent.get_image_data(cell_image)
                    adjacent_dialog:modify{
                        title = "Render Adjacent - " .. current_bounds.width .. "x" .. current_bounds.height .. " cell [" .. current_bounds.x .. "," .. current_bounds.y .. "]"
                    }
                    adjacent_dialog:repaint()
                end
            else
                app.alert("Please select a 16x16 cell for adjacent rendering")
            end
        end
    }

    adjacent_dialog:newrow()

    adjacent_dialog:button {
        id = "save_as_sprite",
        text = "Save as sprite",
        onclick = function()
            RenderAdjacent.save_as_new_sprite()
        end
    }

    adjacent_dialog:button {
        id = "copy_to_clipboard",
        text = "Copy to clipboard",
        onclick = function()
            RenderAdjacent.copy_to_clipboard()
        end
    }

    adjacent_dialog:button {
        id = "close",
        text = "Close",
        onclick = function()
            RenderAdjacent.stop_update_timer()
            adjacent_dialog:close()
            adjacent_dialog = nil
        end
    }

    adjacent_dialog:show{wait=false}

    RenderAdjacent.start_update_timer()
end

function RenderAdjacent.draw_adjacent_grid(ctx)
    local cell_size = Constants.GRID_SIZE * settings.zoom_level

    ctx.color = settings.background_color
    ctx:fillRect(Rectangle(0, 0, ctx.width, ctx.height))

    for grid_y = 0, 2 do
        for grid_x = 0, 2 do
            local start_x = grid_x * cell_size
            local start_y = grid_y * cell_size

            for y = 0, Constants.GRID_SIZE - 1 do
                for x = 0, Constants.GRID_SIZE - 1 do
                    local pixel = cell_image:getPixel(x, y)
                    if pixel ~= 0 then
                        local color = Color(pixel)
                        ctx.color = color

                        local pixel_x = start_x + x * settings.zoom_level
                        local pixel_y = start_y + y * settings.zoom_level
                        ctx:fillRect(Rectangle(pixel_x, pixel_y, settings.zoom_level, settings.zoom_level))
                    end
                end
            end
        end
    end

    if settings.show_grid then
        ctx.color = settings.grid_color
        ctx.strokeWidth = 1

        for i = 1, 2 do
            local x = i * cell_size
            ctx:beginPath()
            ctx:moveTo(x, 0)
            ctx:lineTo(x, ctx.height)
            ctx:stroke()
        end

        for i = 1, 2 do
            local y = i * cell_size
            ctx:beginPath()
            ctx:moveTo(0, y)
            ctx:lineTo(ctx.width, y)
            ctx:stroke()
        end

        ctx:beginPath()
        ctx:moveTo(0, 0)
        ctx:lineTo(ctx.width, 0)
        ctx:lineTo(ctx.width, ctx.height)
        ctx:lineTo(0, ctx.height)
        ctx:closePath()
        ctx:stroke()
    end
end

function RenderAdjacent.create_adjacent_image()
    local cell_size = Constants.GRID_SIZE
    local total_size = cell_size * 3
    local result_image = Image(total_size, total_size, cell_image.colorMode)

    for grid_y = 0, 2 do
        for grid_x = 0, 2 do
            local start_x = grid_x * cell_size
            local start_y = grid_y * cell_size

            for y = 0, Constants.GRID_SIZE - 1 do
                for x = 0, Constants.GRID_SIZE - 1 do
                    local pixel = cell_image:getPixel(x, y)
                    result_image:putPixel(start_x + x, start_y + y, pixel)
                end
            end
        end
    end

    return result_image
end

function RenderAdjacent.save_as_new_sprite()
    local adjacent_image = RenderAdjacent.create_adjacent_image()
    local cell_size = Constants.GRID_SIZE
    local total_size = cell_size * 3

    local new_sprite = Sprite(total_size, total_size, cell_image.colorMode)
    new_sprite.cels[1].image = adjacent_image

    if app.activeSprite and app.activeSprite.colorMode == ColorMode.INDEXED then
        new_sprite:setPalette(app.activeSprite.palettes[1])
    end

    app.alert("New sprite with 3x3 texture grid created")
end

function RenderAdjacent.copy_to_clipboard()
    local adjacent_image = RenderAdjacent.create_adjacent_image()

    local temp_sprite = Sprite(adjacent_image.width, adjacent_image.height, adjacent_image.colorMode)
    temp_sprite.cels[1].image = adjacent_image

    temp_sprite.selection = Rectangle(0, 0, adjacent_image.width, adjacent_image.height)
    app.command.Copy()

    temp_sprite:close()

    app.alert("Image copied to clipboard")
end

function RenderAdjacent.check_for_updates()
    if not adjacent_dialog or not current_bounds then
        return false
    end

    local sprite = app.activeSprite
    if not sprite then
        return false
    end

    local cel = app.activeCel
    if not cel then
        return false
    end

    local current_frame = app.activeFrame.frameNumber
    local current_layer = app.activeLayer.name
    local frame_or_layer_changed = (current_frame ~= last_frame_number) or (current_layer ~= last_layer_name)

    local selection_changed = false
    local new_bounds = SelectionUtils.get_current_cell_selection()
    if new_bounds and current_bounds and (
        current_bounds.x ~= new_bounds.x or
        current_bounds.y ~= new_bounds.y) then
        current_bounds = new_bounds
        selection_changed = true
    end

    local new_cell_image = RenderAdjacent.create_cell_image_from_bounds(current_bounds)
    if not new_cell_image then
        return false
    end

    local new_image_data = RenderAdjacent.get_image_data(new_cell_image)
    if new_image_data ~= last_image_data or frame_or_layer_changed or selection_changed then
        cell_image = new_cell_image
        last_image_data = new_image_data
        last_frame_number = current_frame
        last_layer_name = current_layer

        if selection_changed and adjacent_dialog then
            adjacent_dialog:modify{
                title = "Render Adjacent - " .. current_bounds.width .. "x" .. current_bounds.height .. " cell [" .. current_bounds.x .. "," .. current_bounds.y .. "]"
            }
        end

        return true
    end

    return false
end

function RenderAdjacent.create_cell_image_from_bounds(bounds)
    local sprite = app.activeSprite
    if not sprite then return nil end

    local cel = app.activeCel
    if not cel then return nil end

    local image = cel.image
    local cell_image = Image(Constants.GRID_SIZE, Constants.GRID_SIZE, image.colorMode)

    for y = 0, Constants.GRID_SIZE - 1 do
        for x = 0, Constants.GRID_SIZE - 1 do
            local src_x = bounds.x + x
            local src_y = bounds.y + y

            if src_x >= 0 and src_x < image.width and src_y >= 0 and src_y < image.height then
                local pixel = image:getPixel(src_x, src_y)
                cell_image:putPixel(x, y, pixel)
            end
        end
    end

    return cell_image
end

function RenderAdjacent.get_image_data(image)
    local data = ""
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            data = data .. tostring(image:getPixel(x, y)) .. ","
        end
    end
    return data
end

function RenderAdjacent.start_update_timer()
    RenderAdjacent.stop_update_timer()

    if cell_image then
        last_image_data = RenderAdjacent.get_image_data(cell_image)
    end

    if app.activeFrame and app.activeLayer then
        last_frame_number = app.activeFrame.frameNumber
        last_layer_name = app.activeLayer.name
    end

    update_timer = Timer{
        interval = 0.01,
        ontick = function()
            if RenderAdjacent.check_for_updates() then
                if adjacent_dialog then
                    adjacent_dialog:repaint()
                end
            end
        end
    }
    update_timer:start()
end

function RenderAdjacent.stop_update_timer()
    if update_timer then
        update_timer:stop()
        update_timer = nil
    end
    last_image_data = nil
    last_frame_number = nil
    last_layer_name = nil
end

function RenderAdjacent.stop_all_timers()
    RenderAdjacent.stop_update_timer()
    if adjacent_dialog then
        adjacent_dialog:close()
        adjacent_dialog = nil
    end
end

return RenderAdjacent