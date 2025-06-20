
local MathUtils = {}

function MathUtils.round(number)
    return math.floor(number + 0.5)
end

function MathUtils.rotate3D(block, pitch, yaw, roll)
    for i, point in ipairs(block) do
        local x = point[1]
        local y = point[2]
        local z = point[3]

        local cosa = math.cos(yaw)
        local sina = math.sin(yaw)
        local cosb = math.cos(pitch)
        local sinb = math.sin(pitch)
        local cosc = math.cos(roll)
        local sinc = math.sin(roll)

        local Axx = cosa * cosb
        local Axy = cosa * sinb * sinc - sina * cosc
        local Axz = cosa * sinb * cosc + sina * sinc

        local Ayx = sina * cosb
        local Ayy = sina * sinb * sinc + cosa * cosc
        local Ayz = sina * sinb * cosc - cosa * sinc

        local Azx = sinb * -1
        local Azy = cosb * sinc
        local Azz = cosb * cosc

        block[i][1] = Axx * x + Axy * y + Axz * z
        block[i][2] = Ayx * x + Ayy * y + Ayz * z
        block[i][3] = Azx * x + Azy * y + Azz * z
    end
end

function MathUtils.makeCube(x, y, z, scale)
    scale = scale or 1
    x = x * scale
    y = y * scale
    z = z * scale
    return {
        { (x / 2) * -1, (y / 2) * -1, (z / 2) * -1 },
        { (x / 2) * 1, (y / 2) * -1, (z / 2) * -1 },
        { (x / 2) * 1, (y / 2) * 1, (z / 2) * -1 },
        { (x / 2) * -1, (y / 2) * 1, (z / 2) * -1 },
        { (x / 2) * -1, (y / 2) * -1, (z / 2) * 1 },
        { (x / 2) * 1, (y / 2) * -1, (z / 2) * 1 },
        { (x / 2) * 1, (y / 2) * 1, (z / 2) * 1 },
        { (x / 2) * -1, (y / 2) * 1, (z / 2) * 1 }
    }
end

function MathUtils.calcPixel(points, canvas, x, y)
    local widthRatio = x / canvas.width
    local heightRatio = y / canvas.height

    local xDiff1 = points[2][1] - points[1][1]
    local yDiff1 = points[2][2] - points[1][2]
    local xDiff2 = points[3][1] - points[1][1]
    local yDiff3 = points[3][2] - points[1][2]

    local resultX = points[1][1] + xDiff1 * widthRatio + xDiff2 * heightRatio
    local resultY = points[1][2] + yDiff3 * heightRatio + yDiff1 * widthRatio

    return { resultX, resultY }
end

return MathUtils