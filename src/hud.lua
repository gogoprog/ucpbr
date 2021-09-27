hud = {
    DebugText1 = "Debug Text 1",
    DebugText2 = "Debug Text 2",
    GaugeLevel = {},
    GaugeSize = {64,64},
    HeartCount = {0,0},
    HighScore = {0,0}
}

function hud.load()
    HeartLogo = love.graphics.newImage("data/textures/heart_red.png")
    hud.ProgressLeft = love.graphics.newImage("data/textures/progress_container_left.png")
    hud.ProgressCenter = love.graphics.newImage("data/textures/progress_container_center.png")
    hud.ProgressRight = love.graphics.newImage("data/textures/progress_container_right.png")

end

function hud.update(dt)

end

function hud.draw(p)
    
    if(game.Finished == false) then
        if p.ID == 1 then
            Yoffset = 0
        else
            Yoffset = 384
        end

        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle(
            "fill",
            16 + 5,
            16+Yoffset,
            math.min( hud.GaugeLevel[p.ID], hud.GaugeSize[p.ID] ),
            32
            )

        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.print(hud.HeartCount[p.ID], 1024-128, 16+Yoffset, 0, 3, 3)
        love.graphics.print(hud.HighScore[p.ID], 16, 50+Yoffset, 0, 2, 2)

        love.graphics.setColor(255, 255, 255, 255)

        love.graphics.draw(
            hud.ProgressLeft,
            16,
            16+Yoffset
            )

        love.graphics.draw(
            hud.ProgressRight,
            16+ hud.GaugeSize[p.ID],
            16+Yoffset
            )

        love.graphics.draw(
            hud.ProgressCenter,
            16 + 5,
            16 + Yoffset,
            0,
            hud.GaugeSize[p.ID] / 10,
            1
            )

        if p.Dead == false then
            love.graphics.draw(HeartLogo, 1024-190 - 16 * p.HeartScale, 26+Yoffset- 16 * p.HeartScale, 0, 1 * p.HeartScale, 1 * p.HeartScale)
        end

    end
    
    
end