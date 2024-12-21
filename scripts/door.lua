local Objects = require "objects"
local Particle = require "scripts.particle"

local Door = Objects:new()

function Door:init(gm, x, y, img)
    self.gm = gm
    self.tag = "door"
    self.col = true

    self.x = x
    self.y = y
    self.w = TILE_SIZE
    self.h = TILE_SIZE

    self.img = img
end

function Door:draw()
    if self.gm.index == 2 then
        love.graphics.draw(self.img, self.x, self.y+math.sin(love.timer.getTime()*5)*3)
    else
        love.graphics.draw(self.img, self.x, self.y)
    end
end

function Door:update(dt)
    local col = self.gm:check(self)
    if col then
        if col.tag == "player" then
            self.gm:clear()
            self.gm:remove(self)
            self.gm:shake(7)
            for _ = 0, 5 do
                self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2, {1, 1, 1, 0.8}, math.random(-10, 10), math.random(-10, 10), math.random(20, 30))
            end
        end
    end 
end

return Door