menu = {}

function menu.load()
    menu.Texture = love.graphics.newImage("data/textures/menu.png")
    menu.TextureFinished = love.graphics.newImage("data/textures/menu.png")
    menu.Offset1 = 0
    menu.Offset2 = 0
    menu.PreviousState = false
    menu.ParticleTime = 0
    menu.ParticleInterval = 2
end

function menu.update(dt)
    local current_state = love.keyboard.isDown("return")
    
    if menu.PreviousState == false and game.Started == false then
        if current_state then
            game.start()
        end

        menu.Offset1 = menu.Offset1 + dt * 300
        menu.Offset2 = menu.Offset2 + dt * 200

        particles.update(dt)

        menu.ParticleTime = menu.ParticleTime + dt

        if menu.ParticleTime > menu.ParticleInterval then
            particles.createOther(math.random(0,1024), math.random(0,768))
            menu.ParticleTime = 0
            menu.ParticleInterval = math.random(0.5,1.5)
        end
    else
        if menu.PreviousState == false and current_state then
            game.stop()
            game.Finished = false
        end
    end

    menu.PreviousState = current_state
end

function menu.draw()
    if game.Running then
        return
    end
    
    if game.Finished == false then
        level.draw(-menu.Offset1, 0)
        level.draw(-menu.Offset1, 384)
        love.graphics.draw(menu.Texture)
        particles.draw(0, 0)
    else
        love.graphics.draw(menu.TextureFinished)
        particles.draw(0, 0)
    end
end
