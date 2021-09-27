require 'hud'

physic = {
    World = nil,
}

function physic.setup()
    love.physics.setMeter(32)
    physic.World = love.physics.newWorld(0, 9.81 * 64, true)
    physic.World:setCallbacks(physic.beginContact, physic.endContact)
end

function physic.addRectangle(x, y, width, height, dynamic, user_data)
    local o = {}

    o.Body = love.physics.newBody(physic.World, x, y, dynamic )
    o.Shape = love.physics.newRectangleShape(width, height)
    o.Fixture = love.physics.newFixture(o.Body, o.Shape)
    o.Fixture:setUserData(user_data)

    return o
end

function physic.addCircle(x, y, radius, dynamic, user_data)
    local o = {}

    o.Body = love.physics.newBody(physic.World, x, y, dynamic)
    o.Shape = love.physics.newCircleShape(radius)
    o.Fixture = love.physics.newFixture(o.Body, o.Shape)
    o.Fixture:setUserData(user_data)

    return o
end

function physic.update(dt)
    physic.World:update(dt)
end

function physic.draw()
    love.graphics.setColor(72, 160, 14)
    love.graphics.polygon("fill", physic.Ground.Body:getWorldPoints(physic.Ground.Shape:getPoints()))
end

function physic.beginContact(a, b, coll)
    local user_data_a, user_data_b = a:getUserData(), b:getUserData()

    if user_data_a and user_data_b then
        user_data_a.Manager.onCollision(user_data_a,user_data_b)
        user_data_b.Manager.onCollision(user_data_b,user_data_a)
    end
end

function physic.endContact(a, b, coll)
    local user_data_a, user_data_b = a:getUserData(), b:getUserData()

    if user_data_a and user_data_b then
        user_data_a.Manager.onCollisionEnd(user_data_a,user_data_b)
        user_data_b.Manager.onCollisionEnd(user_data_b,user_data_a)
    end
end