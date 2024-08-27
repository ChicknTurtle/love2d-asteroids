local name = "Asteroid Game"

-- Initial window config
function love.conf(game)
    game.identity = name
    game.window.title = name
    --game.window.icon = 'assets/icon.png'

    game.window.vsync = 0
    game.window.highdpi = false
    game.window.msaa = 1
    game.window.resizable = true
end
