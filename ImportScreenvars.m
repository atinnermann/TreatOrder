function s = ImportScreenvars(debug,language,hostname)

s.language               = language;
s.hostname               = hostname;
s.screens                = Screen('Screens');                  % Find the number of the screen to be opened
s.screenNumber           = max(s.screens);                     % The maximum is the second monitor
s.screenRes              = Screen('resolution',s.screenNumber);

if debug == 1
    commandwindow;
    PsychDebugWindowConfiguration(0,0.5);                      % Make everything transparent for debugging purposes.
    s.window             = [0 0 s.screenRes.width*0.6 s.screenRes.height*0.6];
else
    ListenChar(-1);
    HideCursor(s.screenNumber);
    s.window             = [0 0 s.screenRes.width s.screenRes.height];
end

s.midpoint               = [s.window(3)/2 s.window(4)/2];       % Find the mid position on the screen.
s.startY                 = s.window(4)/2;

s.fontname               = 'Verdana';
s.fontsize               = 20; %30; %18;
s.linespace              = 8;
s.lineheight             = s.fontsize + s.linespace;
s.white                  = [255 255 255];
s.red                    = [255 0 0];
s.backgr                 = [70 70 70];
s.widthCross             = 3;
s.sizeCross              = 20;

s.Fix1                   = [s.midpoint(1)-s.sizeCross s.startY-s.widthCross s.midpoint(1)+s.sizeCross s.startY+s.widthCross];
s.Fix2                   = [s.midpoint(1)-s.widthCross s.startY-s.sizeCross s.midpoint(1)+s.widthCross s.startY+s.sizeCross];

%%%%%%%%%%%%%%%%%%%%%%%%%%% Default parameters

Screen('Preference', 'Verbosity', 0);
Screen('Preference','SyncTestSettings',0.005,50,0.2,10);
Screen('Preference', 'SkipSyncTests', 1); %was toggleDebug
Screen('Preference', 'DefaultFontSize', s.fontsize);
Screen('Preference', 'DefaultFontName', s.fontname);
%Screen('Preference', 'TextAntiAliasing',2);                       % Enable textantialiasing high quality
Screen('Preference', 'VisualDebuglevel', 0);                       % 0 disable all visual alerts
%Screen('Preference', 'SuppressAllWarnings', 0);


%%%%%%%%%%%%%%%%%%%%%%%%%%% Open a graphics window using PTB

if debug == 1
    s.wHandle                = Screen('OpenWindow', s.screenNumber, s.backgr,s.window);
else
    s.wHandle                = Screen('OpenWindow', s.screenNumber, s.backgr);
end
Screen('Flip',s.wHandle);
s.slack                  = Screen('GetFlipInterval',s.wHandle)./2;

