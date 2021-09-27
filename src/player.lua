require 'physic'
require 'hud'
require 'particles'
require 'audio'

player = {
    Width = 60,
    Height = 60,
    HalfWidth = 30,
    HalfHeight = 30,
    Radius = 30
}

function easeOut(t, b, c, d)
    t = t / d;
    t = t - 1
    return c*(t*t*t*t*t + 1) + b;
end

function easeIn(t, b, c, d)
    t = t / d;
    return c*t*t*t*t*t + b;
end


function player.load()

end

function player.setup(p, inverted)

    p.GibTextures = {}

    if inverted == true then
        p.Name = "James"
        p.ID = 2
        p.X = 512
        p.LevelX = 1024
        p.OffsetY = 768/2
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib00_blue.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib01_blue.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib02_blue.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib03_blue.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib04_blue.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib05_blue.png"))
    else
        p.Name = "Jacob"
        p.ID = 1
        p.X = 512
        p.LevelX = 0
        p.OffsetY = 0
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib00.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib01.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib02.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib03.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib04.png"))
        table.insert(p.GibTextures, love.graphics.newImage("data/textures/gib05.png"))
    end

    p.Y = 768/4 + 32
    p.HighScore = 0

    p.Impulse = 10000

    p.MaxSpeedCap = {500,750,1000,1250,1500,1750,2000,2250}
    p.ImpulseReducer = {20,30,40,50,60,70,80,90}
    p.GaugeSize= {64,128,196,256, 320, 384, 452, 512}

    p.HeartCount = 0
    p.AudioCount = 1
    p.PrevCheck = true
    p.Jump = false
    p.Level = 1

    p.PhysicObject = physic.addCircle(p.X, p.Y, player.Radius, "dynamic", p)
    p.PhysicObject.Fixture:setCategory(2)
    p.PhysicObject.Fixture:setMask(2)

    p.Particles = particles.createRainbow()



    p.Animation = {}
    local texture

    texture = love.graphics.newImage("data/textures/perso0"..p.ID..".png")
    table.insert(p.Animation,texture)
    texture = love.graphics.newImage("data/textures/perso0"..p.ID.."_anim.png")
    table.insert(p.Animation,texture)

    p.AnimationIndex = 1

    p.HeartBeatTime = 0
    p.HeartBeatDuration = 1
    p.HeartUp = true
    p.HeartScale = 1

    p.Stopped = false
    p.Dead = false

    p.Gibs = {}

    p.Manager = player
end

function player.update(p, dt)

    p.OldX = p.X
    p.X = p.PhysicObject.Body:getX()
    p.Y = p.PhysicObject.Body:getY()
    p.HighScore  = p.HighScore  + ((p.X - p.OldX) * p.Level)
    hud.HighScore[p.ID] =  " Power x"..p.Level .. "   " .. round(p.HighScore, -1)

    if game.EndSequence then
        p.LevelX = p.LevelX + p.DeltaX / game.EndTime
    else
        p.LevelX = p.X - 256.0
    end


    p.DeltaX = ( p.X - p.OldX ) * dt
    if p.DeltaX < 0.001 then
        p.Impulse = 5000
    end

    p.Particles:setPosition(p.X,p.Y)

    if p.ParticlesLvlUP ~= nil then
        p.ParticlesLvlUP:setPosition(p.X,p.Y)
    end

    if p.SuperParticles ~= nil then
        p.SuperParticles:setPosition(p.X,p.Y)
    end

    p.VelocityX, p.VelocityY = p.PhysicObject.Body:getLinearVelocity( )
    p.Impulse = p.Impulse - (p.Impulse / p.ImpulseReducer[p.Level])


    hud.GaugeLevel[p.ID] = (p.VelocityX / p.MaxSpeedCap[p.Level]) * p.GaugeSize[p.Level]
    hud.GaugeSize[p.ID] = p.GaugeSize[p.Level]

    if p.VelocityX > 0 and p.Jump then
        p.PhysicObject.Body:applyForce(- (p.VelocityX / 2), 10)
    end
    
    if game.Players[p.ID][12] and game.Players[p.ID][13] and p.VelocityY > -100 then
    
        p.PhysicObject.Body:applyForce(10, -16000)
        p.Jump = true
    
    else
    
        p.Jump = false
    
    end

    p.NextHeartBeatDuration = ( 0.30 - p.DeltaX ) / 0.33

    if p.NextHeartBeatDuration < 0.1 then
        p.NextHeartBeatDuration = 0.1
    end

    if p.HeartUp then
        p.HeartBeatTime = p.HeartBeatTime + dt

        if p.HeartBeatTime > p.HeartBeatDuration then
            p.HeartBeatDuration = p.NextHeartBeatDuration
            p.HeartBeatTime = p.HeartBeatDuration
            p.HeartUp = false
        end

        p.HeartScale = 1 + easeIn(p.HeartBeatTime,0, 0.3, p.HeartBeatDuration)
    else
        p.HeartBeatTime = p.HeartBeatTime - dt

        if p.HeartBeatTime < 0 then
            p.HeartBeatDuration = p.NextHeartBeatDuration
            p.HeartBeatTime = 0
            p.HeartUp = true
        end
        p.HeartScale = 1 + easeIn(p.HeartBeatTime,0, 0.3, p.HeartBeatDuration)
    end

    if game.EndSequence == false and game.Finished == false and p.X > level.LevelWidth then
        game.onFinish(p)
    end

    for k,gib in ipairs(p.Gibs) do
        gib.Particles:setPosition(gib.PhysicObject.Body:getPosition())
    end
