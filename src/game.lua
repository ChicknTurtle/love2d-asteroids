local game = {
    -- Global game variables
    frameCount = 0,
    time = 0,
    seed = os.time(),
    level = 1,
    score = 0,
    wrapMargin = 100,
    pixelation = 6,
    paused = false,
    pixelShaderEnabled = true,
    fastGraphics = true,
    -- Conatiners
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
        iframes = 0,
        iframetime = 3,  --seconds
        moveSpeed = 750, --pixels per second
        turnSpeed = 200, --degrees per second
        friction = 1,    --idk
        size = 1.75,     --size multiplier
        hitboxSize = 15, --pixels
    },
    -- Bullets
    bulletSpeed = 1000,    --pixels per second
    bulletCooldown = 0.2,  --seconds
    bulletSize = 6,        --pixels
    bulletLifetime = 1.25, --seconds
    bulletTimer = 0,
    -- Asteroids
    asteroidSpeedMin = 50,  --pixels per second
    asteroidSpeedMax = 150, --pixels per second
    asteroidMaxSpin = 90,   --degrees per second
    asteroidOffset = 30,    --degrees
    asteroidSizeMin = 2,    --size
    asteroidSizeMax = 3,    --size
    -- UFOs
    ufodata = {
        {                      -- blue
            health = 3,
            moveTime = 1,      --seconds
            waitTime = 2,      --seconds
            shootTime = 3,     --seconds
            moveSpeed = 150,   --multiplier
            bulletSpeed = 400, --pixels per second
        },
        {                      -- red
            health = 10,
            moveTime = 0.8,
            waitTime = 1.8,
            shootTime = 1,
            moveSpeed = 150,
            bulletSpeed = 400,
        },
        { -- green
            health = 5,
            moveTime = 0.4,
            waitTime = 0,
            shootTime = 2,
            moveSpeed = 400,
            bulletSpeed = 450,
        },
    },
    -- Levels
    levels = {
        { -- 1
            asteroidAmount = 5,
            asteroidSpeed = 0,
            asteroidSize = 0,
        },
        { -- 2
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
        { -- 11
            asteroidAmount = 8,
            asteroidSpeed = 2,
            asteroidSize = 1,
            ufos = {
                lvl2 = 1,
            },
        },
        { -- 12
            asteroidAmount = 6,
            asteroidSpeed = 2,
            asteroidSize = 1,
            ufos = {
                lvl1 = 2,
                lvl2 = 1,
            },
        },
        { -- 13
            asteroidAmount = 8,
            asteroidSpeed = 4,
            asteroidSize = 2,
            ufos = {
                lvl2 = 2,
            },
        },
        { -- 14
            asteroidAmount = 4,
            asteroidSpeed = 0,
            asteroidSize = 2,
            ufos = {
                lvl1 = 4,
            },
        },
        { -- 15
            asteroidAmount = 0,
            asteroidSpeed = 0,
            asteroidSize = 0,
            ufos = {
                lvl1 = 3,
                lvl2 = 2,
                lvl3 = 1,
            },
        },
    },
}

