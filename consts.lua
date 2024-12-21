SCREEN_W, SCREEN_H = 1280, 720

TILE_SIZE = 45
MAP_SIZE = SCREEN_H

function Init()
    FONT = love.graphics.newFont("data/fonts/Galmuri9.ttf", 40)
end

function rgb(r, g, b)
    return {r/255, g/255, b/255}
end

function rgba(r, g, b, a)
    return {r/255, g/255, b/255, a}
end