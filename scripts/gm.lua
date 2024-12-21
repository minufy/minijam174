local function check_collision(a, b)
    return a.x < b.x+b.w and
            b.x < a.x+a.w and
            a.y < b.y+b.h and
            b.y < a.y+a.h
end

local function draw_background()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setColor(rgb(236, 239, 244))
    love.graphics.rectangle("fill", 0, 0, MAP_SIZE, MAP_SIZE)
    local grid_size = TILE_SIZE*2
    local move = love.timer.getTime()*50%(2*grid_size)
    love.graphics.setLineWidth(grid_size/1.5)
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = -(4*grid_size), SCREEN_W, grid_size do
        love.graphics.line(i + move, 0, i + move + grid_size, SCREEN_H)
    end
end

local function ease_out(x)
    return 1 - (1 - x)^2
end

local Objects = require "objects"
local Particle = require "scripts.particle"

local Player = require "scripts.player"
local player_img
local Tile = require "scripts.tile"
local tile_img
local tile_top_img
local Spike = require "scripts.spike"
local spike_img
local Key = require "scripts.key"
local key_img
local Door = require "scripts.door"
local door_img
local Lava = require "scripts.lava"

local controls_img

local wall = {
    tag = "wall"
}

local twists = {
    {"nothing", false},
    {"door is you, key is win", true},
    {"floor is lava", false},
}

local sound_names = {{"death", 0.5}, {"jump", 0.5}, {"key", 0.5}, {"clear", 0.5}, {"woosh", 0.4}, {"walk", 0.2}, {"land", 0.5}}
local sounds = {}
local music

local GM = Objects:new()

function GM:add(object, ...)
    local o = object:new()
    o:init(self, ...)
    table.insert(self.objects, o)
    return o
end

function GM:remove(object)
    for i, o in ipairs(self.objects) do
        if o == object then
            table.remove(self.objects, i)
            return
        end
    end
end

function GM:init()
    player_img = love.graphics.newImage("data/imgs/player.png")
    tile_img = love.graphics.newImage("data/imgs/tile.png")
    tile_top_img = love.graphics.newImage("data/imgs/tile_top.png")
    spike_img = love.graphics.newImage("data/imgs/spike.png")
    key_img = love.graphics.newImage("data/imgs/key.png")
    door_img = love.graphics.newImage("data/imgs/door.png")
    controls_img = love.graphics.newImage("data/imgs/controls.png")

    for i, sound_name in ipairs(sound_names) do
        sounds[sound_name[1]] = love.audio.newSource("data/audio/"..sound_name[1]..".ogg", "static")
        sounds[sound_name[1]]:setVolume(sound_name[2])
    end

    music = love.audio.newSource("data/audio/music.ogg", "stream")
    music:setVolume(0.2)
    music:play()
    music:setLooping(true)

    self.objects = {}
    self.player = nil
    self.index = 1
    self:load_level()

    self.fade_in_time = 30
    self.fade_in_timer = 0
    self.fading_in = false
    
    self.fade_out_time = 20
    self.fade_out_timer = 0
    self.fading_out = false

    self.shake_dur = 0
    self.shake_x = 0
    self.shake_y = 0
end

function GM:update(dt)
    for _, object in ipairs(self.objects) do
        object:update(dt)
    end
    if self.fading_in then
        self.fade_in_timer = self.fade_in_timer + dt
        if self.fade_in_timer > self.fade_in_time then
            self.fade_in_timer = 0
            self.fading_in = false
            self:load_level()
            self:play_sound("woosh")
            self.fading_out = true
        end
    end
    if self.fading_out then
        self.fade_out_timer = self.fade_out_timer + dt
        if self.fade_out_timer > self.fade_out_time then
            self.fade_out_timer = 0
            self.fading_out = false
            self:play_sound("woosh")
        end
    end

    if self.shake_dur > 0.1 then
        self.shake_x = math.random(-self.shake_dur, self.shake_dur)
        self.shake_y = math.random(-self.shake_dur, self.shake_dur)
    end
    self.shake_dur = self.shake_dur + (0-self.shake_dur)/5*dt
end