-- Spawn asteroid
---@param parent table?
---@param overrides table?
game.spawnAsteroid = function(parent, overrides)
    local asteroidSpeed = 0
    local asteroidSize = 0
    if game.levels[game.level] then
        asteroidSpeed = game.levels[game.level].asteroidSpeed
        asteroidSize = game.levels[game.level].asteroidSize
    else
        t.logwarn("Failed to get level asteroid data! Using fallback.")
    end
    local asteroid = {
        x = 0,
        y = 0,
        moveDir = math.rad(math.random(0, 359)),
        moveSpeed = math.random(game.asteroidSpeedMin, game.asteroidSpeedMax + asteroidSpeed),
        facingDir = math.rad(math.random(0, 359)),
        spinSpeed = math.rad(math.random(0, game.asteroidMaxSpin)),
        size = math.random(2, 3 + asteroidSize),
        health = 1,
        seed = math.random(0, 100000),
        flashTimer = 0,
    }
    if math.random(0, 1) == 1 then
        asteroid.x = Main.width * math.random(0, 1)
        asteroid.y = Main.height * math.random()
    else
        asteroid.x = Main.width * math.random()
        asteroid.y = Main.height * math.random(0, 1)
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
        level = level,
        health = game.ufodata[level].health,
        seed = math.random(0, 100000),
        flashTimer = 0,
        shootTimer = -math.random(0, game.ufodata[level].shootTime * 100) / 100,
        moveTimer = -math.random(0, game.ufodata[level].moveTime * 100) / 100,
        moveDir = 0,
    }
    if math.random(0, 1) == 1 then
        ufo.x = Main.width * math.random(0, 1)
        ufo.y = Main.height * math.random()
    else
        ufo.x = Main.width * math.random()
        ufo.y = Main.height * math.random(0, 1)
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

