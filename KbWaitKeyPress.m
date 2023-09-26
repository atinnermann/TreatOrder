function reactionTime = KbWaitKeyPress(keyname)

while 1
    [keyIsDown, secs, keyCode] = KbCheck();
    if keyIsDown
        if find(keyCode) == keyname
            reactionTime = secs;
            break
        end
    end
end
end

