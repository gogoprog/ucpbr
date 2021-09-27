local TextureDrawer
local RenderIsEnabled = false

-- if love.graphics.isSupported("pixeleffect") then
    -- TextureDrawer=require'perspective'
    -- RenderIsEnabled = true
-- else
    RenderIsEnabled = false
-- end

level = {}

local ScreenWidth = 1024
local ScreenHeight = 768 / 2
local ZoneWidth --= 1024
local ZoneHeight --= 768/2
local BlockYCount --= 12
local BlockXCount --= 32
local ZoneCount = 15
local CurrentLevel = {}

function level.init()
    CurrentLevel.Floor = physic.addRectangle(0, 768/2-16, 10240000, 32)
    CurrentLevel.Ceiling = physic.addRectangle(0, -16, 10240000, 32)
end

function level.load(level_data)
    CurrentLevel.Backgrounds = {}

    for k,v in pairs(level_data.Backgrounds) do
        local background = {}
        background.Texture = love.graphics.newImage("data/textures/" .. v.Texture)
        background.Texture:setWrap("repeat","repeat")
        background.Parallax = v.Parallax
        background.Y = v.Y
        background.Height = v.Height
        background.Width = v.Width
        background.RepeatX = ScreenWidth / background.Width
        table.insert(CurrentLevel.Backgrounds, background)
    end

    if CurrentLevel.Blocks then
        for k,v in ipairs(CurrentLevel.Blocks) do
            if v.PhysicObject then
                v.PhysicObject:destroy()
            end
        end
    end

    CurrentLevel.BlockSet = {}
    CurrentLevel.Zones = {}

    if level_data.File then
        local filedata = love.filesystem.load("data/tilesmaps/" .. level_data.File)()

        BlockXCount = filedata.width
        BlockYCount = filedata.height
        ZoneWidth = BlockXCount * 32
        ZoneHeight = BlockYCount * 32

        level.LevelWidth = ZoneWidth * (ZoneCount + 0.5)

        for k,v in pairs(filedata.tilesets) do
            local def = CurrentLevel.BlockSet
            local image = love.graphics.newImage("data/tilesmaps/" .. v.image)
            def.Texture = image
            def.Texture:setWrap("repeat", "repeat")
            def.Texture:setFilter("nearest","nearest")
            def.SpriteBatch = love.graphics.newSpriteBatch(def.Texture,5000)
            def.BonusSpriteBatch = love.graphics.newSpriteBatch(def.Texture,200)
            def.Blocks = {}
            def.BonusBlocks = {}
            def.BlockTypes = {}
            def.Quads = {}
            def.TileWidth = v.tilewidth
            def.TileHeight = v.tileheight

            for y = 0,image:getHeight()-1,32 do
                for x = 0,image:getWidth()-1,32 do
                    local quad = love.graphics.newQuad(x, y, 32, 32, image:getWidth(), image:getHeight())
                    table.insert(def.Quads, quad)
                end
            end

            for _,tile in ipairs(v.tiles) do
                def.BlockTypes[tile.id+1] = tile.properties.type
            end
        end

        for k,layer in pairs(filedata.layers) do
            local zone = {}
            zone.Blocks = {}
            zone.BonusBlocks = {}
            for i,v in ipairs(layer.data) do
                if v > 0 then
                    local block = {}
                    block.Type = v

                    block.X = ((i-1) % BlockXCount) * 32 + 16
                    block.Y = math.floor((i-1) / BlockXCount) * 32 + 16

                    if CurrentLevel.BlockSet.BlockTypes[v] == "bonus" then
                        table.insert(zone.BonusBlocks, block)
                    else
                        table.insert(zone.Blocks, block)
                    end
                end
            end
            table.insert(CurrentLevel.Zones, zone)

        end

        level.generateStaticBlocks()
    end
end

