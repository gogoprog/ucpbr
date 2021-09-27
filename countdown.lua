
countdown = {
    Finished = false,
    CurrentTime = -10,
    instruction_on = true
}

function countdown.init()
    
end

function countdown.reset()
    countdown.Finished = false
end

function countdown.start(duration)
    countdown.CurrentTime = duration
    countdown.Finished = false
end

function countdown.isFinished()
    return countdown.Finished
end

function countdown.update(dt)
    countdown.CurrentTime = countdown.CurrentTime - dt

    if countdown.Finished == false and countdown.CurrentTime < 1 then
        countdown.Finished = true
        game.onStart()
    end
end

function countdown.draw()
        --love.audio.stop(audio.square_beeep)
        --audio.themusic:setVolume(0.7)
        --love.audio.play(audio.square_beeep)
    
    love.graphics.setColor(255,255,255,255)

    text = "MASH A AND B BUTTON TOGETHER"
        --if countdown.instruction_on then
        love.graphics.print(
            text,
            32,
            360,
            0,
            3,
            3
            )
        --end
        
           
    
    if countdown.CurrentTime > -2 then
        local text
        
        if countdown.CurrentTime > 1 then
            text = tostring(math.floor(countdown.CurrentTime))
        
        love.graphics.setColor(255,255,255,255)

        love.graphics.print(
            text,
            505,
            384-64,
            0,
            3,
            3
            )
        else
            text = "Fly! Fly! Fly!"
            
        love.graphics.setColor(255,255,255,255)

        love.graphics.print(
            text,
            270,
            384-64,
            0,
            3,
            3
            )
        
        countdown.instruction_on = false
        
        end

    end
end