require "consts"
local Objects = require "objects"
local Particle = require "scripts.particle"

local Player = Objects:new()
local base_gravity = 1.2

local filters = {"key", "spike", "door"}

local w, h

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
    w, h = self.w, self.h
    
    self.speed = 4.8
    self.air_speed_mult = 1.15

    self.jump_force = 13
    self.gravity = 0
    self.air_gravity_mult = 0.5
    if self.gm.index == 10 then
        self.air_gravity_mult = 0.6
    end

    self.falling = 999
    self.falling_thresh = 5
    self.jump_buffer = 999
    self.jump_buffer_thresh = 10

    self.acc = 5
    self.dec = 2
    if self.gm.index == 8 then
        self.acc = self.acc*6
        self.dec = self.dec*6
    end

    self.has_key = false

    self.particle_time = 5
    self.particle_timer = 0

    self.landed = false

    self.size = 1

    self.g = 1
end

function Player:update(dt)
    local ix = 0
    if love.keyboard.isDown("left") and not love.keyboard.isDown("right") then
        ix = -1
    end
    if love.keyboard.isDown("right") and not love.keyboard.isDown("left") then
        ix = 1
    end
    
    local wx = 0
    if self.gm.index == 9 then
        wx = -0.3
    end

    if self.falling < self.falling_thresh then
        if ix ~= 0 then
            self.mx = self.mx+(ix+wx-self.mx)/self.acc*dt
        else
            self.mx = self.mx+(wx-self.mx)/self.dec*dt
        end
    else
        if ix ~= 0 then
            self.mx = self.mx+(ix+wx-self.mx)/self.acc/2*dt
        else
            self.mx = self.mx+(wx-self.mx)/self.dec/2*dt
        end
    end

    if ix ~= 0 and self.falling < self.falling_thresh then
        if self.particle_timer > self.particle_time then
            self.particle_timer = 0
            self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2 + self.h*self.g/2, rgba(71, 87, 98, 0.8), -ix*math.random(0, 10), math.random(-5, -1), math.random(5, 10))
            self.gm:play_sound("walk")
        end
        self.particle_timer = self.particle_timer + dt
    end

    local air = 1
    if self.falling > self.falling_thresh then
        air = self.air_speed_mult
    end
    
    self.gm:move_x(self, self.mx*self.speed*air*dt, filters)
    
    self.vy = self.vy+dt*self.gravity*self.g
    
    if self.gm:move_y(self, self.vy*dt, filters) then
        if self.vy*self.g > 0 then
            self.falling = 0
        end
        self.vy = 0
    end

    self.falling = self.falling+dt
    self.jump_buffer = self.jump_buffer+dt

    if self.gm.index ~= 7 then
        
        if self.jump_buffer < self.jump_buffer_thresh then
            if self.falling < self.falling_thresh then
                self:jump()
            end
        end
    end

    local moon_gravity = 1
    if self.gm.index == 10 then
        moon_gravity = 2.6
    end

    if love.keyboard.isDown("space") then
        self.gravity = base_gravity/moon_gravity*self.air_gravity_mult
    else
        self.gravity = base_gravity/moon_gravity
    end

    self.vy = math.min(self.vy, self.max_vy)

    if self.falling < self.falling_thresh and not self.landed then
        self.landed = true
        self.gm:play_sound("land")
    elseif self.falling > self.falling_thresh*2 then
        self.landed = false
    end
end

function Player:draw()
    love.graphics.draw(self.img, self.x, self.y, 0, self.size, self.size)
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
    if self.gm.index == 7 then
        self.g = -self.g
    else
        self.vy = -self.jump_force*self.g
        self.falling = 999
        self.jump_buffer = 999
        for _ = 0, 2 do
            self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2, {1, 1, 1, 0.8}, math.random(-10, 10), math.random(0, 10), math.random(15, 20))
        end
        self.gm:play_sound("jump")
    
        if self.gm.index == 5 then
            self.size = self.size - 0.2
            if self.size < 0.2 then
                self:die()
            end
            self.w = w*self.size
            self.h = h*self.size
            self.jump_force = self.jump_force + 3
            self.speed = self.speed + 1
        end
    end
end

function Player:die()
    for _ = 0, 5 do
        self.gm:add(Particle, self.x + self.w/2, self.y + self.h/2, rgba(243, 53, 53, 0.8), math.random(-10, 10), math.random(-10, 10), math.random(20, 30))
    end
    self.gm:remove(self)
    self.gm:restart()
    self.gm:shake(10)
    self.gm:play_sound("death")
end

function Player:grab_key() 
    self.has_key = true
    self.gm:key_obtained()
    self.gm:shake(3)
    self.gm:play_sound("key")
end

return Player