function level.generateStaticBlocks()

    local x_offset

    CurrentLevel.Blocks = {}
    CurrentLevel.BonusBlocks = {}

    CurrentLevel.BlockSet.SpriteBatch:clear()
    -- CurrentLevel.BlockSet.SpriteBatch:bind()

    for i=0,ZoneCount do
        local zone
        if i == ZoneCount then
            zone = CurrentLevel.Zones[#CurrentLevel.Zones]
        else
            zone = CurrentLevel.Zones[math.random(#CurrentLevel.Zones - 1)]
        end

        x_offset = ZoneWidth * i
        for k,v in ipairs(zone.Blocks) do
            local block = {}
            if v.Y < 345 then
                block.PhysicObject = physic.addRectangle(v.X+x_offset,v.Y,32,32)
            end

            CurrentLevel.BlockSet.SpriteBatch:add(
                CurrentLevel.BlockSet.Quads[v.Type],
                v.X+x_offset,
                v.Y
                )

            table.insert(CurrentLevel.Blocks, block)
        end

        for k,v in ipairs(zone.BonusBlocks) do
            local block = {}
            block.Manager = level
            block.PhysicObject = physic.addRectangle(v.X+x_offset,v.Y,32,32,nil,block)
            block.PhysicObject.Fixture:setSensor(true)
            block.X = v.X+x_offset
            block.Y = v.Y
            block.Type = v.Type
            block.Enabled = true
            block.RegenerationTime = 0.0

            table.insert(CurrentLevel.BonusBlocks, block)
        end
    end

    print("Blocks : " .. #CurrentLevel.Blocks)
    print("Bonus : " .. #CurrentLevel.BonusBlocks)

    -- CurrentLevel.BlockSet.SpriteBatch:unbind()
end

function level.updateBonusBlocks(dt)
    local x_offset

    CurrentLevel.BlockSet.BonusSpriteBatch:clear()
    -- CurrentLevel.BlockSet.BonusSpriteBatch:bind()

    for k,v in ipairs(CurrentLevel.BonusBlocks) do
        if v.Enabled then
            CurrentLevel.BlockSet.BonusSpriteBatch:add(
                CurrentLevel.BlockSet.Quads[v.Type],
                v.X,
                v.Y
                )
        else
            v.RegenerationTime = v.RegenerationTime - dt
            if v.RegenerationTime < 0.0 then
                v.Enabled = true
            end
        end
    end

    -- CurrentLevel.BlockSet.BonusSpriteBatch:unbind()
end

function level.update(dt)
    level.updateBonusBlocks(dt)
end

function level.draw(x_offset, y_offset)
    if RenderIsEnabled == false then

        love.graphics.setColor(0,255,0,255)
        love.graphics.rectangle("fill", 0, y_offset+384-32, 1024, 32)
        
        love.graphics.setColor(128,0,128,255)
        love.graphics.rectangle("fill", 0, 384-32, 10, 32)

        love.graphics.setColor(255,255,255,255)
        for k,v in pairs(CurrentLevel.Backgrounds) do
            local offset = -x_offset * v.Parallax
            local y = y_offset + v.Y

            for r = -4,20 do
                love.graphics.draw(v.Texture, -offset + r * v.Width, y)
            end
        end
    else

        for k,v in pairs(CurrentLevel.Backgrounds) do
            local offset = -x_offset * v.Parallax
            local y = y_offset + v.Y
            TextureDrawer.setRepeat({offset / v.Width,0},{v.RepeatX,1})
            TextureDrawer.quad(v.Texture,{0,y},{ScreenWidth,y},{ScreenWidth,v.Height + y},{0,v.Height + y})
        end
    end

    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(CurrentLevel.BlockSet.SpriteBatch, x_offset - 16, y_offset - 16)
    love.graphics.draw(CurrentLevel.BlockSet.BonusSpriteBatch, x_offset - 16, y_offset - 16)

end

function level.onCollision(obj,other)

end
function level.onCollisionEnd(obj,other)

end
