local Objects = require "objects"

local Lava = Objects:new()

local speed = 1.65

function Lava:init(gm)
    self.gm = gm
    self.tag = "spike"
    self.col = true
    
    self.delay_time = 25
    self.delay_timer = 0

    self.w = MAP_SIZE
    self.h = MAP_SIZE
    self.x = 0
    self.y = 20 + MAP_SIZE
end

function Lava:draw()
    love.graphics.setColor(rgb(255, 89, 89))
    love.graphics.rectangle("fill", self.x, self.y - 20, self.w, self.h)
    love.graphics.setColor(1, 1, 1)
end

function Lava:update(dt)
    self.delay_timer = self.delay_timer + dt
    if self.delay_timer > self.delay_time then
        self.y = self.y - speed*dt
        local cols = self.gm:check(self)
        for i, col in ipairs(cols) do
            if col.tag == "player" then
                col:die()
            end
        end
    end
end

return Lava