-- Explosion
game.spawnExplosion = function(x, y)
    math.randomseed(game.seed)
    for i = 1, 20 do
        local colors = { { 1, 0.5, 0 }, { 1, 0.1, 0 }, { 1, 0.9, 0 }, { 0.6, 0.6, 0.6 } }
        color = colors[math.random(1, #colors)]
        xv = math.random(-100, 100) / 100
        yv = math.random(-100, 100) / 100
        game.spawnParticle(x, y, "explosion", { color = color, xv = xv, yv = yv })
    end
end

-- Next level
game.nextLevel = function()
    local level = game.levels[game.level]
    if not level then
        t.logwarn("Tried to load an invalid level: " .. game.level)
        return
    end

    -- Save game
    Main.saveData()

    -- Clear lists
    for i = #game.bullets, 1, -1 do game.bullets[i] = nil end
    for i = #game.asteroids, 1, -1 do game.asteroids[i] = nil end
    for i = #game.ufos, 1, -1 do game.ufos[i] = nil end

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
    if level.ufos then
        if level.ufos.lvl1 then for i = 1, level.ufos.lvl1 do game.spawnUfo(1) end end
        if level.ufos.lvl2 then for i = 1, level.ufos.lvl2 do game.spawnUfo(2) end end
        if level.ufos.lvl3 then for i = 1, level.ufos.lvl3 do game.spawnUfo(3) end end
    end
end

function game.load()
    -- Load level
    game.level = game.level or 1
    t.logdebug(table.concat(
        (function()
            local t = {}; for k in pairs(Main.data) do table.insert(t, k) end
            return t
        end)(), ", "))
    -- Print rng seed
    t.log("Seed: " .. game.seed)
    -- Spawn player in center of screen
    game.player.x = Main.width / 2
    game.player.y = Main.height / 2
    game.player.dir = math.pi * 0.75
    -- Create font objects
    Main.fonts.BooCity = gfx.newFont('assets/fonts/BooCity.ttf', 40)
    Main.fonts.BooCity:setFilter('nearest')
    Main.fonts.BooCitySmall = gfx.newFont('assets/fonts/BooCity.ttf', 20)
    Main.fonts.BooCitySmall:setFilter('nearest')
    Main.fonts.Visitor = gfx.newFont('assets/fonts/Visitor.ttf', 40)
    Main.fonts.Visitor:setFilter('nearest')
    Main.fonts.VisitorSmall = gfx.newFont('assets/fonts/Visitor.ttf', 20)
    Main.fonts.VisitorSmall:setFilter('nearest')
    -- Create shader objects
    gfx.setDefaultFilter('linear')
    Main.shaders.pixel = gfx.newShader('assets/shaders/pixel.glsl')
    Main.shaders.pixel:send('amount', Game.pixelation)
    Main.shaders.pixel:send('size', { Main.width, Main.height })
    Main.shaders.stars = gfx.newShader('assets/shaders/stars.glsl')
    -- Create canvas objects
    gfx.setDefaultFilter('linear')
    Main.canvases.game = gfx.newCanvas(Main.width, Main.height)
    Main.canvases.ui = gfx.newCanvas(Main.width, Main.height)
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

    -- Increment game time
    game.time = game.time + dt
    Main.shaders.stars:send('time', game.time)

    game.player.iframes = game.player.iframes - dt

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
        -- Smoke particle
        if math.random(5) == 1 then
            local dx = math.cos(game.player.dir) * 25
            local dy = math.sin(game.player.dir) * 25
            game.spawnParticle(game.player.x + dx, game.player.y + dy, "smoke", { dir = game.player.dir })
        end
        -- Add velocity
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
        game.player.x = Main.width
    end
    if game.player.x > Main.width then
        game.player.x = 0
    end
    if game.player.y < 0 then
        game.player.y = Main.height
    end
    if game.player.y > Main.height then
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
                shooter = 'player',
                lifetime = game.bulletLifetime,
                speed = game.bulletSpeed,
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
        local dx = math.cos(bullet.dir) * -bullet.speed * dt
        local dy = math.sin(bullet.dir) * -bullet.speed * dt
        -- Update the bullet's position
        bullet.x = bullet.x + dx
        bullet.y = bullet.y + dy
        -- Screen wrap
        if bullet.x < 0 then
            bullet.x = Main.width
        end
        if bullet.x > Main.width then
            bullet.x = 0
        end
        if bullet.y < 0 then
            bullet.y = Main.height
        end
        if bullet.y > Main.height then
            bullet.y = 0
        end
        -- Update timer
        bullet.timer = bullet.timer + dt
        if bullet.timer > bullet.lifetime then
            -- Spawn particle
            game.spawnParticle(bullet.x, bullet.y, "bulletBlast", { shooter = bullet.shooter })
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
            asteroid.x = Main.width
        end
        if asteroid.x > Main.width then
            asteroid.x = 0
        end
        if asteroid.y < 0 then
            asteroid.y = Main.height
        end
        if asteroid.y > Main.height then
            asteroid.y = 0
        end
    end
    -- Update UFOs
    for i, ufo in ipairs(game.ufos) do
        -- Update timers
        ufo.flashTimer = ufo.flashTimer - dt
        ufo.moveTimer = ufo.moveTimer - dt
        ufo.shootTimer = ufo.shootTimer - dt
        -- Move
        if ufo.moveTimer < 0 - game.ufodata[ufo.level].waitTime then
            ufo.moveTimer = game.ufodata[ufo.level].moveTime
            ufo.moveDir = math.pi * 2 * math.random()
        end
        if ufo.moveTimer > 0 then
            local speed = game.ufodata[ufo.level].moveSpeed
            ufo.x = ufo.x + math.cos(ufo.moveDir) * speed * dt
            ufo.y = ufo.y + math.sin(ufo.moveDir) * speed * dt
        end
        -- Shoot
        if ufo.shootTimer < -game.ufodata[ufo.level].shootTime then
            ufo.shootTimer = game.ufodata[ufo.level].shootTime
            -- Create new bullet object
            local bullet = {
                x = ufo.x,
                y = ufo.y,
                dir = getDirection(game.player.x, game.player.y, ufo.x, ufo.y),
                shooter = 'ufo',
                lifetime = game.bulletLifetime * 2 * (game.bulletSpeed / game.ufodata[ufo.level].bulletSpeed),
                speed = game.ufodata[ufo.level].bulletSpeed,
                timer = 0,
            }
            -- Add bullet to table
            table.insert(game.bullets, bullet)
        end
        -- Screen wrap
        if ufo.x < 0 then
            ufo.x = Main.width
        end
        if ufo.x > Main.width then
            ufo.x = 0
        end
        if ufo.y < 0 then
            ufo.y = Main.height
        end
        if ufo.y > Main.height then
            ufo.y = 0
        end
    end

    -- Checks circle collisions
    local function collisionTransformed(x, y, x1, y1, x2, y2, size)
        return t.distance(x1 + x, y1 + y, x2, y2) < size
    end
    -- Checks circle collisions wrapped
    local function collisionWrapped(x1, y1, x2, y2, size)
        local width, height = Main.width, Main.height
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
        if collisionWrapped(asteroid.x, asteroid.y, game.player.x, game.player.y, 21 * asteroid.size + game.player.hitboxSize)
            and game.player.iframes < 0 then
            -- Player hit an asteroid
            t.logdebug("Player hit an asteroid!")
            game.player.death = true
            -- Damage asteroid
            asteroid.health = asteroid.health - 1
            asteroid.flashTimer = 0.1
        end
        -- Check bullet + asteroid collisions
        for i, bullet in ipairs(game.bullets) do
            if collisionWrapped(asteroid.x, asteroid.y, bullet.x, bullet.y, 21 * asteroid.size + game.bulletSize)
                and bullet.shooter == 'player' then
                -- A bullet hit an asteroid
                asteroid.health = asteroid.health - 1
                asteroid.flashTimer = 0.1
                -- Spawn particle
                game.spawnParticle(bullet.x, bullet.y, "bulletBlast", { shooter = bullet.shooter })
                -- Remove bullet
                table.remove(game.bullets, i)
            end
        end
    end
    -- UFO collisions
    for i, ufo in ipairs(game.ufos) do
        -- Check player + ufo
        if collisionWrapped(ufo.x, ufo.y, game.player.x, game.player.y, 40 + game.player.hitboxSize)
            and game.player.iframes < 0 then
            -- Player hit a UFO
            t.logdebug("Player hit a UFO!")
            game.player.death = true
            -- Damage ufo
            ufo.health = ufo.health - 1
            ufo.flashTimer = 0.1
        end
        -- Check bullet + ufo collisions
        for i, bullet in ipairs(game.bullets) do
            if collisionWrapped(ufo.x, ufo.y, bullet.x, bullet.y, 40 + game.bulletSize * 2)
                and bullet.shooter == 'player' then
                -- A bullet hit a UFO
                ufo.health = ufo.health - 1
                ufo.flashTimer = 0.1
                -- Spawn particle
                game.spawnParticle(bullet.x, bullet.y, "bulletBlast", { shooter = bullet.shooter })
                -- Remove bullet
                table.remove(game.bullets, i)
            end
        end
    end
    -- Bullet collisions
    for i, bullet in ipairs(game.bullets) do
        -- Check player + bullet
        if collisionWrapped(bullet.x, bullet.y, game.player.x, game.player.y, game.bulletSize + game.player.hitboxSize)
            and bullet.timer > 0.1
            and game.player.iframes < 0 then
            -- Player hit a bullet
            t.logdebug("Player hit a bullet!")
            game.player.death = true
            -- Spawn particle
            game.spawnParticle(bullet.x, bullet.y, "bulletBlast", { shooter = bullet.shooter })
            -- Remove bullet
            table.remove(game.bullets, i)
        end
        -- Check bullet + bullet
        for i2, bullet2 in ipairs(game.bullets) do
            if i ~= i2 then
                -- Bullets collid with each other easier than other things
                if collisionWrapped(bullet.x, bullet.y, bullet2.x, bullet2.y, game.bulletSize * 2 * 2) then
                    -- Spawn particle
                    game.spawnParticle((bullet.x + bullet2.x) / 2, (bullet.y + bullet2.y) / 2, "bulletBlast",
                        { shooter = bullet.shooter })
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
        game.spawnExplosion(game.player.x, game.player.y)
        game.player.death = false
        game.player.iframes = game.player.iframetime
        game.player.x, game.player.y = Main.width / 2, Main.height / 2
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
            game.spawnExplosion(ufo.x, ufo.y)
            table.remove(game.ufos, i)
        end
    end

    -- Check if ready for next level
    if #game.asteroids + #game.ufos == 0
        and game.levels[game.level + 1] ~= nil then
        -- Clear bullets
        for i, bullet in ipairs(game.bullets) do
            game.spawnParticle(bullet.x, bullet.y, "bulletBlast", { shooter = bullet.shooter })
        end
        game.bullets = {}
        t.logdebug("Level " .. tostring(game.level) .. " Complete!")
        game.level = game.level + 1
        game.nextLevel()
    end

    -- Update particles
    for i, particle in ipairs(game.particles) do
        particle.timer = particle.timer + dt
        if particle.type == 'explosion' then
            particle.x = particle.x + particle.xv
            particle.y = particle.y + particle.yv
        elseif particle.type == 'smoke' then
            particle.x = particle.x + math.cos(particle.dir)
            particle.y = particle.y + math.sin(particle.dir)
        end
    end
end

function game.draw()
    local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

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
        local width, height = Main.width, Main.height
        drawTransformed(0, 0, x, y, dir, func, ...)
        drawTransformed(0, -height, x, y, dir, func, ...)
        drawTransformed(-width, 0, x, y, dir, func, ...)
        drawTransformed(width, 0, x, y, dir, func, ...)
        drawTransformed(0, height, x, y, dir, func, ...)
    end

    gfx.setCanvas(Main.canvases.ui)
    gfx.clear()
    gfx.setCanvas(Main.canvases.game)
    gfx.clear()

    -- Draw background
    gfx.setColor(0, 0, 0)
    gfx.setShader(Main.shaders.stars)
    gfx.rectangle('fill', 0, 0, Main.width, Main.height)
    gfx.setShader()

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
    local interval = 0.1
    if game.player.iframes >= 0
        and (game.time % (interval * 2)) < interval then
        gfx.setColor(1, 1, 1)
    end
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
        if ufo.level == 2 then gfx.setColor(1, 0, 0, 0.5) end
        if ufo.level == 3 then gfx.setColor(0, 1, 0, 0.5) end
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
        if ufo.level == 2 then gfx.setColor(0.5, 0.4, 0.4) end
        if ufo.level == 3 then gfx.setColor(0.4, 0.5, 0.4) end
        if ufo.flashTimer > 0 then
            gfx.setColor(1, 1, 1)
        end
        drawWrapped(0, 0, 0, gfx.polygon, "fill", -76, 0, -32, 24, 32, 24, 76, 0, 32, -24, -32, -24)
        -- Body gap
        gfx.setColor(0.2, 0.2, 0.25)
        if ufo.level == 2 then gfx.setColor(0.25, 0.2, 0.2) end
        if ufo.level == 3 then gfx.setColor(0.2, 0.25, 0.2) end
        if ufo.flashTimer > 0 then
            gfx.setColor(0, 0, 0, 0)
        end
        drawWrapped(0, 0, 0, gfx.polygon, "fill", -76, 0, -32, 6, 32, 6, 76, 0, 32, -6, -32, -6)
        gfx.pop()
        -- Reset seed
        math.randomseed(game.seed)
    end

    -- Draw bullets
    for i, bullet in ipairs(game.bullets) do
        gfx.push()
        gfx.translate(bullet.x, bullet.y)
        gfx.setColor(0, 1, 0)
        if bullet.shooter == 'ufo' then gfx.setColor(1, 0, 0) end
        if game.fastGraphics then
            -- Don't draw wrapped
            drawTransformed(0, 0, 0, 0, bullet.dir + math.pi, gfx.circle, "fill", 0, 0, game.bulletSize)
        else
            -- Draw wrapped
            drawWrapped(0, 0, bullet.dir + math.pi, gfx.circle, "fill", 0, 0, game.bulletSize)
        end
        gfx.pop()
    end

    -- Draw particles
    for i, particle in ipairs(game.particles) do
        gfx.push()
        gfx.translate(particle.x, particle.y)
        if particle.type == "asteroidSplit" then
            -- Asteroid split
            if particle.timer > 0.5 then
                table.remove(game.particles, i)
            end
            gfx.setColor(1, 1, 1, 1 - particle.timer * 2)
            gfx.circle("fill", 0, 0, particle.size * 0.75 + particle.timer * 75)
        elseif particle.type == "bulletBlast" then
            -- Bullet blast
            if particle.timer > 0.25 then
                table.remove(game.particles, i)
            end
            local alpha = 1 - particle.timer * 4
            gfx.setColor(0.5, 1, 0.5, alpha)
            if particle.shooter == 'ufo' then gfx.setColor(1, 0.5, 0.5, alpha) end
            gfx.circle("fill", 0, 0, game.bulletSize * 0.75 + particle.timer * 50)
        elseif particle.type == "explosion" then
            -- Explosion
            local speed = math.sqrt(particle.xv ^ 2 + particle.yv ^ 2)
            local lifetime = speed * 2 - particle.timer
            if particle.timer > lifetime then
                table.remove(game.particles, i)
            end
            local alpha = 1 - particle.timer * t.inverse(lifetime)
            local r, g, b = particle.color[1], particle.color[2], particle.color[3]
            gfx.setColor(r, g, b, alpha)
            local size = 15 - particle.timer * 10
            gfx.circle("fill", 0, 0, size)
        elseif particle.type == "smoke" then
            -- Smoke
            local lifetime = 0.75
            if particle.timer > lifetime then
                table.remove(game.particles, i)
            end
            local alpha = 1 - particle.timer * t.inverse(lifetime)
            gfx.setColor(0.5, 0.5, 0.5, alpha / 2)
            local size = 15 - particle.timer * 10
            gfx.circle("fill", 0, 0, size)
        end
        gfx.pop()
    end

    gfx.setCanvas(Main.canvases.ui)

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
        -- Bullets
        for i, bullet in ipairs(game.bullets) do
            gfx.setColor(1, 1, 1, 0.75)
            drawWrapped(0, 0, 0, gfx.circle, "fill", bullet.x, bullet.y, game.bulletSize * 2)
        end
    end

    -- Draw paused
    if Game.paused then
        gfx.setColor(0, 0, 0, 0.5)
        gfx.rectangle('fill', 0, 0, Main.width, Main.height)
        gfx.setColor(1, 1, 1)
        gfx.setFont(Main.fonts.Visitor)
        local scale = 2
        local width = Main.fonts.Visitor:getWidth("Paused") * scale
        gfx.print("Paused", Main.width * 0.5 + (width * -0.5), Main.height * 0.3, 0, scale)
    end

    -- Draw text
    gfx.setColor(1, 1, 1)
    gfx.setDefaultFilter('nearest')
    gfx.setFont(Main.fonts.Visitor)
    gfx.print("Level " .. game.level, 20, 20, 0, 1)
    gfx.print("Score: " .. game.score, 20, 60, 0, 1)
    local fps = t.round(timer.getFPS()) .. " FPS"
    gfx.print(fps, Main.width - Main.fonts.Visitor:getWidth(fps) - 20, 20, 0, 1)
    if keyboard.isDown(',') then
        gfx.setFont(Main.fonts.VisitorSmall)
        gfx.print(#game.asteroids .. " asteroids", 20, 100, 0, 1)
        gfx.print(#game.bullets .. " bullets", 20, 120, 0, 1)
        gfx.print(#game.particles .. " particles", 20, 140, 0, 1)
    end

    -- Draw game onto real canvas
    gfx.setCanvas()
    local scaleX = screenWidth / Main.width
    local scaleY = screenHeight / Main.height
    local scale = math.min(scaleX, scaleY)
    local offsetX = (screenWidth - Main.width * scale) / 2
    local offsetY = (screenHeight - Main.height * scale) / 2
    -- Game canvas
    if Game.pixelShaderEnabled then
        gfx.setShader(Main.shaders.pixel)
    end
    gfx.draw(Main.canvases.game, offsetX, offsetY, 0, scale)
    gfx.setShader()
    gfx.draw(Main.canvases.ui, offsetX, offsetY, 0, scale)
end

return game
