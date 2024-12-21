local Objects = require "objects"

local Particle = Objects:new()

function Particle:init(gm, x, y, color, vx, vy, size)
    self.gm = gm
    self.tag = "particle"
    self.col = false

    self.x = x
    self.y = y
    self.w = 0
    self.h = 0

    self.color = color

    self.vx = vx
    self.vy = vy

    self.size = size
end

function Particle:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1)
end

function Particle:update(dt)
    self.size = self.size + (0 - self.size)/10*dt
    if self.size < 0.1 then
        self.gm:remove(self)
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy

    self.vx = self.vx + (0 - self.vx)/5*dt
    self.vy = self.vy + (0 - self.vy)/5*dt
end

return Particle