-- Define imports globally
t = require 'lib.turtleutils'
inspect = require 'lib.inspect'
binser = require 'lib.binser'

-- Define love shortcuts
gfx = love.graphics
mouse = love.mouse
window = love.window
keyboard = love.keyboard
timer = love.timer
system = love.system
filesystem = love.filesystem
audio = love.audio

Main = {
    name = "Asteroid Game",
    width = 1920,
    height = 1080,
}

Game = require 'game'

function getDirection(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.atan(dy / dx)
end

function love.load()
    window.updateMode(Main.width, Main.height)

    Game.load()
end

function love.quit()
    -- Save data on quit
    Game.saveData()
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'escape' and isrepeat == false then
        Game.paused = t.toggle(Game.paused)
        if Game.paused then
            t.log("Paused.")
        else
            t.log("Unpaused.")
        end
    end
end

function love.resize(w, h)
    do end
end

function love.update(dt)
    -- Update game if not paused
    if Game.paused == false then
        Game.update(dt)
    end
end

function love.draw()
    Game.draw()
end
