local Objects = require "objects"

local Spike = Objects:new()

local spike_size = 40
local spike_actual_size = 20

function Spike:init(gm, x, y, img)
    self.gm = gm
    self.tag = "spike"
    self.col = true
    
    self.w = spike_actual_size
    self.h = spike_actual_size
    self.x = x+TILE_SIZE/2-spike_actual_size/2
    self.y = y+TILE_SIZE-spike_actual_size
    
    self.img = img
end

function Spike:draw()
    love.graphics.draw(self.img, self.x, self.y, 0, 1, 1, -spike_actual_size/2 + spike_size/2, -spike_actual_size + spike_size)
end

function Spike:update(dt)
    local cols = self.gm:check(self)
    for i, col in ipairs(cols) do
        if col.tag == "player" then
            col:die()
        end 
    end
end

return Spike