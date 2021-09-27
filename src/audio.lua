audio = {
}

function audio.load()

    square_beep = love.audio.newSource("data/audio/square_beep.mp3", "static")
    audio.square_beeep = love.audio.newSource("data/audio/square_beep.mp3", "static")
    audio.beat = love.audio.newSource("data/audio/beat.mp3", "static")
    sine_beep = love.audio.newSource("data/audio/sine_beep.mp3", "static")
    audio.themusic = love.audio.newSource("data/audio/music.mp3", "stream")
    audio.intro_loop = love.audio.newSource("data/audio/intro_loop.mp3", "stream")
    level_up1 = love.audio.newSource("data/audio/level_up_1.mp3", "static")
    level_up2 = love.audio.newSource("data/audio/level_up_2.mp3", "static")
    audio.explosion = love.audio.newSource("data/audio/explosion.mp3", "static")
    love.audio.play(audio.intro_loop)
    
end

function audio.update(dt)

    
end

function audio.sfxplay(player_id, file_id)

    if player_id == 1 then
        love.audio.stop( square_beep )
        square_beep:setPitch(1+(file_id/10 ))
        love.audio.play(square_beep)
    else
        love.audio.stop( sine_beep )
        sine_beep:setPitch(1+(file_id/10))
        love.audio.play(sine_beep)
    end
    
    if player_id == 1 and file_id == 8 then
        love.audio.stop( level_up1 )
        love.audio.play(level_up1)
    elseif player_id == 2 and file_id == 8  then
        love.audio.stop( level_up2 )
        love.audio.play(level_up2)
    end

end

function audio.draw(p)

end
