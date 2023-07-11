 function [abort] = LoopBreaker(keys)
        abort = 0;
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyIsDown
            if find(keyCode) == keys.name.esc
                abort = 1;
                return;
            elseif find(keyCode) == keys.name.pause
                fprintf('\nPaused, press [%s] to resume.\n',upper(char(keys.keyList(keys.name.resume))));
                while 1
                    [keyIsDown, ~, keyCode] = KbCheck();
                    if keyIsDown
                        if find(keyCode) == keys.name.resume
                            break;
                        end
                    end
                end
            end
        end
    end
