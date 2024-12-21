local Objects = require "objects"

local Tile = Objects:new()

function Tile:init(gm, x, y, img)
    self.gm = gm
    self.tag = "tile"
    self.col = true

    self.x = x
    self.y = y
    self.w = TILE_SIZE
    self.h = TILE_SIZE

    self.img = img
end

function Tile:draw()
    love.graphics.draw(self.img, self.x, self.y)
end

return Tile