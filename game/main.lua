
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

function getDirection(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.atan(dy / dx)
end

Game = {
    -- Global game variables
    name = "Asteroid Game",
    width = 1920,
    height = 1080,
    frameCount = 0,
    seed = os.time(),
    level = 1,
    wrapMargin = 100,
    fastGraphics = true,
    -- Conatiners
    data = {},
    fonts = {},
    shaders = {},
    canvases = {},
    bullets = {},
    asteroids = {},
    ufos = {},
    particles = {},
    -- Player
    player = {
        x = 0,
        y = 0,
        xv = 0,
        yv = 0,
        dir = 0,
        moving = false,
        death = false,
        moveSpeed = 750, --pixels per second
        turnSpeed = 200, --degrees per second
        friction = 1,
        size = 1.75, --size multiplier
        hitboxSize = 15, --pixels
    },
    -- Bullets
    bulletSpeed = 1000, --pixels per second
    bulletCooldown = 0.2, --seconds
    bulletSize = 6, --pixels
    bulletLifetime = 0.65, --seconds
    bulletTimer = 0,
    -- Asteroids
    asteroidSpeedMin = 50, --pixels per second
    asteroidSpeedMax = 150, --pixels per second
    asteroidMaxSpin = 90, --degrees per second
    asteroidOffset = 30, --degrees
    asteroidSizeMin = 2, --size
    asteroidSizeMax = 3, --size
    -- UFOs
    ufoMoveTime = 1, --seconds
    ufoWaitTime = 1, --seconds
    -- Levels
    levels = {
        { -- 1
            asteroidAmount = 5, --amount
            asteroidSpeed = 0, --added to asteroidSpeedMax
            asteroidSize = 0, --added to asteroidSizeMax
        },
        {-- 2
            asteroidAmount = 6,
            asteroidSpeed = 5,
            asteroidSize = 0,
        },
        {-- 3
            asteroidAmount = 7,
            asteroidSpeed = 10,
            asteroidSize = 1,
        },
        {-- 4
            asteroidAmount = 9,
            asteroidSpeed = 10,
            asteroidSize = 1,
        },
        {-- 5
            asteroidAmount = 5,
            asteroidSpeed = 5,
            asteroidSize = 0,
            ufos = {
                lvl1 = 1,
            },
        },
        {-- 6
            asteroidAmount = 7,
            asteroidSpeed = 10,
            asteroidSize = 1,
            ufos = {
                lvl1 = 1,
            },
        },
        {-- 7
            asteroidAmount = 8,
            asteroidSpeed = 5,
            asteroidSize = 0,
            ufos = {
                lvl1 = 2,
            },
        },
        {-- 8
            asteroidAmount = 8,
            asteroidSpeed = 5,
            asteroidSize = 2,
        },
        {-- 9
            asteroidAmount = 12,
            asteroidSpeed = 0,
            asteroidSize = 0,
            ufos = {
                lvl1 = 1,
            },
        },
        {-- 10
            asteroidAmount = 4,
            asteroidSpeed = 0,
            asteroidSize = 0,
            asteroids = {
                {
                    size = 9,
                },
            },
        },
    },
}

Game.saveData = function()
    -- Save game data
    Game.data.level = Game.level
    -- Write to file
    local success, message = filesystem.write("game.data", binser.serialize(Game.data))
    if success then
        t.log("Saved game.")
    else
        t.logerror("Failed to write save data: "..message)
    end
end

-- Spawn asteroid
---@param parent table?
---@param overrides table?
Game.spawnAsteroid = function(parent, overrides)
    local asteroid = {
        x = 0,
        y = 0,
        moveDir = math.rad(math.random(0,359)),
        moveSpeed = math.random(Game.asteroidSpeedMin, Game.asteroidSpeedMax+Game.levels[Game.level].asteroidSpeed),
        facingDir = math.rad(math.random(0,359)),
        spinSpeed = math.rad(math.random(0, Game.asteroidMaxSpin)),
        size = math.random(2,3+Game.levels[Game.level].asteroidSize),
        health = 1,
        seed = math.random(0,100000),
        flashTimer = 0,
    }
    if math.random(0,1) == 1 then
        asteroid.x = Game.width*math.random(0,1)
        asteroid.y = Game.height*math.random()
    else
        asteroid.x = Game.width*math.random()
        asteroid.y = Game.height*math.random(0,1)
    end
    -- Inherit some values from parent
    if parent then
        asteroid.size = parent.size - 1
        asteroid.x, asteroid.y = parent.x, parent.y
    end
    -- Apply overrides
    if overrides then
        for key, value in pairs(overrides) do
            asteroid[key] = value
        end
    end
    -- Bigger = more health
    asteroid.health = asteroid.size
    -- Add asteroid to table
    table.insert(Game.asteroids, asteroid)
end

-- Spawn UFO
---@param level number
Game.spawnUfo = function(level)
    local ufo = {
        x = 0,
        y = 0,
        health = 3*level,
        level = level,
        seed = math.random(0,100000),
        flashTimer = 0,
        moveTimer = 0,
    }
    if math.random(0,1) == 1 then
        ufo.x = Game.width*math.random(0,1)
        ufo.y = Game.height*math.random()
    else
        ufo.x = Game.width*math.random()
        ufo.y = Game.height*math.random(0,1)
    end
    -- Add ufo to table
    table.insert(Game.ufos, ufo)
end

-- Spawn particle
---@param x number
---@param y number
---@param type string
Game.spawnParticle = function(x,y,type,...)
    local particle = {
        x = x,
        y = y,
        type = type,
        timer = 0,
    }
    for _, arg in ipairs({...}) do
        -- Add to particle data
        for key, value in pairs(arg) do
            particle[key] = value
        end
    end
    -- Add particle to table
    table.insert(Game.particles, particle)
end

-- Next level
Game.nextLevel = function()
    -- Save game
    Game.saveData()

    local level = Game.levels[Game.level]
    math.randomseed(Game.seed)

    -- Spawn asteroids
    if level.asteroidAmount then
        for i = 1, level.asteroidAmount do
            Game.spawnAsteroid()
        end
    end
    -- Spawn override asteroids
    if level.asteroids then
        for i, asteroid in ipairs(level.asteroids) do
            Game.spawnAsteroid(nil, asteroid)
        end
    end
    -- Spawn ufos
    if level.ufos and level.ufos.lvl1 then
        for i = 1, level.ufos.lvl1 do
            Game.spawnUfo(1)
        end
    end
end

function love.load()
    window.updateMode(Game.width,Game.height)

    -- Load game data
    if filesystem.getInfo("game.data") then
        local contents, size = filesystem.read("game.data")
        Game.data = binser.deserialize(contents)[1]
        t.log("Loaded game data.")
    else
        t.logwarn("No game data to load.")
    end
    -- Load level
    Game.level = Game.data.level or 1

    -- Print rng seed
    t.log("Seed: "..Game.seed)

    -- Spawn player in center of screen
    Game.player.x = Game.width/2
    Game.player.y = Game.height/2
    Game.player.dir = math.pi*0.75

    -- Create font objects
    Game.fonts.BooCity = gfx.newFont('assets/fonts/BooCity.ttf', 40)
    Game.fonts.BooCity:setFilter('nearest')
    Game.fonts.BooCitySmall = gfx.newFont('assets/fonts/BooCity.ttf', 20)
    Game.fonts.BooCitySmall:setFilter('nearest')
    Game.fonts.Visitor = gfx.newFont('assets/fonts/Visitor.ttf', 40)
    Game.fonts.Visitor:setFilter('nearest')
    Game.fonts.VisitorSmall = gfx.newFont('assets/fonts/Visitor.ttf', 20)
    Game.fonts.VisitorSmall:setFilter('nearest')

    -- Create shader objects
    gfx.setDefaultFilter('linear')
    --Game.shaders.pixel = gfx.newShader('assets/shaders/pixel.glsl')
    --Game.shaders.pixel:send('amount', Game.pixelSize)

    -- Create canvas objects
    gfx.setDefaultFilter('linear')
    Game.canvases.game = gfx.newCanvas(Game.width, Game.height)

    -- Start level
    Game.nextLevel()
end

function love.quit()
    -- Save data on quit
    -- Doesn't always work, so don't rely on this
    Game.saveData()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "p" then
        Game.saveData()
    end
end

function love.resize(w,h)
end

function love.update(dt)

    -- Increment frame count
    Game.frameCount = Game.frameCount + 1
    -- Set seed
    math.randomseed(Game.seed)
    Game.seed = math.random(1,Game.frameCount+os.time())
    math.randomseed(Game.seed)

    -- Limit dt to 10 fps
    -- Game will slow down under 10 fps, instead of inaccurate collisions
    dt = math.min(dt, 1/10)

    -- Rotate player
    if keyboard.isDown("a") or keyboard.isDown("left") then
        Game.player.dir = Game.player.dir - math.rad(Game.player.turnSpeed)*dt
    end
    if keyboard.isDown("d") or keyboard.isDown("right") then
        Game.player.dir = Game.player.dir + math.rad(Game.player.turnSpeed)*dt
    end

    -- Change player velocity
    Game.player.moving = false
    if keyboard.isDown("w") or keyboard.isDown("up") then
        Game.player.moving = true
    end
    if Game.player.moving then
        local dx = math.cos(Game.player.dir)
        local dy = math.sin(Game.player.dir)
        Game.player.xv = Game.player.xv - dx*Game.player.moveSpeed*dt
        Game.player.yv = Game.player.yv - dy*Game.player.moveSpeed*dt
    end

    -- Friction
    Game.player.xv = Game.player.xv * (1-Game.player.friction*dt)
    Game.player.yv = Game.player.yv * (1-Game.player.friction*dt)

    -- Move player
    Game.player.x = Game.player.x + Game.player.xv*dt
    Game.player.y = Game.player.y + Game.player.yv*dt

    -- Screen wrap
    if Game.player.x < 0 then
        Game.player.x = Game.width
    end
    if Game.player.x > Game.width then
        Game.player.x = 0
    end
    if Game.player.y < 0 then
        Game.player.y = Game.height
    end
    if Game.player.y > Game.height then
        Game.player.y = 0
    end

    -- Shoot bullets
    Game.bulletTimer = Game.bulletTimer - dt
    if keyboard.isDown("space") or mouse.isDown(1) then
        if Game.bulletTimer < 0 then
            -- Create new bullet object
            local bullet = {
                x = Game.player.x+math.cos(Game.player.dir)*-18,
                y = Game.player.y+math.sin(Game.player.dir)*-18,
                dir = Game.player.dir,
                timer = 0,
            }
            -- Add bullet to table
            table.insert(Game.bullets, bullet)
            -- Reset bullet timer
            Game.bulletTimer = Game.bulletCooldown
        end
    end
    -- Update bullets
    for i, bullet in ipairs(Game.bullets) do
        -- Calculate movement of the bullet
        local dx = math.cos(bullet.dir) * -Game.bulletSpeed*dt
        local dy = math.sin(bullet.dir) * -Game.bulletSpeed*dt
        -- Update the bullet's position
        bullet.x = bullet.x + dx
        bullet.y = bullet.y + dy
        -- Screen wrap
        if bullet.x < 0 then
            bullet.x = Game.width
        end
        if bullet.x > Game.width then
            bullet.x = 0
        end
        if bullet.y < 0 then
            bullet.y = Game.height
        end
        if bullet.y > Game.height then
            bullet.y = 0
        end
        -- Update timer
        bullet.timer = bullet.timer + dt
        if bullet.timer > Game.bulletLifetime then
            -- Spawn particle
            Game.spawnParticle(bullet.x,bullet.y,"bulletBlast")
            -- Delete bullet
            table.remove(Game.bullets,i)
        end
    end
    -- Update asteroids
    for i, asteroid in ipairs(Game.asteroids) do
        -- Calculate movement of the asteroid
        local dx = math.cos(asteroid.moveDir) * -asteroid.moveSpeed*dt
        local dy = math.sin(asteroid.moveDir) * -asteroid.moveSpeed*dt
        -- Update the asteroid's position
        asteroid.x = asteroid.x + dx
        asteroid.y = asteroid.y + dy
        -- Update facing direction
        asteroid.facingDir = asteroid.facingDir + asteroid.spinSpeed*dt
        -- Update flashTimer
        asteroid.flashTimer = asteroid.flashTimer - dt
        -- Screen wrap
        if asteroid.x < 0 then
            asteroid.x = Game.width
        end
        if asteroid.x > Game.width then
            asteroid.x = 0
        end
        if asteroid.y < 0 then
            asteroid.y = Game.height
        end
        if asteroid.y > Game.height then
            asteroid.y = 0
        end
    end
    -- Update UFOs
    for i, ufo in ipairs(Game.ufos) do
        -- Update timers
        ufo.flashTimer = ufo.flashTimer - dt
        ufo.moveTimer = ufo.moveTimer - dt
        -- Screen wrap
        if ufo.x < 0 then
            ufo.x = Game.width
        end
        if ufo.x > Game.width then
            ufo.x = 0
        end
        if ufo.y < 0 then
            ufo.y = Game.height
        end
        if ufo.y > Game.height then
            ufo.y = 0
        end
    end

    -- Checks circle collisions
    local function collisionTransformed(x,y,x1,y1,x2,y2,size)
        return t.distance(x1+x,y1+y,x2,y2) < size
    end
    -- Checks circle collisions wrapped
    local function collisionWrapped(x1,y1,x2,y2,size)
        local width,height = Game.width,Game.height
        local check1 = collisionTransformed(0,0,x1,y1,x2,y2,size)
        local check2 = collisionTransformed(0,-height,x1,y1,x2,y2,size)
        local check3 = collisionTransformed(-width,0,x1,y1,x2,y2,size)
        local check4 = collisionTransformed(width,0,x1,y1,x2,y2,size)
        local check5 = collisionTransformed(0,height,x1,y1,x2,y2,size)
        return check1 or check2 or check3 or check4 or check5
    end

    -- Asteroid collisions
    for i, asteroid in ipairs(Game.asteroids) do
        -- Check player + asteroid
        if collisionWrapped(asteroid.x,asteroid.y,Game.player.x,Game.player.y, 21*asteroid.size+Game.player.hitboxSize) then
            -- Player hit an asteroid
            t.logdebug("Player hit an asteroid!")
            Game.player.death = true
            -- Damage asteroid
            asteroid.health = asteroid.health - 1
            asteroid.flashTimer = 0.1
        end
        -- Check bullet + asteroid collisions
        for i, bullet in ipairs(Game.bullets) do
            if collisionWrapped(asteroid.x,asteroid.y,bullet.x,bullet.y, 21*asteroid.size+Game.bulletSize) then
                -- A bullet hit an asteroid
                asteroid.health = asteroid.health - 1
                asteroid.flashTimer = 0.1
                -- Spawn particle
                Game.spawnParticle(bullet.x,bullet.y,"bulletBlast")
                -- Remove bullet
                table.remove(Game.bullets,i)
            end
        end
    end
    -- UFO collisions
    for i, ufo in ipairs(Game.ufos) do
        -- Check player + ufo
        if collisionWrapped(ufo.x,ufo.y,Game.player.x,Game.player.y, 40+Game.player.hitboxSize) then
            -- Player hit a UFO
            t.logdebug("Player hit a UFO!")
            Game.player.death = true
            -- Damage ufo
            ufo.health = ufo.health - 1
            ufo.flashTimer = 0.1
        end
        -- Check bullet + ufo collisions
        for i, bullet in ipairs(Game.bullets) do
            if collisionWrapped(ufo.x,ufo.y,bullet.x,bullet.y, 40+Game.bulletSize) then
                -- A bullet hit a UFO
                ufo.health = ufo.health - 1
                ufo.flashTimer = 0.1
                -- Spawn particle
                Game.spawnParticle(bullet.x,bullet.y,"bulletBlast")
                -- Remove bullet
                table.remove(Game.bullets,i)
            end
        end
    end
    -- Bullet collisions
    for i, bullet in ipairs(Game.bullets) do
        -- Check player + bullet
        if collisionWrapped(bullet.x,bullet.y,Game.player.x,Game.player.y, Game.bulletSize+Game.player.hitboxSize)
            and bullet.timer > 0.1 then
            -- Player hit a bullet
            t.logdebug("Player hit a bullet!")
            Game.player.death = true
            -- Spawn particle
            Game.spawnParticle(bullet.x,bullet.y,"bulletBlast")
            -- Remove bullet
            table.remove(Game.bullets,i)
        end
        -- Check bullet + bullet
        for i2, bullet2 in ipairs(Game.bullets) do
            if i ~= i2 then
                -- Bullets collid with each other easier than other things
                if collisionWrapped(bullet.x,bullet.y,bullet2.x,bullet2.y, Game.bulletSize*2*2) then
                    -- Spawn particle
                    Game.spawnParticle((bullet.x+bullet2.x)/2,(bullet.y+bullet2.y)/2,"bulletBlast")
                    -- Delete bullets
                    table.remove(Game.bullets,i)
                    if i2 > i then
                        i2 = i2 - 1
                    end
                    table.remove(Game.bullets,i2)
                end
            end
        end
    end

    -- Check if player was hit
    if Game.player.death == true then
        Game.player.death = false
        Game.player.x, Game.player.y = Game.width/2, Game.height/2
        Game.player.xv, Game.player.yv = 0,0
    end

    -- Split asteroids
    for i, asteroid in ipairs(Game.asteroids) do
        if asteroid.health < 1 then
            table.remove(Game.asteroids, i)
            Game.spawnParticle(asteroid.x,asteroid.y,"asteroidSplit",{size=22*asteroid.size})
            if asteroid.size > 1 then
                Game.spawnAsteroid(asteroid)
                Game.spawnAsteroid(asteroid)
            end
        end
    end
    -- Blow up UFOs
    for i, ufo in ipairs(Game.ufos) do
        if ufo.health < 1 then
            table.remove(Game.ufos, i)
            Game.spawnParticle(ufo.x,ufo.y,"ufoExplode")
        end
    end

    -- Check if ready for next level
    if #Game.asteroids+#Game.ufos == 0
        and Game.levels[Game.level+1] ~= nil then
        -- Clear bullets
        for i, bullet in ipairs(Game.bullets) do
            Game.spawnParticle(bullet.x,bullet.y,"bulletBlast",{size=Game.bulletSize})
        end
        Game.bullets = {}
        Game.level = Game.level + 1
        Game.nextLevel()
    end

    -- Update particles
    for i, particle in ipairs(Game.particles) do
        particle.timer = particle.timer + dt
    end

end

function love.draw()

    local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

    gfx.setCanvas(Game.canvases.game)

    local function drawTransformed(tx,ty,x,y,dir,func,...)
        gfx.translate(tx,ty)
        gfx.rotate(dir)
        gfx.translate(x,y)
        func(...)
        gfx.translate(-x,-y)
        gfx.rotate(-dir)
        gfx.translate(-tx,-ty)
    end
    local function drawWrapped(x,y,dir,func,...)
        local width,height = Game.width,Game.height
        drawTransformed(0,0,x,y,dir,func,...)
        drawTransformed(0,-height,x,y,dir,func,...)
        drawTransformed(-width,0,x,y,dir,func,...)
        drawTransformed(width,0,x,y,dir,func,...)
        drawTransformed(0,height,x,y,dir,func,...)
    end

    -- Draw background
    gfx.setBackgroundColor(0,0,0)
    gfx.setColor(0.025,0.025,0.1)
    gfx.rectangle('fill',0,0,Game.width,Game.height)
    gfx.setLineWidth(4)
    gfx.setColor(1,1,1,0.1)
    gfx.rectangle('line',0,0,Game.width,Game.height)

    -- Draw bullets
    for i, bullet in ipairs(Game.bullets) do
        gfx.push()
        gfx.translate(bullet.x,bullet.y)
        gfx.setColor(0,1,0)
        if Game.fastGraphics then
            -- Don't draw wrapped
            drawTransformed(0,0,0,0,bullet.dir+math.pi,gfx.circle,"fill",0,0,Game.bulletSize)
        else
            -- Draw wrapped
            drawWrapped(0,0,bullet.dir+math.pi,gfx.circle,"fill",0,0,Game.bulletSize)
        end
        gfx.pop()
    end

    -- Draw player
    -- Position player
    gfx.push()
    gfx.translate(Game.player.x,Game.player.y)
    local size = Game.player.size
    -- Thrust
    if Game.player.moving then
        local colors = {{1,0.6,0},{1,0.1,0},{1,1,0}}
        gfx.setColor(unpack(colors[math.random(1, #colors)]))
        drawWrapped(0,0,Game.player.dir,gfx.polygon,"fill",20*size,0,11*size,-8*size,11*size,8*size)
    end
    -- Draw player
    gfx.setColor(0,0,1)
    drawWrapped(0,0,Game.player.dir,gfx.polygon,"fill",-18*size,0,12*size,-12*size,12*size,12*size)
    gfx.pop()

    -- Draw asteroids
    for i, asteroid in ipairs(Game.asteroids) do
        math.randomseed(asteroid.seed)
        gfx.push()
        gfx.translate(asteroid.x, asteroid.y)
        -- Shadow
        gfx.setColor(0,0,0,0.25)
        drawWrapped(0,0,asteroid.facingDir,gfx.circle,"fill",0,0,22*asteroid.size+3)
        -- Asteroid
        gfx.setColor(0.5,0.5,0.5)
        if asteroid.flashTimer > 0 then
            gfx.setColor(1,1,1)
        end
        drawWrapped(0,0,asteroid.facingDir,gfx.circle,"fill",0,0,22*asteroid.size+20*math.max(0,asteroid.flashTimer))
        -- Spot
        local size = math.random(75,105)/10
        gfx.setColor(0.3,0.3,0.3)
        if asteroid.flashTimer > 0 then
            -- Hide if flashing
            gfx.setColor(1,1,1,0)
        end
        drawWrapped(10*asteroid.size,0,asteroid.facingDir,gfx.circle,"fill",0,0,size*asteroid.size)
        gfx.pop()
        -- Reset seed
        math.randomseed(Game.seed)
    end

    -- Draw ufos
    for i, ufo in ipairs(Game.ufos) do
        gfx.push()
        gfx.translate(ufo.x, ufo.y)
        -- Alien
        gfx.setColor(0,0.85,0)
        drawWrapped(0,0,0,gfx.circle,"fill",0,-30,12)
        -- Glass
        gfx.setColor(0,0,1,0.5)
        if ufo.flashTimer > 0 then
            gfx.setColor(1,1,1)
        end
        drawWrapped(0,0,0,gfx.circle,"fill",0,-24,28)
        -- Thrust
        math.randomseed(Game.seed)
        local colors = {{1,0.6,0},{1,0.1,0},{1,1,0}}
        gfx.setColor(unpack(colors[math.random(1, #colors)]))
        drawWrapped(0,0,0,gfx.polygon,"fill",-16,24,16,24,0,36)
        -- Body
        gfx.setColor(0.4,0.4,0.5)
        if ufo.flashTimer > 0 then
            gfx.setColor(1,1,1)
        end
        drawWrapped(0,0,0,gfx.polygon,"fill",-76,0,-32,24,32,24,76,0,32,-24,-32,-24)
        -- Body gap
        gfx.setColor(0.2,0.2,0.25)
        if ufo.flashTimer > 0 then
            gfx.setColor(0,0,0,0)
        end
        drawWrapped(0,0,0,gfx.polygon,"fill",-76,0,-32,6,32,6,76,0,32,-6,-32,-6)
        gfx.pop()
        -- Reset seed
        math.randomseed(Game.seed)
    end

    -- Draw particles
    for i, particle in ipairs(Game.particles) do
        gfx.push()
        gfx.translate(particle.x,particle.y)
        if particle.type == "asteroidSplit" then
            if particle.timer > 0.5 then
                table.remove(Game.particles, i)
            end
            gfx.setColor(1,1,1,1-particle.timer*2)
            gfx.circle("fill",0,0,particle.size*0.75+particle.timer*75)
        end
        if particle.type == "bulletBlast" then
            if particle.timer > 0.25 then
                table.remove(Game.particles, i)
            end
            gfx.setColor(0.5,1,0.5,1-particle.timer*4)
            gfx.circle("fill",0,0,Game.bulletSize*0.75+particle.timer*50)
        end
        gfx.pop()
    end

    -- Draw hitboxes
    if keyboard.isDown('.') then
        gfx.setColor(0,1,0,0.5)
        -- Player
        drawWrapped(0,0,0,gfx.circle,"fill",Game.player.x,Game.player.y,Game.player.hitboxSize)
        -- Asteroids
        for i, asteroid in ipairs(Game.asteroids) do
            gfx.setColor(1,0,0,0.5)
            drawWrapped(0,0,0,gfx.circle,"fill",asteroid.x,asteroid.y,21*asteroid.size)
        end
        -- UFOs
        for i, ufo in ipairs(Game.ufos) do
            gfx.setColor(1,0,1,0.5)
            drawWrapped(0,0,0,gfx.circle,"fill",ufo.x,ufo.y,40)
        end
        -- This bullet hitbox used for bullet+bullet collisions
        for i, bullet in ipairs(Game.bullets) do
            gfx.setColor(0,0,1,0.5)
            drawWrapped(0,0,0,gfx.circle,"fill",bullet.x,bullet.y,Game.bulletSize*2)
        end
    end

    -- Draw text
    gfx.setColor(1,1,1)
    gfx.setDefaultFilter('nearest')
    gfx.setFont(Game.fonts.Visitor)
    gfx.print(t.round(timer.getFPS()).." FPS", 20, 20, 0, 1)
    gfx.print("Level "..Game.level, 20, 60, 0, 1)
    if keyboard.isDown(',') then
        gfx.setFont(Game.fonts.VisitorSmall)
        gfx.print(#Game.asteroids.." asteroids", 20, 100, 0, 1)
        gfx.print(#Game.bullets.." bullets", 20, 120, 0, 1)
        gfx.print(#Game.particles.." particles", 20, 140, 0, 1)
    end

    -- Draw game onto real canvas
    gfx.setCanvas()
    local scaleX = screenWidth / Game.width
    local scaleY = screenHeight / Game.height
    local scale = math.min(scaleX, scaleY)
    local offsetX = (screenWidth - Game.width * scale) / 2
    local offsetY = (screenHeight - Game.height * scale) / 2
    gfx.draw(Game.canvases.game,offsetX,offsetY,0,scale)
end
