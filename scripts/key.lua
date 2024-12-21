local Objects = require "objects"
local Particle = require "scripts.particle"

local Key = Objects:new()

function Key:init(gm, x, y, img)
    self.gm = gm
    self.tag = "key"
    self.col = true

    self.x = x
    self.y = y
    self.w = TILE_SIZE
    self.h = TILE_SIZE

    self.img = img
end

function Key:draw()
    love.graphics.draw(self.img, self.x, self.y+math.sin(love.timer.getTime()*5)*3)
end

function Key:update(dt)
    local col = self.gm:check(self)
    if col then
        if col.tag == "player" then
            col:grab_key()
            self.gm:remove(self)
            for _ = 0, 5 do
                self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2, {1, 1, 1, 0.8}, math.random(-10, 10), math.random(-10, 10), math.random(20, 30))
            end
        end
    end 
end

return Key