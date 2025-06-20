
local Constants = load_mc_module("core/constants.lua")
local MathUtils = load_mc_module("core/math_utils.lua")
local SelectionUtils = load_mc_module("core/selection_utils.lua")
local BackgroundRenderer = load_mc_module("ui/background_renderer.lua")

local Render3D = {}

local cube = { Constants.DEFAULT_CUBE_SIZE[1], Constants.DEFAULT_CUBE_SIZE[2], Constants.DEFAULT_CUBE_SIZE[3] }
local pitch = Constants.DEFAULT_PITCH
local roll = Constants.DEFAULT_ROLL
local scale = Constants.DEFAULT_SCALE
local spin = Constants.DEFAULT_ROTATE_SPEED
local render_active = false
local render_dialog = nil
local drag = 0
local px, py = 0, 0
local current_bounds = nil
local cell_image = nil
local block = nil

function Render3D.create_command(plugin)
    return plugin:newCommand {
        id = "MCToolkit3D",
        title = "3D Render",
        group = "mc_toolkit_menu_group",
        onenabled = function()
            return app.activeSprite ~= nil and SelectionUtils.is_valid_cell_selection()
        end,
        onclick = function()
            Render3D.show_dialog()
        end
    }
end

function Render3D.show_dialog()
    local bounds = SelectionUtils.get_current_cell_selection()
    if not bounds then
        app.alert("Please select a 16x16 cell for 3D rendering")
        return
    end

    cell_image = SelectionUtils.create_cell_image(bounds)
    if not cell_image then
        app.alert("Cannot create image from selection")
        return
    end

    if render_dialog then
        render_dialog:close()
    end

    local connect_points = {
        { { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 } },
        { { 5, 1 }, { 1, 4 }, { 4, 8 }, { 8, 5 } },
        { { 4, 3 }, { 3, 7 }, { 7, 8 }, { 8, 4 } },
        { { 6, 5 }, { 5, 8 }, { 8, 7 }, { 7, 6 } },
        { { 5, 6 }, { 6, 2 }, { 2, 1 }, { 1, 5 } },
        { { 2, 6 }, { 6, 7 }, { 7, 3 }, { 3, 2 } }
    }

    render_active = true
    current_bounds = bounds
    drag = 0
    spin = Constants.DEFAULT_ROTATE_SPEED

    block = MathUtils.makeCube(cube[1], cube[2], cube[3], scale)
    MathUtils.rotate3D(block, pitch * math.pi / 180, 0, 0)
    MathUtils.rotate3D(block, 0, 0, roll * math.pi / 180)

    render_dialog = Dialog("3D Block Render - " .. bounds.width .. "x" .. bounds.height .. " cell")

    render_dialog:canvas {
        id = "canvas",
        width = Constants.CANVAS_SIZE,
        height = Constants.CANVAS_SIZE,
        onpaint = function(ev)
            local ctx = ev.context
            local cx, cy = ctx.width / 2, ctx.height / 2

            local bg_color = render_dialog and render_dialog.data.backgroundColor or Color { red = 220, green = 220, blue = 220 }
            ctx.color = bg_color
            ctx:fillRect(Rectangle(0, 0, ctx.width, ctx.height))

            local remap = {}
            for i, face in ipairs(connect_points) do
                local z = (block[face[1][1]][3] + block[face[2][1]][3] + block[face[3][1]][3] + block[face[4][1]][3]) / 4
                if z < 0 then
                    remap[#remap + 1] = face
                end
            end

            table.sort(remap, function(a, b)
                local za = (block[a[1][1]][3] + block[a[2][1]][3] + block[a[3][1]][3] + block[a[4][1]][3]) / 4
                local zb = (block[b[1][1]][3] + block[b[2][1]][3] + block[b[3][1]][3] + block[b[4][1]][3]) / 4
                return za < zb
            end)

            ctx.strokeWidth = 0
            for y = 0, cell_image.height - 1 do
                for x = 0, cell_image.width - 1 do
                    local pixel = cell_image:getPixel(x, y)
                    if pixel ~= 0 then
                        local color = Color(pixel)
                        ctx.color = color

                        for _, face in ipairs(remap) do
                            ctx:beginPath()
                            local points = { block[face[1][1]], block[face[2][1]], block[face[4][1]] }

                            local pixelXY = MathUtils.calcPixel(points, cell_image, x, y)
                            ctx:moveTo(pixelXY[1] + cx, pixelXY[2] + cy)

                            pixelXY = MathUtils.calcPixel(points, cell_image, x + 1, y)
                            ctx:lineTo(pixelXY[1] + cx, pixelXY[2] + cy)

                            pixelXY = MathUtils.calcPixel(points, cell_image, x + 1, y + 1)
                            ctx:lineTo(pixelXY[1] + cx, pixelXY[2] + cy)

                            pixelXY = MathUtils.calcPixel(points, cell_image, x, y + 1)
                            ctx:lineTo(pixelXY[1] + cx, pixelXY[2] + cy)

                            ctx:closePath()
                            ctx:fill()
                        end
                    end
                end
            end
        end,
        onmousedown = function(ev)
            drag = 1
            spin = 0
            px = ev.x
            py = ev.y
        end,
        onmouseup = function(ev)
            drag = 0
            spin = render_dialog.data.spin
        end,
        onmousemove = function(ev)
            if drag == 1 then
                roll = (roll + (ev.y - py)) % 360
                pitch = (pitch + ((px - ev.x) * math.cos(roll * math.pi / 180))) % 360

                block = MathUtils.makeCube(cube[1], cube[2], cube[3], scale)
                MathUtils.rotate3D(block, pitch * math.pi / 180, 0, 0)
                MathUtils.rotate3D(block, 0, 0, roll * math.pi / 180)

                render_dialog:repaint()
                px = ev.x
                py = ev.y
            end
        end,
        onwheel = function(ev)
            scale = math.max(0.1, scale - (ev.deltaY / 10))
            block = MathUtils.makeCube(cube[1], cube[2], cube[3], scale)
            MathUtils.rotate3D(block, pitch * math.pi / 180, 0, 0)
            MathUtils.rotate3D(block, 0, 0, roll * math.pi / 180)
            render_dialog:repaint()
        end
    }

    render_dialog:color {
        id = "backgroundColor",
        label = "Background color:",
        color = Color { red = 220, green = 220, blue = 220 },
        onchange = function()
            render_dialog:repaint()
        end
    }

    render_dialog:newrow()

    render_dialog:slider {
        id = "spin",
        label = "Auto rotate speed:",
        min = 0,
        max = 10,
        value = spin,
        onchange = function()
            spin = render_dialog.data.spin
        end
    }

    render_dialog:button {
        text = "Manual Update",
        onclick = function()
            local updated_bounds = SelectionUtils.get_current_cell_selection()
            if updated_bounds then
                current_bounds = updated_bounds
                cell_image = SelectionUtils.create_cell_image(current_bounds)
                render_dialog:repaint()
            end
        end
    }

    render_dialog:button {
        text = "Reset",
        onclick = function()
            pitch = Constants.DEFAULT_PITCH
            roll = Constants.DEFAULT_ROLL
            scale = Constants.DEFAULT_SCALE
            spin = Constants.DEFAULT_ROTATE_SPEED
            cube = { Constants.DEFAULT_CUBE_SIZE[1], Constants.DEFAULT_CUBE_SIZE[2], Constants.DEFAULT_CUBE_SIZE[3] }
            block = MathUtils.makeCube(cube[1], cube[2], cube[3], scale)
            MathUtils.rotate3D(block, pitch * math.pi / 180, 0, 0)
            MathUtils.rotate3D(block, 0, 0, roll * math.pi / 180)
            render_dialog:modify{id = "spin", value = spin}
            render_dialog:repaint()
        end
    }

    render_dialog:button {
        text = "Close",
        onclick = function()
            render_active = false
            render_dialog:close()
            render_dialog = nil
        end
    }

    render_dialog:show { wait = false }
end

function Render3D.start_global_timer()
    Timer {
        interval = 0.01,
        ontick = function()
            if render_active and render_dialog then
                local new_bounds = SelectionUtils.get_current_cell_selection()
                if new_bounds and current_bounds and (
                    current_bounds.x ~= new_bounds.x or
                    current_bounds.y ~= new_bounds.y) then
                    current_bounds = new_bounds
                    cell_image = SelectionUtils.create_cell_image(current_bounds)
                end

                if spin ~= 0 then
                    pitch = (pitch - (spin / 8)) % 360
                    block = MathUtils.makeCube(cube[1], cube[2], cube[3], scale)
                    MathUtils.rotate3D(block, pitch * math.pi / 180, 0, 0)
                    MathUtils.rotate3D(block, 0, 0, roll * math.pi / 180)
                    render_dialog:repaint()
                end
            end
        end
    }:start()
end

return Render3D