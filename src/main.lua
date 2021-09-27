require 'level'
require 'levels'
require 'game'
require 'hud'
require 'menu'

function love.load()

    local font = love.graphics.newImageFont("data/imagefont.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")

    love.graphics.setFont(font)
    menu.load()
    game.load(LevelData)
end

function love.update(dt)
    menu.update(dt)
    game.update(dt)
end

function love.draw()
    game.draw()
    menu.draw()
end

function love.joystickpressed( joystick, button )
    if game.isControllable() then
        game.Players[joystick][button] = true

        if button == 13 then
          player.mashmash(game.Players[joystick],dt, true, 13)
        end
        if button == 12 then
          player.mashmash(game.Players[joystick],dt, false, 12)
        end
    end
end

function love.joystickreleased( joystick, button )

    if game.isControllable() then
        game.Players[joystick][button] = false
    end
end

function love.keypressed(key)
    if game.isControllable() then
        if key == "z" then
          player.mashmash(game.Players[1],dt, true)
          game.Players[1][12] = true
        end
        if key == "x" then
          player.mashmash(game.Players[1],dt, false)
          game.Players[1][13] = true
        end

        if key == "n" then
          player.mashmash(game.Players[2],dt, true)
          game.Players[2][12] = true
        end
        if key == "m" then
          player.mashmash(game.Players[2],dt, false)
          game.Players[2][13] = true
        end
    end

    if key == "escape" then
        love.event.push("quit")
    end
    
    if key == "f5" then
        love.filesystem.load("main.lua")()
        love.load()
    end

    if key == "f12" then
      game.start()
    end

end

function love.keyreleased(key)
    if game.isControllable() then
        if key == "z" then
          player.mashmash(game.Players[1],dt, true)
          game.Players[1][12] = false
        end
        if key == "x" then
          player.mashmash(game.Players[1],dt, false)
          game.Players[1][13] = false
        end

        if key == "n" then
          player.mashmash(game.Players[2],dt, true)
          game.Players[2][12] = false
        end
        if key == "m" then
          player.mashmash(game.Players[2],dt, false)
          game.Players[2][13] = false
        end
    end
end