function GM:draw()
    -- shake

    love.graphics.setColor(1, 1, 1)
    if self.shake_dur > 0.1 then
        love.graphics.translate(self.shake_x, self.shake_y)
    end
    
    draw_background()
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", MAP_SIZE, 0, SCREEN_W-MAP_SIZE, SCREEN_H)
    love.graphics.setColor(1, 1, 1)

    for _, object in ipairs(self.objects) do
        object:draw()
    end

    if self.index == 1 and not self.player.has_key then
        love.graphics.draw(controls_img, 40, 550, 0, 2, 2)
    end

    -- gui 

    love.graphics.setFont(FONT)
    love.graphics.push()
    love.graphics.translate(MAP_SIZE + TILE_SIZE, TILE_SIZE)
    
    love.graphics.setColor(rgb(236, 239, 244))
    if not self.fading_in then
        love.graphics.print("level "..self.index)

        love.graphics.print("twist:", 0, 100)
        love.graphics.print(twists[self.index][1], 0, 160)
    end
    
    love.graphics.pop()

    -- fade in/out
    
    love.graphics.setColor(0, 0, 0)
    if self.fading_in then
        love.graphics.rectangle("fill", 0, 0, MAP_SIZE, ease_out(self.fade_in_timer/self.fade_in_time)*SCREEN_H)
    end
    if self.fading_out then
        love.graphics.rectangle("fill", 0, ease_out(self.fade_out_timer/self.fade_out_time)*SCREEN_H, MAP_SIZE, SCREEN_H)
    end
    love.graphics.setColor(1, 1, 1)
end

function GM:keypressed(key)
    self.player:keypressed(key)
end

function GM:check(a, filters)
    local cols = {}
    if a.col then
        for _, b in ipairs(self.objects) do
            if b.col then
                local filtered = false
                if filters then
                    for i, filter in ipairs(filters) do
                        if b.tag == filter then
                            filtered = true
                            break
                        end
                    end
                end
                if not filtered then
                    if a ~= b and check_collision(a, b) then
                        table.insert(cols, b)
                    end
                end
            end
        end
    end
    return cols
end

function GM:move_x(a, x, filters)
    a.x = a.x+x
    local cols = self:check(a, filters)
    if #cols ~= 0 then
        local c = cols[1]
        if x > 0 then
            a.x = c.x-a.w
        else
            a.x = c.x+c.w
        end
        return c
    end
    if a.x < 0 then
        a.x = 0
        return wall
    end
    if a.x+a.w > MAP_SIZE then
        a.x = MAP_SIZE-a.w
        return wall
    end
    return nil
end

function GM:move_y(a, y, filters)
    a.y = a.y+y
    local cols = self:check(a, filters)
    if #cols ~= 0 then
        local c = cols[1]
        if y > 0 then
            a.y = c.y-a.h
        else
            a.y = c.y+c.h
        end
        return c
    end
    if a.y+a.h > MAP_SIZE then
        a.y = MAP_SIZE-a.h
        return wall
    end
    return nil
end

function GM:load_level()
    self.objects = {}
    local level = require("data.levels.base")
    if twists[self.index][2] then
        level = require("data.levels."..self.index)
    end
    for y, row in ipairs(level) do
        for x = 1, #row do
            local px, py = (x - 1)*TILE_SIZE, (y - 1)*TILE_SIZE
            local tile = row:sub(x, x)
            if tile == "x" then
                if y ~= 1 and level[y - 1]:sub(x, x) ~= "x" then
                    self:add(Tile, px, py, tile_top_img)
                else
                    self:add(Tile, px, py, tile_img)
                end
            elseif tile == "s" then
                self:add(Spike, px, py, spike_img)
            end

            if self.index == 2 then
                if tile == "p" then
                    self.player = self:add(Player, px, py, door_img)
                elseif tile == "d" then
                    self:add(Door, px, py, key_img)
                end
            else
                if tile == "p" then
                    self.player = self:add(Player, px, py, player_img)
                elseif tile == "d" then
                    self.door_x, self.door_y = px, py
                elseif tile == "k" then
                    self:add(Key, px, py, key_img)
                end
            end
        end
    end
    if self.index == 3 then
        self:add(Lava)
    end
end

function GM:next(x)
    self.index = math.min(#twists, self.index + x)
end

function GM:clear()
    self:next(1)
    self.fading_in = true
    self:play_sound("clear")
end

function GM:key_obtained()
    self:add(Door, self.door_x, self.door_y, door_img)
    for _ = 0, 5 do
        self:add(Particle, self.door_x + TILE_SIZE/2, self.door_y + TILE_SIZE/2, {1, 1, 1, 0.8}, math.random(-10, 10), math.random(-10, 10), math.random(20, 30))
    end
end

function GM:restart()
    self.fading_in = true
end

function GM:shake(dur)
    self.shake_dur = dur
end

function GM:play_sound(sound_name)
    love.audio.play(sounds[sound_name])
end

return GM