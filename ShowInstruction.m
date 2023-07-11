function [abort] = ShowInstruction(section,keys,s,com,displayDuration)

if nargin == 4
    displayDuration = 0;
end

abort = 0;

if section == 1
    %instruction preexpsoure
    fprintf('Ready PREEXPOSURE protocol.\n');
    heightText = s.startY-s.lineheight*2;
    if strcmp(s.language,'de')
        [~,heightText]=DrawFormattedText(s.wHandle, 'Gleich erhalten Sie über die Thermode einen', 'center', heightText, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'langen Hitzereizen, der leicht schmerzhaft sein kann.', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Wir melden uns gleich, falls Sie noch Fragen haben,', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'danach geht es los!', 'center', heightText+s.lineheight, s.white);
    elseif strcmp(s.language,'en')
        [~,heightText]=DrawFormattedText(s.wHandle, 'You will now receive a number of very brief heat stimuli,', 'center', heightText, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'which may or may not be painful for you.', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'We will ask you in a few moments about any remaining questions,', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'then the measurement will start!', 'center', heightText+s.lineheight, s.white);
    end
elseif section == 2
    %instruction awiszus thesholding
    heightText = s.startY-s.lineheight*3;
    if strcmp(s.hostname,'stimpc1')
        if strcmp(s.language,'de')
            keyNotPainful = '(linker Knopf)';
            keyPainful = '(rechter Knopf)';
        elseif strcmp(s.language,'en')
            keyNotPainful = '(left button)';
            keyPainful = '(right button)';
        end
    else
        keyNotPainful = '(<-)';
        keyPainful = '(->)';
    end
    if strcmp(s.language,'de')
        [~,heightText]=DrawFormattedText(s.wHandle, 'Gleich beginnt Teil 1 der Schmerzschwellenmessung.', 'center', heightText, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Sie werden über die Thermode konstante Hitzereize erhalten.', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Bitte geben Sie nach jedem Reiz an, ob dieser', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['NICHT SCHMERZHAFT ' keyNotPainful ' oder'], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['mindestens LEICHT SCHMERZHAFT ' keyPainful ' war.'], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        %[screenRes.width, heightText]=DrawFormattedText(s.wHandle, 'Wir melden uns gleich, falls Sie noch Fragen haben,', 'center', heightText+s.lineheight, s.white);
        %[screenRes.width, heightText]=DrawFormattedText(s.wHandle, 'danach geht es los!', 'center', heightText+s.lineheight, s.white);
        [~, heightText]=DrawFormattedText(s.wHandle, 'Gleich geht es los!', 'center', heightText+s.lineheight, s.white);
    elseif strcmp(s.language,'en')
        [~,heightText]=DrawFormattedText(s.wHandle, 'In a moment, part 1 of the pain threshold calibration will start.', 'center', heightText, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'You will receive constant heat stimuli via the thermode.', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Please indicate after each stimulus whether it was', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['NOT PAINFUL ' keyNotPainful ' or'], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['(at least) SLIGHTLY PAINFUL ' keyPainful ], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Commencing shortly!', 'center', heightText+s.lineheight, s.white);
    end
elseif section == 3
    %instruction for calibration
    heightText = s.startY-s.lineheight*3;   
    if strcmp(s.hostname,'stimpc1')
        if strcmp(s.language,'de')
            keyMoreLessPainful = 'des linken/rechten Knopfes';
            keyConfirm = 'dem mittleren oberen Knopf';
        elseif strcmp(s.language,'en')
            keyMoreLessPainful = 'the left/right button';
            keyConfirm = 'the middle upper button';
        end
    else
        if strcmp(s.language,'de')
            keyMoreLessPainful = 'der linken/rechten Pfeiltaste';
            keyConfirm = 'der Eingabetaste';
        elseif strcmp(s.language,'en')
            keyMoreLessPainful = 'the left/right cursor key';
            keyConfirm = 'Enter';
        end
    end
    if strcmp(s.language,'de')
        [~,heightText]=DrawFormattedText(s.wHandle, 'Gleich beginnt Teil 2 der Schmerzschwellenmessung.', 'center', heightText, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Sie werden über die Thermode konstante Hitzereize erhalten.', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['Bitte bewerten Sie jeden Reiz mithilfe ' keyMoreLessPainful], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['und bestätigen mit ' keyConfirm '.'], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'Es ist SEHR WICHTIG, dass Sie JEDEN der Reize bewerten!', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
    elseif strcmp(s.language,'en')
        [~,heightText]=DrawFormattedText(s.wHandle, 'In a moment, part 2 of pain threshold calibration will start.', 'center', heightText, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'You will receive constant heat stimuli via the thermode.', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['Please rate each stimulus using ' keyMoreLessPainful], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ['and confirm with ' keyConfirm '.'], 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, 'It is VERY IMPORTANT that you rate EACH AND EVERY stimulus!', 'center', heightText+s.lineheight, s.white);
        [~,heightText]=DrawFormattedText(s.wHandle, ' ', 'center', heightText+s.lineheight, s.white);
    end
elseif section == 4
    heightText = s.startY;  
    if strcmp(s.language,'de')
        [~, heightText]=DrawFormattedText(s.wHandle,'Gleich geht es weiter...','center',heightText,s.white);
    elseif strcmp(s.language,'en')
        [~, heightText]=DrawFormattedText(s.wHandle,'Continuing shortly...','center',heightText,s.white);
    end
elseif section == 5
    heightText = s.startY;
    if strcmp(s.language,'de')
        [~, heightText]=DrawFormattedText(s.wHandle,'Gleich geht es los...','center',heightText,s.white);
    elseif strcmp(s.language,'en')
        [~, heightText]=DrawFormattedText(s.wHandle,'Starting shortly...','center',heightText,s.white);
    end
elseif section == 6
    fprintf('Please check data/figure and press enter when ready.\n');
    heightText = s.startY;
    [~, heightText]=DrawFormattedText(s.wHandle,'','center',heightText,s.white);  
end

introTextTime = Screen('Flip',s.wHandle);

if displayDuration == 1 && section ~= 6
    fprintf('Displaying instructions... ');
    countedDown = 1;
end

while 1
    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        if find(keyCode) == keys.name.confirm
            break;
        elseif find(keyCode) == keys.name.esc
            abort = 1;
            break;
        end
    end
    
    if displayDuration == 1 && section ~= 6
        [countedDown] = CountDown(GetSecs-introTextTime,countedDown,'.');
    end
end

if abort
    QuickCleanup(com.thermoino);
    return;
end

if displayDuration == 1 && section ~= 6
    fprintf('\nInstructions were displayed for %d seconds.\n',round(GetSecs-introTextTime,0)); 
end

Screen('Flip',s.wHandle);
end