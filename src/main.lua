
-- Define imports globally
t = require 'lib.turtleutils'
inspect = require 'lib.inspect'
binser = require 'lib.binser'

Game = require 'game'

-- Define love shortcuts
gfx = love.graphics
mouse = love.mouse
window = love.window
keyboard = love.keyboard
timer = love.timer
system = love.system
filesystem = love.filesystem
audio = love.audio

function getDirection(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.atan(dy / dx)
end

function love.load()
    window.updateMode(Game.width,Game.height)

    Game.load()
end

function love.quit()
    -- Save data on quit
    -- Doesn't always work, so don't rely on this
    Game.saveData()
end

function love.keypressed(key, scancode, isrepeat)
    do end
end

function love.resize(w,h)
    do end
end

function love.update(dt)
    Game.update(dt)
end

function love.draw()
    Game.draw()
end
