local function check_collision(a, b)
    return a.x < b.x+b.w and
            b.x < a.x+a.w and
            a.y < b.y+b.h and
            b.y < a.y+a.h
end

local function draw_background()
    love.graphics.setBackgroundColor(rgb(236, 239, 244))
    local grid_size = TILE_SIZE*2
    local move = love.timer.getTime()*50%(2*grid_size)
    love.graphics.setLineWidth(grid_size/1.5)
    love.graphics.setColor(1, 1, 1, 0.02)
    for i = -(4*grid_size), SCREEN_W, grid_size do
        love.graphics.line(i + move, 0, i + move + grid_size, SCREEN_H)
    end
end

local function ease_out(x)
    return 1 - (1 - x)^2
end


local Objects = require "objects"
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
local wall = {
    tag = "wall"
}

local twists = {
    [1] = {"nothing", false},
    [2] = {"door is you, key is win", true}
}

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
            self.fading_out = true
        end
    end
    if self.fading_out then
        self.fade_out_timer = self.fade_out_timer + dt
        if self.fade_out_timer > self.fade_out_time then
            self.fade_out_timer = 0
            self.fading_out = false
        end
    end
end

function GM:draw()
    draw_background()
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", MAP_SIZE, 0, SCREEN_W-MAP_SIZE, SCREEN_H)
    love.graphics.setColor(1, 1, 1)
    
    for _, object in ipairs(self.objects) do
        object:draw()
    end

    love.graphics.setFont(FONT)
    love.graphics.push()
    love.graphics.translate(MAP_SIZE + TILE_SIZE, TILE_SIZE)
    
    love.graphics.setColor(rgb(236, 239, 244))
    if not self.fading_in then
        love.graphics.print("twist:")
        love.graphics.print(twists[self.index][1], 0, 60)
    end

    love.graphics.pop()

    love.graphics.setColor(rgb(71, 87, 98))
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
                        return b
                    end
                end
            end
        end
    end
end

function GM:move_x(a, x, filters)
    a.x = a.x+x
    local c = self:check(a, filters)
    if c then
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
    local c = self:check(a, filters)
    if c then
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
end

function GM:next(x)
    self.index = math.min(#twists, self.index + x)
end

function GM:clear()
    self:next(1)
    self.fading_in = true
end

function GM:key_obtained()
    self:add(Door, self.door_x, self.door_y, door_img)
end

function GM:restart()
    self.fading_in = true
end

return GM