end

function player.mashmash(p, dt, butcheck, butid)
    
    if butcheck ~= p.PrevCheck then
    
        p.PrevCheck = butcheck

        if(p.VelocityX < p.MaxSpeedCap[p.Level]) then

            p.Impulse = p.Impulse + 100
            p.PhysicObject.Body:applyForce(p.Impulse, 10)
            
        end

        p.AnimationIndex = p.AnimationIndex + 1
        if p.AnimationIndex > #p.Animation then
            p.AnimationIndex = 1
        end

    end
end

function player.draw(p, x_offset, y_offset)

    if p.Dead == false then
        local x = p.X + x_offset
        local y = p.Y + y_offset
        local angle = 0

        if game.EndSequence then
            angle = p.PhysicObject.Body:getAngle()
        end

        love.graphics.draw(
            p.Animation[p.AnimationIndex],
            x,
            y,
            angle,
            1,
            1,
            player.HalfWidth,
            player.HalfHeight
            )
    else
        for k,gib in ipairs(p.Gibs) do
            local body = gib.PhysicObject.Body
            love.graphics.draw(
                gib.Texture,
                body:getX() + x_offset,
                body:getY() + y_offset,
                body:getAngle(),
                1,
                1,
                gib.Width / 2,
                gib.Height / 2
                )
        end
    end
end

function player.onCollision(p,other)
    -- other is always a bonus block!
    if other.Enabled then
        p.HeartCount = p.HeartCount + 1
        p.AudioCount = p.AudioCount + 1
        audio.sfxplay(p.ID, p.AudioCount)

        hud.HeartCount[p.ID] = tostring(p.HeartCount)
        p.HighScore = p.HighScore + (1000 * p.Level)
        other.Enabled = false

        if p.HeartCount == 0 then
            p.Level = 1
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 8 then
            p.Level = 2
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 16 then
            p.Level = 3
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 24 then
            p.Level = 4
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 32 then
            p.Level = 5
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 40 then
            p.Level = 6
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 48 then
            p.Level = 7
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        elseif p.HeartCount == 56 then
            p.Level = 8
            p.AudioCount = 0
            p.ParticlesLvlUP = particles.createLevelUpText();
        end

        particles.createOther(other.X,other.Y)

        other.RegenerationTime = 1.0

        if p.X < game.Players[3 - p.ID].X then
            p.Impulse = 50000
            if p.DeltaX > 0.35 then
                -- SUPER POWER
                p.SuperParticles = particles.createBoost()
            end
        end
    end
end

function player.onCollisionEnd(p,other)
end

function player.stop(p)
    p.Jump = false
    p.Stopped = true
    game.Players[p.ID][12] = false
    game.Players[p.ID][13] = false
end

function player.createGib(p, texture, physic_object)
    local gib = {}

    gib.Texture = texture
    gib.Width = gib.Texture:getWidth()
    gib.Height = gib.Texture:getHeight()
    gib.PhysicObject = physic.addRectangle(p.X,p.Y,gib.Width * 0.7,gib.Height * 0.7,"dynamic")
    gib.PhysicObject.Body:applyForce(math.random(-20000,20000),-15000)
    gib.Particles = particles.createGib()
    table.insert(p.Gibs, gib)
    
end

function player.die(p)
    p.Dead = true
    p.Particles:stop()
    p.Particles = particles.createDeath(p.X, p.Y)

    for k,v in ipairs(p.GibTextures) do
        player.createGib(p, v)
    end
    love.audio.play(audio.explosion)
end

function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end