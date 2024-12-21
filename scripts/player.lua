require "consts"
local Objects = require "objects"
local Particle = require "scripts.particle"

local Player = Objects:new()
local base_gravity = 1.2

local filters = {"key", "spike", "door"}

function Player:init(gm, x, y, img)
    self.gm = gm
    self.tag = "player"
    self.col = true

    self.img = img
    
    self.x = x
    self.mx = 0

    self.y = y
    self.vy = 0
    self.max_vy = 18
    
    self.w, self.h = self.img:getDimensions()
    
    self.speed = 4.8
    self.air_speed_mult = 1.15

    self.jump_force = 13
    self.gravity = 0
    self.air_gravity_mult = 0.5

    self.falling = 999
    self.falling_thresh = 5
    self.jump_buffer = 999
    self.jump_buffer_thresh = 10

    self.acc = 5
    self.dec = 2

    self.has_key = false

    self.particle_time = 5
    self.particle_timer = 0
end

function Player:update(dt)
    local ix = 0
    if love.keyboard.isDown("left") and not love.keyboard.isDown("right") then
        ix = -1
    end
    if love.keyboard.isDown("right") and not love.keyboard.isDown("left") then
        ix = 1
    end
    
    if self.falling < self.falling_thresh then
        if ix ~= 0 then
            self.mx = self.mx+(ix-self.mx)/self.acc*dt
        else
            self.mx = self.mx+(0-self.mx)/self.dec*dt
        end
    else
        if ix ~= 0 then
            self.mx = self.mx+(ix-self.mx)/self.acc/2*dt
        else
            self.mx = self.mx+(0-self.mx)/self.dec/2*dt
        end
    end

    if ix ~= 0 and self.falling < self.falling_thresh then
        if self.particle_timer > self.particle_time then
            self.particle_timer = 0
            self.gm:add(Particle, self.x + self.w/2, self.y + self.h, {0.2, 0.2, 0.2, 0.8}, -ix*math.random(0, 10), math.random(-5, -1), math.random(5, 10))
        end
        self.particle_timer = self.particle_timer + dt
    end

    local air = 1
    if self.falling > self.falling_thresh then
        air = self.air_speed_mult
    end
    
    self.gm:move_x(self, self.mx*self.speed*air*dt, filters)
    
    self.vy = self.vy+dt*self.gravity
    
    if self.gm:move_y(self, self.vy*dt, filters) then
        if self.vy > 0 then
            self.falling = 0
        end
        self.vy = 0
    end

    self.falling = self.falling+dt
    self.jump_buffer = self.jump_buffer+dt

    if self.jump_buffer < self.jump_buffer_thresh then
        if self.falling < self.falling_thresh then
            self:jump()
        end
    end

    if love.keyboard.isDown("space") then
        self.gravity = base_gravity*self.air_gravity_mult
    else
        self.gravity = base_gravity
    end

    self.vy = math.min(self.vy, self.max_vy)
end

function Player:draw()
    love.graphics.draw(self.img, self.x, self.y)
end

function Player:keypressed(key)
    if key == "space" then
        if self.falling < self.falling_thresh then
            self:jump()
        end
        self.jump_buffer = 0
    end
end

function Player:jump()
    self.vy = -self.jump_force
    self.falling = 999
    self.jump_buffer = 999
    for _ = 0, 2 do
        self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2, {1, 1, 1, 0.8}, math.random(-10, 10), math.random(0, 10), math.random(15, 20))
    end
end

function Player:die()
    for _ = 0, 5 do
        self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2, rgba(243, 53, 53, 0.8), math.random(-10, 10), math.random(-10, 10), math.random(20, 30))
    end
    self.gm:remove(self)
    self.gm:restart()
    self.gm:shake(10)
end

function Player:grab_key()
    self.has_key = true
    self.gm:key_obtained()
    self.gm:shake(3)
end

return Player