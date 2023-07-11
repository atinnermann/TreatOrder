function t = VASScale(nTrial,s,t,keys)

%% Default values
nRatingSteps    = 101;
scaleWidth      = s.window(3)*0.35;
textSize        = 18;
lineWidth       = 6;

%% Calculate rects
activeAddon_width   = s.widthCross/2;
activeAddon_height  = s.sizeCross;
axesRect            = [s.midpoint(1) - scaleWidth/2; s.midpoint(2) - lineWidth/2; s.midpoint(1) + scaleWidth/2; s.midpoint(2) + lineWidth/2];
lowLabelRect        = [axesRect(1),s.midpoint(2)-activeAddon_height,axesRect(1)+activeAddon_width*4,s.midpoint(2)+activeAddon_height];
highLabelRect       = [axesRect(3)-activeAddon_width*4,s.midpoint(2)-activeAddon_height,axesRect(3),s.midpoint(2)+activeAddon_height];
ticPositions        = linspace(s.midpoint(1) - scaleWidth/2,s.midpoint(1) + scaleWidth/2-lineWidth,nRatingSteps);
activeTicRects      = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*s.midpoint(2)-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*s.midpoint(2)+activeAddon_height];

currentRating   = t.tmp.scaleInitVAS(nTrial);
finalRating     = currentRating;
reactionTime    = 0;
response        = 0;
first_flip      = 1;
startTime       = GetSecs;
numberOfSecondsRemaining = t.glob.ratingDur;
nrbuttonpresses = 0;


%%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
% tic; % control if timing is as long as durRating
while numberOfSecondsRemaining  > 0
    Screen('FillRect',s.wHandle,s.backgr);
    Screen('FillRect',s.wHandle,s.white,axesRect);
    Screen('FillRect',s.wHandle,s.white,lowLabelRect);
    Screen('FillRect',s.wHandle,s.white,highLabelRect);
    Screen('FillRect',s.wHandle,s.red,activeTicRects(:,currentRating));
    
    Screen('TextSize',s.wHandle,s.fontsize);
    DrawFormattedText(s.wHandle, 'Wie bewerten Sie die Schmerzhaftigkeit', 'center',s.midpoint(2)-s.midpoint(2)*0.25, s.white);
    DrawFormattedText(s.wHandle, 'des Hitzereizes?', 'center',s.midpoint(2)-s.midpoint(2)*0.25+s.lineheight, s.white);
    
    Screen('TextSize',s.wHandle,textSize);
    Screen('DrawText',s.wHandle,'kein',axesRect(1)-17,s.midpoint(2)+25,s.white);
    Screen('DrawText',s.wHandle,'Schmerz',axesRect(1)-40,s.midpoint(2)+45,s.white);
    
    Screen('DrawText',s.wHandle,'unerträglicher',axesRect(3)-53,s.midpoint(2)+25,s.white);
    Screen('DrawText',s.wHandle,'Schmerz',axesRect(3)-40,s.midpoint(2)+45,s.white);
    
    if response == 0
        
        % set time 0 (for reaction time)
        if first_flip   == 1
            secs0       = Screen(s.wHandle,'Flip'); % output Flip -> starttime rating
            first_flip  = 0;
            % after 1st flip -> just flips without setting secs0 to null
        else
            Screen('Flip', s.wHandle);
        end
        
        [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
        if keyIsDown % only if a key was pressed we check which key it was
            response = 0; % predefine variable for confirmation button 'space'
            nrbuttonpresses = nrbuttonpresses + 1;
            if keyCode(keys.name.right) % if it was the key we named key1 at the top then...
                currentRating = currentRating + 1;
                finalRating = currentRating;
                response = 0;
                if currentRating > nRatingSteps
                    currentRating = nRatingSteps;
                end
            elseif keyCode(keys.name.left)
                currentRating = currentRating - 1;
                finalRating = currentRating;
                response = 0;
                if currentRating < 1
                    currentRating = 1;
                end
            elseif keyCode(keys.name.esc)
                reactionTime = 99; % to differentiate between ESCAPE and timeout in logfile
                VASoff = GetSecs-startTime;
                disp('***********');
                disp('Abgebrochen');
                disp('***********');
                break;
            elseif keyCode(keys.name.confirm)
                finalRating = currentRating-1;
                disp(['VAS Rating: ' num2str(finalRating)]);
                response = 1;
                reactionTime = secs - secs0;
                break;
            end
        end
    end
    
    numberOfSecondsElapsed   = (GetSecs - startTime);
    numberOfSecondsRemaining = t.glob.ratingDur - numberOfSecondsElapsed;
    
end

if nrbuttonpresses ~= 0 && response == 0
    finalRating = currentRating - 1;
    reactionTime = GetSecs - startTime;
    disp(['VAS Rating: ' num2str(finalRating)]);    
elseif nrbuttonpresses == 0
    finalRating = NaN;
    reactionTime = GetSecs - startTime;
    disp(['VAS Rating: ' num2str(finalRating)]);    
end
% toc

t.tmp.trial(nTrial)         = nTrial; 
t.tmp.rating(nTrial)        = finalRating;
t.tmp.reactionTime(nTrial)  = reactionTime;
t.tmp.response(nTrial)      = response;

