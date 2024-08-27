local game = {
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
        size = 1.75,     --size multiplier
        hitboxSize = 15, --pixels
    },
    -- Bullets
    bulletSpeed = 1000,    --pixels per second
    bulletCooldown = 0.2,  --seconds
    bulletSize = 6,        --pixels
    bulletLifetime = 0.65, --seconds
    bulletTimer = 0,
    -- Asteroids
    asteroidSpeedMin = 50,  --pixels per second
    asteroidSpeedMax = 150, --pixels per second
    asteroidMaxSpin = 90,   --degrees per second
    asteroidOffset = 30,    --degrees
    asteroidSizeMin = 2,    --size
    asteroidSizeMax = 3,    --size
    -- UFOs
    ufoMoveTime = 1,        --seconds
    ufoWaitTime = 1,        --seconds
    -- Levels
    levels = {
        {                       -- 1
            asteroidAmount = 5, --amount
            asteroidSpeed = 0,  --added to asteroidSpeedMax
            asteroidSize = 0,   --added to asteroidSizeMax
        },
        {                       -- 2
            asteroidAmount = 6,
            asteroidSpeed = 5,
            asteroidSize = 0,
        },
        { -- 3
            asteroidAmount = 7,
            asteroidSpeed = 10,
            asteroidSize = 1,
        },
        { -- 4
            asteroidAmount = 9,
            asteroidSpeed = 10,
            asteroidSize = 1,
        },
        { -- 5
            asteroidAmount = 5,
            asteroidSpeed = 5,
            asteroidSize = 0,
            ufos = {
                lvl1 = 1,
            },
        },
        { -- 6
            asteroidAmount = 7,
            asteroidSpeed = 10,
            asteroidSize = 1,
            ufos = {
                lvl1 = 1,
            },
        },
        { -- 7
            asteroidAmount = 8,
            asteroidSpeed = 5,
            asteroidSize = 0,
            ufos = {
                lvl1 = 2,
            },
        },
        { -- 8
            asteroidAmount = 8,
            asteroidSpeed = 5,
            asteroidSize = 2,
        },
        { -- 9
            asteroidAmount = 12,
            asteroidSpeed = 0,
            asteroidSize = 0,
            ufos = {
                lvl1 = 1,
            },
        },
        { -- 10
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

game.saveData = function()
    -- Save game data
    game.data.level = game.level
    -- Write to file
    local success, message = filesystem.write("game.data", binser.serialize(game.data))
    if success then
        t.log("Saved game.")
    else
        t.logerror("Failed to write save data: " .. message)
    end
end

-- Spawn asteroid
---@param parent table?
---@param overrides table?
game.spawnAsteroid = function(parent, overrides)
    local asteroid = {
        x = 0,
        y = 0,
        moveDir = math.rad(math.random(0, 359)),
        moveSpeed = math.random(game.asteroidSpeedMin, game.asteroidSpeedMax + game.levels[game.level].asteroidSpeed),
        facingDir = math.rad(math.random(0, 359)),
        spinSpeed = math.rad(math.random(0, game.asteroidMaxSpin)),
        size = math.random(2, 3 + game.levels[game.level].asteroidSize),
        health = 1,
        seed = math.random(0, 100000),
        flashTimer = 0,
    }
    if math.random(0, 1) == 1 then
        asteroid.x = game.width * math.random(0, 1)
        asteroid.y = game.height * math.random()
    else
        asteroid.x = game.width * math.random()
        asteroid.y = game.height * math.random(0, 1)
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
    table.insert(game.asteroids, asteroid)
end

-- Spawn UFO
---@param level number
game.spawnUfo = function(level)
    local ufo = {
        x = 0,
        y = 0,
        health = 3 * level,
        level = level,
        seed = math.random(0, 100000),
        flashTimer = 0,
        moveTimer = 0,
    }
    if math.random(0, 1) == 1 then
        ufo.x = game.width * math.random(0, 1)
        ufo.y = game.height * math.random()
    else
        ufo.x = game.width * math.random()
        ufo.y = game.height * math.random(0, 1)
    end
    -- Add ufo to table
    table.insert(game.ufos, ufo)
end

-- Spawn particle
---@param x number
---@param y number
---@param type string
game.spawnParticle = function(x, y, type, ...)
    local particle = {
        x = x,
        y = y,
        type = type,
        timer = 0,
    }
    for _, arg in ipairs({ ... }) do
        -- Add to particle data
        for key, value in pairs(arg) do
            particle[key] = value
        end
    end
    -- Add particle to table
    table.insert(game.particles, particle)
end

-- Next level
game.nextLevel = function()
    -- Save game
    game.saveData()

    local level = game.levels[game.level]
    math.randomseed(game.seed)

    -- Spawn asteroids
    if level.asteroidAmount then
        for i = 1, level.asteroidAmount do
            game.spawnAsteroid()
        end
    end
    -- Spawn override asteroids
    if level.asteroids then
        for i, asteroid in ipairs(level.asteroids) do
            game.spawnAsteroid(nil, asteroid)
        end
    end
    -- Spawn ufos
    if level.ufos and level.ufos.lvl1 then
        for i = 1, level.ufos.lvl1 do
            game.spawnUfo(1)
        end
    end
end

function game.load()
    -- Load game data
    if filesystem.getInfo("game.data") then
        local contents, size = filesystem.read("game.data")
        game.data = binser.deserialize(contents)[1]
        t.log("Loaded game data. (" .. tostring(size) .. "bytes)")
    else
        t.logwarn("No game data to load.")
    end
    -- Load level
    game.level = game.data.level or 1
    -- Print rng seed
    t.log("Seed: " .. game.seed)
    -- Spawn player in center of screen
    game.player.x = game.width / 2
    game.player.y = game.height / 2
    game.player.dir = math.pi * 0.75
    -- Create font objects
    game.fonts.BooCity = gfx.newFont('assets/fonts/BooCity.ttf', 40)
    game.fonts.BooCity:setFilter('nearest')
    game.fonts.BooCitySmall = gfx.newFont('assets/fonts/BooCity.ttf', 20)
    game.fonts.BooCitySmall:setFilter('nearest')
    game.fonts.Visitor = gfx.newFont('assets/fonts/Visitor.ttf', 40)
    game.fonts.Visitor:setFilter('nearest')
    game.fonts.VisitorSmall = gfx.newFont('assets/fonts/Visitor.ttf', 20)
    game.fonts.VisitorSmall:setFilter('nearest')
    -- Create shader objects
    gfx.setDefaultFilter('linear')
    --Game.shaders.pixel = gfx.newShader('assets/shaders/pixel.glsl')
    --Game.shaders.pixel:send('amount', Game.pixelSize)
    -- Create canvas objects
    gfx.setDefaultFilter('linear')
    game.canvases.game = gfx.newCanvas(game.width, game.height)
    -- Start level
    game.nextLevel()
end

function game.update(dt)
    -- Increment frame count
    game.frameCount = game.frameCount + 1
    -- Set seed
    math.randomseed(game.seed)
    game.seed = math.random(1, game.frameCount + os.time())
    math.randomseed(game.seed)

    -- Limit dt to 10 fps
    -- Game will slow down under 10 fps, instead of inaccurate collisions
    dt = math.min(dt, 1 / 10)

    -- Rotate player
    if keyboard.isDown("a") or keyboard.isDown("left") then
        game.player.dir = game.player.dir - math.rad(game.player.turnSpeed) * dt
    end
    if keyboard.isDown("d") or keyboard.isDown("right") then
        game.player.dir = game.player.dir + math.rad(game.player.turnSpeed) * dt
    end

    -- Change player velocity
    game.player.moving = false
    if keyboard.isDown("w") or keyboard.isDown("up") then
        game.player.moving = true
    end
    if game.player.moving then
        local dx = math.cos(game.player.dir)
        local dy = math.sin(game.player.dir)
        game.player.xv = game.player.xv - dx * game.player.moveSpeed * dt
        game.player.yv = game.player.yv - dy * game.player.moveSpeed * dt
    end

    -- Friction
    game.player.xv = game.player.xv * (1 - game.player.friction * dt)
    game.player.yv = game.player.yv * (1 - game.player.friction * dt)

    -- Move player
    game.player.x = game.player.x + game.player.xv * dt
    game.player.y = game.player.y + game.player.yv * dt

    -- Screen wrap
    if game.player.x < 0 then
        game.player.x = game.width
    end
    if game.player.x > game.width then
        game.player.x = 0
    end
    if game.player.y < 0 then
        game.player.y = game.height
    end
    if game.player.y > game.height then
        game.player.y = 0
    end

    -- Shoot bullets
    game.bulletTimer = game.bulletTimer - dt
    if keyboard.isDown("space") or mouse.isDown(1) then
        if game.bulletTimer < 0 then
            -- Create new bullet object
            local bullet = {
                x = game.player.x + math.cos(game.player.dir) * -18,
                y = game.player.y + math.sin(game.player.dir) * -18,
                dir = game.player.dir,
                timer = 0,
            }
            -- Add bullet to table
            table.insert(game.bullets, bullet)
            -- Reset bullet timer
            game.bulletTimer = game.bulletCooldown
        end
    end
    -- Update bullets
    for i, bullet in ipairs(game.bullets) do
        -- Calculate movement of the bullet
        local dx = math.cos(bullet.dir) * -game.bulletSpeed * dt
        local dy = math.sin(bullet.dir) * -game.bulletSpeed * dt
        -- Update the bullet's position
        bullet.x = bullet.x + dx
        bullet.y = bullet.y + dy
        -- Screen wrap
        if bullet.x < 0 then
            bullet.x = game.width
        end
        if bullet.x > game.width then
            bullet.x = 0
        end
        if bullet.y < 0 then
            bullet.y = game.height
        end
        if bullet.y > game.height then
            bullet.y = 0
        end
        -- Update timer
        bullet.timer = bullet.timer + dt
        if bullet.timer > game.bulletLifetime then
            -- Spawn particle
            game.spawnParticle(bullet.x, bullet.y, "bulletBlast")
            -- Delete bullet
            table.remove(game.bullets, i)
        end
    end
    -- Update asteroids
    for i, asteroid in ipairs(game.asteroids) do
        -- Calculate movement of the asteroid
        local dx = math.cos(asteroid.moveDir) * -asteroid.moveSpeed * dt
        local dy = math.sin(asteroid.moveDir) * -asteroid.moveSpeed * dt
        -- Update the asteroid's position
        asteroid.x = asteroid.x + dx
        asteroid.y = asteroid.y + dy
        -- Update facing direction
        asteroid.facingDir = asteroid.facingDir + asteroid.spinSpeed * dt
        -- Update flashTimer
        asteroid.flashTimer = asteroid.flashTimer - dt
        -- Screen wrap
        if asteroid.x < 0 then
            asteroid.x = game.width
        end
        if asteroid.x > game.width then
            asteroid.x = 0
        end
        if asteroid.y < 0 then
            asteroid.y = game.height
        end
        if asteroid.y > game.height then
            asteroid.y = 0
        end
    end
    -- Update UFOs
    for i, ufo in ipairs(game.ufos) do
        -- Update timers
        ufo.flashTimer = ufo.flashTimer - dt
        ufo.moveTimer = ufo.moveTimer - dt
        -- Screen wrap
        if ufo.x < 0 then
            ufo.x = game.width
        end
        if ufo.x > game.width then
            ufo.x = 0
        end
        if ufo.y < 0 then
            ufo.y = game.height
        end
        if ufo.y > game.height then
            ufo.y = 0
        end
    end

    -- Checks circle collisions
    local function collisionTransformed(x, y, x1, y1, x2, y2, size)
        return t.distance(x1 + x, y1 + y, x2, y2) < size
    end
    -- Checks circle collisions wrapped
    local function collisionWrapped(x1, y1, x2, y2, size)
        local width, height = game.width, game.height
        local check1 = collisionTransformed(0, 0, x1, y1, x2, y2, size)
        local check2 = collisionTransformed(0, -height, x1, y1, x2, y2, size)
        local check3 = collisionTransformed(-width, 0, x1, y1, x2, y2, size)
        local check4 = collisionTransformed(width, 0, x1, y1, x2, y2, size)
        local check5 = collisionTransformed(0, height, x1, y1, x2, y2, size)
        return check1 or check2 or check3 or check4 or check5
    end

    -- Asteroid collisions
    for i, asteroid in ipairs(game.asteroids) do
        -- Check player + asteroid
        if collisionWrapped(asteroid.x, asteroid.y, game.player.x, game.player.y, 21 * asteroid.size + game.player.hitboxSize) then
            -- Player hit an asteroid
            t.logdebug("Player hit an asteroid!")
            game.player.death = true
            -- Damage asteroid
            asteroid.health = asteroid.health - 1
            asteroid.flashTimer = 0.1
        end
        -- Check bullet + asteroid collisions
        for i, bullet in ipairs(game.bullets) do
            if collisionWrapped(asteroid.x, asteroid.y, bullet.x, bullet.y, 21 * asteroid.size + game.bulletSize) then
                -- A bullet hit an asteroid
                asteroid.health = asteroid.health - 1
                asteroid.flashTimer = 0.1
                -- Spawn particle
                game.spawnParticle(bullet.x, bullet.y, "bulletBlast")
                -- Remove bullet
                table.remove(game.bullets, i)
            end
        end
    end
    -- UFO collisions
    for i, ufo in ipairs(game.ufos) do
        -- Check player + ufo
        if collisionWrapped(ufo.x, ufo.y, game.player.x, game.player.y, 40 + game.player.hitboxSize) then
            -- Player hit a UFO
            t.logdebug("Player hit a UFO!")
            game.player.death = true
            -- Damage ufo
            ufo.health = ufo.health - 1
            ufo.flashTimer = 0.1
        end
        -- Check bullet + ufo collisions
        for i, bullet in ipairs(game.bullets) do
            if collisionWrapped(ufo.x, ufo.y, bullet.x, bullet.y, 40 + game.bulletSize) then
                -- A bullet hit a UFO
                ufo.health = ufo.health - 1
                ufo.flashTimer = 0.1
                -- Spawn particle
                game.spawnParticle(bullet.x, bullet.y, "bulletBlast")
                -- Remove bullet
                table.remove(game.bullets, i)
            end
        end
    end
    -- Bullet collisions
    for i, bullet in ipairs(game.bullets) do
        -- Check player + bullet
        if collisionWrapped(bullet.x, bullet.y, game.player.x, game.player.y, game.bulletSize + game.player.hitboxSize)
            and bullet.timer > 0.1 then
            -- Player hit a bullet
            t.logdebug("Player hit a bullet!")
            game.player.death = true
            -- Spawn particle
            game.spawnParticle(bullet.x, bullet.y, "bulletBlast")
            -- Remove bullet
            table.remove(game.bullets, i)
        end
        -- Check bullet + bullet
        for i2, bullet2 in ipairs(game.bullets) do
            if i ~= i2 then
                -- Bullets collid with each other easier than other things
                if collisionWrapped(bullet.x, bullet.y, bullet2.x, bullet2.y, game.bulletSize * 2 * 2) then
                    -- Spawn particle
                    game.spawnParticle((bullet.x + bullet2.x) / 2, (bullet.y + bullet2.y) / 2, "bulletBlast")
                    -- Delete bullets
                    table.remove(game.bullets, i)
                    if i2 > i then
                        i2 = i2 - 1
                    end
                    table.remove(game.bullets, i2)
                end
            end
        end
    end

    -- Check if player was hit
    if game.player.death == true then
        game.player.death = false
        game.player.x, game.player.y = game.width / 2, game.height / 2
        game.player.xv, game.player.yv = 0, 0
    end

    -- Split asteroids
    for i, asteroid in ipairs(game.asteroids) do
        if asteroid.health < 1 then
            table.remove(game.asteroids, i)
            game.spawnParticle(asteroid.x, asteroid.y, "asteroidSplit", { size = 22 * asteroid.size })
            if asteroid.size > 1 then
                game.spawnAsteroid(asteroid)
                game.spawnAsteroid(asteroid)
            end
        end
    end
    -- Blow up UFOs
    for i, ufo in ipairs(game.ufos) do
        if ufo.health < 1 then
            table.remove(game.ufos, i)
            game.spawnParticle(ufo.x, ufo.y, "ufoExplode")
        end
    end

    -- Check if ready for next level
    if #game.asteroids + #game.ufos == 0
        and game.levels[game.level + 1] ~= nil then
        -- Clear bullets
        for i, bullet in ipairs(game.bullets) do
            game.spawnParticle(bullet.x, bullet.y, "bulletBlast", { size = game.bulletSize })
        end
        game.bullets = {}
        game.level = game.level + 1
        game.nextLevel()
    end

    -- Update particles
    for i, particle in ipairs(game.particles) do
        particle.timer = particle.timer + dt
    end
end

function game.draw()
    local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

    gfx.setCanvas(game.canvases.game)

    local function drawTransformed(tx, ty, x, y, dir, func, ...)
        gfx.translate(tx, ty)
        gfx.rotate(dir)
        gfx.translate(x, y)
        func(...)
        gfx.translate(-x, -y)
        gfx.rotate(-dir)
        gfx.translate(-tx, -ty)
    end
    local function drawWrapped(x, y, dir, func, ...)
        local width, height = game.width, game.height
        drawTransformed(0, 0, x, y, dir, func, ...)
        drawTransformed(0, -height, x, y, dir, func, ...)
        drawTransformed(-width, 0, x, y, dir, func, ...)
        drawTransformed(width, 0, x, y, dir, func, ...)
        drawTransformed(0, height, x, y, dir, func, ...)
    end

    -- Draw background
    gfx.setBackgroundColor(0, 0, 0)
    gfx.setColor(0.025, 0.025, 0.1)
    gfx.rectangle('fill', 0, 0, game.width, game.height)
    gfx.setLineWidth(4)
    gfx.setColor(1, 1, 1, 0.1)
    gfx.rectangle('line', 0, 0, game.width, game.height)

    -- Draw bullets
    for i, bullet in ipairs(game.bullets) do
        gfx.push()
        gfx.translate(bullet.x, bullet.y)
        gfx.setColor(0, 1, 0)
        if game.fastGraphics then
            -- Don't draw wrapped
            drawTransformed(0, 0, 0, 0, bullet.dir + math.pi, gfx.circle, "fill", 0, 0, game.bulletSize)
        else
            -- Draw wrapped
            drawWrapped(0, 0, bullet.dir + math.pi, gfx.circle, "fill", 0, 0, game.bulletSize)
        end
        gfx.pop()
    end

    -- Draw player
    -- Position player
    gfx.push()
    gfx.translate(game.player.x, game.player.y)
    local size = game.player.size
    -- Thrust
    if game.player.moving then
        local colors = { { 1, 0.6, 0 }, { 1, 0.1, 0 }, { 1, 1, 0 } }
        gfx.setColor(unpack(colors[math.random(1, #colors)]))
        drawWrapped(0, 0, game.player.dir, gfx.polygon, "fill", 20 * size, 0, 11 * size, -8 * size, 11 * size, 8 * size)
    end
    -- Draw player
    gfx.setColor(0, 0, 1)
    drawWrapped(0, 0, game.player.dir, gfx.polygon, "fill", -18 * size, 0, 12 * size, -12 * size, 12 * size, 12 * size)
    gfx.pop()

    -- Draw asteroids
    for i, asteroid in ipairs(game.asteroids) do
        math.randomseed(asteroid.seed)
        gfx.push()
        gfx.translate(asteroid.x, asteroid.y)
        -- Shadow
        gfx.setColor(0, 0, 0, 0.25)
        drawWrapped(0, 0, asteroid.facingDir, gfx.circle, "fill", 0, 0, 22 * asteroid.size + 3)
        -- Asteroid
        gfx.setColor(0.5, 0.5, 0.5)
        if asteroid.flashTimer > 0 then
            gfx.setColor(1, 1, 1)
        end
        drawWrapped(0, 0, asteroid.facingDir, gfx.circle, "fill", 0, 0,
            22 * asteroid.size + 20 * math.max(0, asteroid.flashTimer))
        -- Spot
        local size = math.random(75, 105) / 10
        gfx.setColor(0.3, 0.3, 0.3)
        if asteroid.flashTimer > 0 then
            -- Hide if flashing
            gfx.setColor(1, 1, 1, 0)
        end
        drawWrapped(10 * asteroid.size, 0, asteroid.facingDir, gfx.circle, "fill", 0, 0, size * asteroid.size)
        gfx.pop()
        -- Reset seed
        math.randomseed(game.seed)
    end

    -- Draw ufos
    for i, ufo in ipairs(game.ufos) do
        gfx.push()
        gfx.translate(ufo.x, ufo.y)
        -- Alien
        gfx.setColor(0, 0.85, 0)
        drawWrapped(0, 0, 0, gfx.circle, "fill", 0, -30, 12)
        -- Glass
        gfx.setColor(0, 0, 1, 0.5)
        if ufo.flashTimer > 0 then
            gfx.setColor(1, 1, 1)
        end
        drawWrapped(0, 0, 0, gfx.circle, "fill", 0, -24, 28)
        -- Thrust
        math.randomseed(game.seed)
        local colors = { { 1, 0.6, 0 }, { 1, 0.1, 0 }, { 1, 1, 0 } }
        gfx.setColor(unpack(colors[math.random(1, #colors)]))
        drawWrapped(0, 0, 0, gfx.polygon, "fill", -16, 24, 16, 24, 0, 36)
        -- Body
        gfx.setColor(0.4, 0.4, 0.5)
        if ufo.flashTimer > 0 then
            gfx.setColor(1, 1, 1)
        end
        drawWrapped(0, 0, 0, gfx.polygon, "fill", -76, 0, -32, 24, 32, 24, 76, 0, 32, -24, -32, -24)
        -- Body gap
        gfx.setColor(0.2, 0.2, 0.25)
        if ufo.flashTimer > 0 then
            gfx.setColor(0, 0, 0, 0)
        end
        drawWrapped(0, 0, 0, gfx.polygon, "fill", -76, 0, -32, 6, 32, 6, 76, 0, 32, -6, -32, -6)
        gfx.pop()
        -- Reset seed
        math.randomseed(game.seed)
    end

    -- Draw particles
    for i, particle in ipairs(game.particles) do
        gfx.push()
        gfx.translate(particle.x, particle.y)
        if particle.type == "asteroidSplit" then
            if particle.timer > 0.5 then
                table.remove(game.particles, i)
            end
            gfx.setColor(1, 1, 1, 1 - particle.timer * 2)
            gfx.circle("fill", 0, 0, particle.size * 0.75 + particle.timer * 75)
        end
        if particle.type == "bulletBlast" then
            if particle.timer > 0.25 then
                table.remove(game.particles, i)
            end
            gfx.setColor(0.5, 1, 0.5, 1 - particle.timer * 4)
            gfx.circle("fill", 0, 0, game.bulletSize * 0.75 + particle.timer * 50)
        end
        gfx.pop()
    end

    -- Draw hitboxes
    if keyboard.isDown('.') then
        gfx.setColor(0, 1, 0, 0.5)
        -- Player
        drawWrapped(0, 0, 0, gfx.circle, "fill", game.player.x, game.player.y, game.player.hitboxSize)
        -- Asteroids
        for i, asteroid in ipairs(game.asteroids) do
            gfx.setColor(1, 0, 0, 0.5)
            drawWrapped(0, 0, 0, gfx.circle, "fill", asteroid.x, asteroid.y, 21 * asteroid.size)
        end
        -- UFOs
        for i, ufo in ipairs(game.ufos) do
            gfx.setColor(1, 0, 1, 0.5)
            drawWrapped(0, 0, 0, gfx.circle, "fill", ufo.x, ufo.y, 40)
        end
        -- This bullet hitbox used for bullet+bullet collisions
        for i, bullet in ipairs(game.bullets) do
            gfx.setColor(0, 0, 1, 0.5)
            drawWrapped(0, 0, 0, gfx.circle, "fill", bullet.x, bullet.y, game.bulletSize * 2)
        end
    end

    -- Draw text
    gfx.setColor(1, 1, 1)
    gfx.setDefaultFilter('nearest')
    gfx.setFont(game.fonts.Visitor)
    gfx.print(t.round(timer.getFPS()) .. " FPS", 20, 20, 0, 1)
    gfx.print("Level " .. game.level, 20, 60, 0, 1)
    if keyboard.isDown(',') then
        gfx.setFont(game.fonts.VisitorSmall)
        gfx.print(#game.asteroids .. " asteroids", 20, 100, 0, 1)
        gfx.print(#game.bullets .. " bullets", 20, 120, 0, 1)
        gfx.print(#game.particles .. " particles", 20, 140, 0, 1)
    end

    -- Draw game onto real canvas
    gfx.setCanvas()
    local scaleX = screenWidth / game.width
    local scaleY = screenHeight / game.height
    local scale = math.min(scaleX, scaleY)
    local offsetX = (screenWidth - game.width * scale) / 2
    local offsetY = (screenHeight - game.height * scale) / 2
    gfx.draw(game.canvases.game, offsetX, offsetY, 0, scale)
end

return game
