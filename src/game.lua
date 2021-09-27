require 'player'
require 'level'
require 'physic'
require 'hud'
require 'countdown'
require 'particles'

game = {
    Players = {}
}

local TimeSum = 0
local FixedRate = 0.015

function game.load(lvl)
    physic.setup()
    player.load()
    level.init()
    level.load(lvl)
    particles.load()
    countdown.init()
    hud.load()
    audio.load()

    game.Started = false
    game.Finished = false
    game.ScoreSaved = false
    winnertext = ""
    --game.start()
end

function game.unload()
    if game.Players then
        for k,p in ipairs(game.Players) do
            p.PhysicObject.Fixture:destroy()
            p.PhysicObject.Body:destroy()
            p.Particles:stop()

            for i,g in ipairs(p.Gibs) do
                g.PhysicObject.Fixture:destroy()
                g.PhysicObject.Body:destroy()
                g.Particles:stop()
            end
        end



        game.Players = {}
    end
end

function game.start()

    love.audio.stop(audio.intro_loop)
    audio.themusic:setVolume(0.7)
    love.audio.play(audio.themusic)

    game.unload()

    game.Players[1] = {}
    game.Players[2] = {}
    game.TotalTime = 0.0

    player.setup(game.Players[1])
    player.setup(game.Players[2],true)

    countdown.start(6)

    game.Running = true
    game.Started = true
    game.Finished = false
    game.EndSequence = false
    game.EndTime = 0.001
    game.Winner = nil
    game.Loser = nil
    game.ScoreSaved = false
    countdown.instruction_on = true

end


function game.stop()
    love.audio.play(audio.intro_loop)
    love.audio.stop(audio.themusic)
    countdown.reset()
    game.Started = false
    game.Running = false
    game.unload()
end

function game.onStart()

end

function game.onFinish(p)
    game.EndSequence = true
    game.Winner = p

    for k,v in pairs(game.Players) do
        if v ~= p then
            game.Loser = v
        end
    end

    player.stop(game.Winner)
    player.stop(game.Loser)
end

function game.isControllable()
    return game.Started and game.EndSequence == false and countdown.isFinished()
end

function game.update(dt)

    TimeSum = TimeSum + dt

    while TimeSum >= FixedRate do
        physic.update(FixedRate)
        TimeSum = TimeSum - FixedRate
    end

    if game.Started then
        player.update(game.Players[1],dt)
        player.update(game.Players[2],dt)

        if countdown.isFinished() == true then
            level.update(dt)

            hud.update(game.Players[1],dt)
            hud.update(game.Players[2],dt)

            game.TotalTime = game.TotalTime + dt
        end

        countdown.update(dt)
        particles.update(dt)


        --debug key
        if love.keyboard.isDown("k") then
            game.onFinish(game.Players[1])
        end

        if love.keyboard.isDown("j") then
            game.onFinish(game.Players[2])
        end

        if game.EndSequence then
            game.EndTime = game.EndTime + dt

            if game.Winner.Dead == false then
                if game.EndTime > 1.0 then
                    player.die(game.Winner)
                end
            end

            if game.Loser.Dead == false then
                if game.EndTime > 1.5 then
                    player.die(game.Loser)
                end
            end

            if game.EndTime > 8.0 and game.ScoreSaved == false then
                game.Finished = true
                game.WinningScore = game.Winner.HighScore
                game.ScoreSaved = true
                game.EndSequence = false
            end
        end
    end
end

function game.draw()

    if game.Running then
        for k,p in ipairs(game.Players) do
            level.draw(-p.LevelX, p.OffsetY)

            particles.draw(-p.LevelX, p.OffsetY)

            player.draw(game.Players[3-k], -p.LevelX, p.OffsetY)
            player.draw(game.Players[k], -p.LevelX, p.OffsetY)

            hud.draw(game.Players[1])
            hud.draw(game.Players[2])

        end

        countdown.draw()
    end

    if game.Finished then
        scoretext = "     WITH A HIGH SCORE OF:"
        if game.Winner.ID == 1 then
            winnertext = "   PLAYER ONE IS THE WINNER"
        else
            winnertext = "   PLAYER TWO IS THE WINNER"
        end
        
        love.graphics.print("          GAME IS OVER", 16, 100, 0, 3, 3)
        love.graphics.print("      YOUR HEART EXPLODED", 16, 200, 0, 3, 3)
        love.graphics.print(winnertext, 16, 300, 0, 3, 3)
        love.graphics.print(scoretext, 16, 400, 0, 3, 3)
        love.graphics.print(round(game.WinningScore, 0), 350, 500, 0, 3, 3)
        love.graphics.print("  Press enter to go back to the main menu", 16, 600, 0, 2, 2)
    
    end
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end