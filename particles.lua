particles = {
    Systems = {}
}

local ParticleTrail

function particles.load()
    ParticleTrail = love.graphics.newImage("data/textures/particle_trail.png")
    ParticleHeart = love.graphics.newImage("data/textures/particle_star.png")
    ParticleLvlUpTxt = love.graphics.newImage("data/textures/particle_level_up_text.png")
    ParticleBlood = love.graphics.newImage("data/textures/particle_blood.png")
end

function particles.createBoost()
    local p = love.graphics.newParticleSystem(ParticleTrail, 20)

    p:setEmissionRate(20)
    p:setSpeed(1000)
    p:setGravity(0, 100)
    p:setSizes(1, 3, 1)
    p:setColors(255, 255, 255, 255) 
    p:setPosition(0, 0)
    p:setLifetime(0.5)
    p:setParticleLife(1.0)
    p:setDirection(12.25)
    p:setSpread(0)
    p:setSpin(0, 0)

    table.insert(particles.Systems, p)

    return p
end

function particles.createRainbow()
    local p = love.graphics.newParticleSystem(ParticleTrail, 100)

    p:setEmissionRate(30)
    p:setSpeed(10, 20)
    p:setGravity(0, 100)
    p:setSizes(1, 0.5)
    p:setColors(255, 0, 255, 255, 255, 0, 0, 255, 255, 255, 0, 255,0,255,0,255,0,0,255,255)
    p:setPosition(0, 0)
    --p:setLifetime(0.1)
    p:setParticleLife(0.3)
    p:setDirection(3.25)
    p:setSpread(0)
    p:setSpin(0, 0)

    table.insert(particles.Systems, p)

    return p
end

function particles.createOther(x,y)
    local p = love.graphics.newParticleSystem(ParticleHeart, 30)

    p:setEmissionRate(30)
    p:setSpeed(300, 400)
    p:setGravity(1)
    p:setSizes(0.5, 1, 0.5)
    p:setColors(0, 255, 255, 255)
    p:setPosition(x, y)
    p:setLifetime(0.5)
    p:setParticleLife(0.3)
    p:setDirection(25)
    p:setSpread(360)
    p:setRotation(10, 5)
    p:setRadialAcceleration(1)
    p:setTangentialAcceleration(1)
        
    

    table.insert(particles.Systems, p)

    return p
end

function particles.createLevelUpText(x,y)
    local p = love.graphics.newParticleSystem(ParticleLvlUpTxt, 150)

    p:setEmissionRate(2)
    p:setSpeed(500)
    p:setGravity(0)
    p:setSizes(2, 5)
    --p:setColors(255, 0, 0, 255, 255, 0, 0, 125)
    p:setPosition(0, 0)
    p:setLifetime(1)
    p:setParticleLife(1)
    p:setDirection(12.25)
    p:setSpread(0)
    --p:setRotation(10, 5)
    p:setRadialAcceleration(0)
    p:setTangentialAcceleration(0)

    table.insert(particles.Systems, p)

    return p
end

function particles.createDeath(x,y)
    local p = love.graphics.newParticleSystem(ParticleBlood, 49)

    p:setEmissionRate(50)
    p:setSpeed(200,500)
    p:setGravity(750)
    p:setSizes(2, 5.5)
    --p:setColors(255, 0, 0, 255, 255, 0, 0, 125)
    p:setPosition(0, 0)
    p:setLifetime(0.3)
    p:setParticleLife(0.1,0.2)
    p:setDirection(0)
    p:setSpread(30)
    --p:setRotation(10, 5)
    p:setRadialAcceleration(-3000)
    p:setTangentialAcceleration(0)

    table.insert(particles.Systems, p)

    return p
end

function particles.createGib(x,y)
    local p = love.graphics.newParticleSystem(ParticleBlood, 15)
    

    p:setEmissionRate(10)
    p:setSpeed(0,1)
    p:setGravity(500)
    p:setSizes(0.5, 1)
    p:setColors(255, 0, 0, 255, 0, 0, 0, 0)
    p:setPosition(0, 0)
    p:setLifetime(2.0)
    p:setParticleLife(0.3,1.0)
    p:setDirection(12.25)
    p:setSpread(360)
    --p:setRotation(10, 5)
    p:setRadialAcceleration(0)
    p:setTangentialAcceleration(0)

    table.insert(particles.Systems, p)

    return p
end

function particles.update(dt)
    local particles_to_remove = {}

    for k,v in ipairs(particles.Systems) do
        v:update(dt)

        if v:isActive() == false then
            table.insert(particles_to_remove, k)
        end
    end

    for k,v in ipairs(particles_to_remove) do
        table.remove(particles.Systems, v)
    end
end

function particles.draw(x,y)
    for k,v in ipairs(particles.Systems) do
        
        love.graphics.draw(v,x,y)
    end
end