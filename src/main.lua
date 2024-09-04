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
    -- Containers
    data = {},
    fonts = {},
    shaders = {},
    canvases = {},
}

Game = require 'game'

function getDirection(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.atan2(dy, dx)
end

Main.loadData = function()
    -- Load from file
    if filesystem.getInfo("game.data") then
        local contents, size = filesystem.read("game.data")
        Main.data = binser.deserialize(contents)[1]
        t.log("Loaded game data. (" .. tostring(size) .. " bytes)")
    else
        t.logwarn("No game data to load.")
    end
    -- Load game data
    Game.level = Main.data.level
end

Main.saveData = function()
    -- Save game data
    Main.data.level = Game.level
    -- Write to file
    local success, message = filesystem.write("game.data", binser.serialize(Main.data))
    if success then
        t.log("Saved game.")
    else
        t.logerror("Failed to write save data: "..message)
    end
end

function love.load()
    -- Set window size
    window.updateMode(Main.width, Main.height)
    -- Load game data
    Main.loadData()
    -- Setup game scene
    Game.load()
end

function love.quit()
    -- Save data on quit
    Main.saveData()
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'escape' and isrepeat == false then
        Game.paused = t.toggle(Game.paused)
        if Game.paused then
            t.log("Game paused.")
        else
            t.log("Game unpaused.")
        end
    end
    if keyboard.isDown('/') then
        if key == 'p' and isrepeat == false then
            Game.pixelShaderEnabled = t.toggle(Game.pixelShaderEnabled)
            t.log("DEV: pixelShaderEnabled: " .. tostring(Game.pixelShaderEnabled))
        end
        if key == '[' then
            Game.level = Game.level - 1
            t.log("DEV: level: " .. tostring(Game.level))
            Game.nextLevel()
        end
        if key == ']' then
            Game.level = Game.level + 1
            t.log("DEV: level: " .. tostring(Game.level))
            Game.nextLevel()
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
