% Interface script for CHEPS thermode, for use with arduino software Thermode v2.3 or higher.
%
% [varargout] = UseThermoino(action,varargin)
%
% Available options are:
%
% UseThermoino('Init',c,b,t,r); where c is the com port used by Thermoino (e.g. 'COM5'), b the baud rate (default 115200), t the starting temperature,
%                                     r the rate of change
% UseThermoino('Help');
% UseThermoino('Diag');
% UseThermoino('Trigger'); or UseThermoino('Trigger',deviceIndex);
% [s] = UseThermoino('Set',t); most common function, with t the target temperature
% [s] = UseThermoino('Set',[40 38],[1 2]); usecase for simultaneous access to two thermoinos (indices 1 and 2)
% [t] = UseThermoino('Move',us); elemental function of 'set' and 'complex', opens port for ramp for us microseconds; 
%                                negative us = ramp down
% [st] = UseThermoino('Complex',ref,seq,lead); where ref is the refractory latency, seq the custom ramp, 
%                                              lead the padding to compensate for cumulative rounding;
%                                              st is a cell array returning both total ramp duration and 
%                                              new temperature
% UseThermoino('Shock',msDur,msIti); generates pulse for shock port (lightning symbol), e.g. for use with digitimer;
%                                    msDur total duration of stimulation im ms, msIti ITI for repeated stimulation within msDur;
%                                    base pulses are 5ms long, will then be separated by msIti within msDur - for example, UseThermoino('Shock',500,100)
%                                    will produce FOUR 5ms shocks (at 0, at 0+5+100=105, at 105+5+100=210, at 210+5+100=315, and at 315+5+100=420
% UseThermoino('InitCTC',msBinSize); kick off complex time course (cTC) transfer by defining the binSize (in ms) in which the cTC info is provided
% [qCTC] = UseThermoino('LoadCTC',cTC,queryLvl,statAbort); loads a single cTC bin to the thermoino (should therefore be used in loop) and appends it to the 
%                                                          existing cTC; also calls queryctc(queryLvl,statAbort) if desired (see below) which can return queryctc 
%                                                          output
% [qCTC] = UseThermoino('QueryCTC',queryLvl,statAbort); queries cTC information on the thermoino (e.g. cTCStatus, cTCBinSize, cTC length, the cTC itself);
%                                                       queryLvl 1 only returns the cTCStatus and verbose status description, queryLvl 2 also includes cTCBinSize,
%                                                       cTC length, cTC execution flag, and the full cTC (which can take some time to transfer); qCTC is optional, 
%                                                       if statAbort is set, cTCStatus 0 will give an error/stop MATLAB execution
% [st] = UseThermoino('ExecCTC',msOffs); executes the cTC on the thermoino (i.e., sends thermode pulses); msOffs requires sum(diff(tC)) to estimate temp at cTC 
%                                        offset; st is optional and includes sum(diff(tC)) and new temp
% UseThermoino('FlushCTC'); resets/deletes all cTC info on the thermoino; can be called individually, but is automatically called via InitCTC
% UseThermoino('Kill'); closes ALL current COM ports
%
% Note: Initializing the arduino with this function (UseThermoino('Init',etc.) will create a variable in base workspace which is queried whenever 
% UseThermoino is called with its various functions. This solution is not as swift as using local variables (about 5x slower), but very convenient.
% The performance impact for a single query is negligible (~0.4ms).
%
% Version: 1.9
% Author: Björn Horing, University Medical Center Hamburg-Eppendorf
% Date: 2019-04-15
%
% Version notes
% 1.1 
% - Moved serial object handles to base workspace
% 1.2 
% - Added functionality for multiple arduinos, which can simply be consecutively 'init'ialized; once more than 1 device
%   is registered in the base workspace thermoino variable, accessing a thermoino requires an index variable together with
%   any UseThermoino subfunction (e.g., UseThermoino('set',40,2) to use the second thermoino for ramping)
% - Added 'complex' for custom ramps (currently intended for use with SlopeAdj)
% - Removed output format option for set
% - Removed automatic 'kill' before 'init' - should be done manually
% - Changed 'set' readOut to double
% 1.3
% - Minor bug fixes, formatting.
% - (!) Changed output format of all readOuts from cell to matrix
% 1.4
% - Implemented non-monotonous capabilities of 'complex'
% 1.5
% - Bugfix at 'shock' (added sprintf to fprintf)
% 1.6 
% - Added complex time course functions (initCTC, loadCTC, queryCTC, execCTC, flushCTC)
% 1.7 
% - Qualified the evalin('base','exist(''thermoino'')') with ''var'' 
% 1.8
% - Added catch condition for license server issues with instrreset in kill
% 1.9
% - Added SHOCK_US function for firmware v2.6
% - Added some sca on error to kill PTB screens
% 2.0
% - Added serial port status confirmation for most commands
% - Now requires thermoino firmware 3.0
% 2.x (tbd)
% - Upgrade to serialport() (from serial()), with backwards compatibility
%
% To do: Make specifying COM port and baud rate for 'init' optional.

function [varargout] = UseThermoino(action,varargin)

if ~nargin
    help UseTermoino;
    return;
end

% define some constants
SMAXWAIT = 5;

ERRORMSG = {}; % errors as defined in Thermode_PWM.ino
ERRORMSG{end+1} = 'ERR_NO_PARAM';
ERRORMSG{end+1} = 'ERR_CMD_NOT_FOUND';
ERRORMSG{end+1} = 'ERR_CTC_BIN_WIDTH';
ERRORMSG{end+1} = 'ERR_CTC_PULSE_WIDTH';
ERRORMSG{end+1} = 'ERR_CTC_NOT_INIT';
ERRORMSG{end+1} = 'ERR_CTC_FULL';
ERRORMSG{end+1} = 'ERR_CTC_EMPTY';
ERRORMSG{end+1} = 'ERR_SHOCK_RANGE';
ERRORMSG{end+1} = 'ERR_SHOCK_ISI';
ERRORMSG{end+1} = 'ERR_BUSY';
ERRORMSG{end+1} = 'ERR_DEBUG_RANGE';

MATLABVersion = cell2mat(regexp(version,'(?<=\(R)\d{4}.*?(?=\))','MATCH')); % some environmental stuff
MATLABYear = str2double(cell2mat(regexp(MATLABVersion,'\d{4}','MATCH')));
MATLABSubVersion = cell2mat(regexp(MATLABVersion,'(?<=\d{4}).*','MATCH'));    
if MATLABYear<2019 || (MATLABYear==2019 && strcmp(MATLABSubVersion,'a'))
    old = true; % toggle for backward compatibility
else
    old = false;
end
old = true; % OVERRIDE FOR NOW, we need to figure this out 2.1+ later...


if ~strcmpi(action,'init') && ~strcmpi(action,'kill') % then we want to do something with the arduino, so we have to check if it has been initialized       
    try
        thermoino = evalin('base','thermoino');
    catch % not really a catch is it
        sca; % kill PTB if necessary
        error('Thermoino not found. Aborting.');
    end
    
    tarTh = 0; % Brienne of; target thermoino (1 default, scalar or vector in case of multiple instantiated serial objects)
    if size(thermoino,2)>1      
        if ( strcmpi(action,'help') || strcmpi(action,'diag') || strcmpi(action,'trigger') ) && nargin>2
            tarTh = varargin{1}; % scalar/vector of Thermoino index/indices
        elseif ( strcmpi(action,'move') || strcmpi(action,'set') ) && nargin>3
            if numel(varargin{1}) ~= numel(varargin{2})
                error('Attempting to access %d Thermoinos with %d %s parameters.',numel(varargin{2}),numel(varargin{1}),upper(action));
            end
            tarTh = varargin{2};   
        elseif strcmpi(action,'shock') && nargin>4
            if ( numel(varargin{1}) ~= numel(varargin{3}) ) || ...
                 numel(varargin{2}) ~= numel(varargin{3})
                error('Attempting to access %d Thermoinos with %d %s parameters.',numel(varargin{3}),upper(action));
            end
        elseif strcmpi(action,'complex')
            if ( numel(varargin{1}) ~= numel(varargin{4}) ) || ...
               ( numel(varargin{2}) ~= numel(varargin{4}) ) || ...
               ( numel(varargin{3}) ~= numel(varargin{4}) )
                error('Attempting to access %d Thermoinos with a insufficient or superfluous %s parameters.',numel(varargin{4}),upper(action));
            end
            tarTh = varargin{4};                                 
        end
        if ~tarTh 
            error('Multiple connected Thermoinos detected, but %s command has insufficient control parameters.\nPlease specify index/indices of Thermoino(s) you intend to access.',upper(action));
        end
    else
        tarTh = 1;
    end
    
    for t = 1:numel(tarTh)
        if thermoino(tarTh(t)).E.old
            flushinput(thermoino(tarTh(t)).H); % always clear leftover blips and chitz
            if ~strcmp(thermoino(tarTh(t)).H.status,'open')
                error('Serial object %d has not been initialized (use UseThermoino(''Init'') first), or connection broke down. Aborting.',t);
            end
        else
            flush(thermoino(tarTh(t)).H,'input');
        end
    end
end

switch lower(action)
    
%-----------------------------------------------------------    
    case 'init' 
        % varargin{1} = COM port
        % varargin{2} = baud rate
        % varargin{3} = baseline temperature
        % varargin{4} = rate of rise

        thermoino = struct;
        thermoino.E.MATLABYear = MATLABYear;
        thermoino.E.MATLABSubVersion = MATLABSubVersion;
        thermoino.E.old = old;
        thermoino.P.sMaxWait = SMAXWAIT;
        thermoino.P.ERRORMSG = ERRORMSG;

        if ischar(varargin{2})
            warning('Baudrate entered as string, but Thermoino expects a number. Attempting to convert via str2double...');
            try
                varargin{2} = str2double(varargin{2});            
            catch
                error('Conversion failed. Check data type for UseThermoino command.');
            end
        end
%         varargin{2} = 115200; % default value for Thermoino v2.3; keep varargin{2} as required input for now 
        try             
            if thermoino.E.old
                thermoino.H = serial(varargin{1},'BaudRate',varargin{2}); % will switch to serialport once we all use 2019b
                %thermoino.H.Terminator = 'CR/LF';
                thermoino.H.Terminator = 'LF';
                fopen(thermoino.H);
            else % then we have 2019 or higher
                thermoino.H = serialport(varargin{1},varargin{2}); % will switch to serialport once we all use 2019b
                %configureTerminator(thermoino.H,'CR/LF');
                configureTerminator(thermoino.H,'LF');
            end            
        catch
            sca; % kill PTB if necessary
            error('Could not initialize Thermoino serial object, not for lack of trying.');
        end
        WaitSecs(1); % give it some time to open connection
        thermoino.P.T = varargin{3};                
        thermoino.P.ROR = varargin{4}; 
        thermoino.P.activeUntil = GetSecs; % for activity flag                
       
        % see if we already have an open Thermoino, in which case we add another entry...
        if evalin('base','exist(''thermoino'',''var'')') % alright let's do some trickery, because evalin does not permit (sub)struct manipulation
            baseThermoino = evalin('base','thermoino');
            for t = 1:size(baseThermoino,2)
                if strcmpi(baseThermoino(t).H.Port,varargin{1})
                    error('You are trying to instantiate a new Thermoino at a port which is already in use. Please use UseThermoino(''Kill'') before you do this.');
                end
            end
            tN = size(baseThermoino,2);
            assignin('base','thermoinoTEMPORARY',thermoino);
            evalin('base',sprintf('thermoino(%d)=thermoinoTEMPORARY',tN+1)); % save it to base
            evalin('base','clear thermoinoTEMPORARY');
        else
            tN = 0;
            assignin('base','thermoino',thermoino); % save it to base
        end
        
        v = UseThermoino('diag',tN+1); % needs base object
        v = str2double(cell2mat(regexp(v{1},'(?<=\+\+\+ V\:)\d+\.*\d*(?= RAM\:)','MATCH')));
        if v<3.0 || isnan(v)
            UseThermoino('kill','Closed due to initialization error.');
            error('Thermoino version %g. UseThermoino requires version 3.0 or higher.\n',v);
        end

%-----------------------------------------------------------
    case { 'help', 'diag' }
        readOut = cell(numel(tarTh),1);        
        for t = 1:numel(tarTh)
            fprintf(thermoino(tarTh(t)).H,upper(action));
            readOut{t} = AwaitStatus(thermoino(tarTh(t)),action,1); % force verbosity
        end
        varargout{1} = readOut;
        

%-----------------------------------------------------------
    case 'trigger' 
        if nargin<2
            verbosity = 0;
        else
            verbosity = varargin{1};
        end
        for t = 1:numel(tarTh)            
            fprintf(thermoino(tarTh(t)).H,'START');
            AwaitStatus(thermoino(tarTh(t)),'START',verbosity);
        end


%-----------------------------------------------------------   
    case 'set'
        if nargin<3
            verbosity = 0;
        else
            verbosity = varargin{2};
        end        
        readOut = numel(tarTh);
        for t = 1:numel(tarTh)
            tmp = varargin{1};
            targetTemp = tmp(t);            
            tUs = round(((targetTemp-thermoino(tarTh(t)).P.T)/thermoino(tarTh(t)).P.ROR)*1e6);
            outCmd = sprintf('MOVE;%d\n',tUs);
            fprintf(thermoino(tarTh(t)).H,outCmd); % this requires ~1-2ms                
            AwaitStatus(thermoino(tarTh(t)),outCmd,verbosity);
        end

        % extra loop for housekeeping
        for t = 1:numel(tarTh)
            tmp = varargin{1};
            targetTemp = tmp(t);
            tUs = round(((targetTemp-thermoino(tarTh(t)).P.T)/thermoino(tarTh(t)).P.ROR)*1e6);            
            evalin('base',sprintf('thermoino(%d).P.T=%1.2f;',tarTh(t),targetTemp)); % this requires ~1-2ms        
            readOut(t) = tUs/1e6;
        end

        if nargout==1
            varargout{1} = readOut; % feed back rise time IN SECONDS
        end        

%-----------------------------------------------------------   
    case 'move' % more basic alternative to 'set'; ramp up (positive numbers) or down (negative numbers) for x microseconds
        if nargin<3
            verbosity = 0;
        else
            verbosity = varargin{2};
        end     

        readOut = numel(tarTh);        
        for t = 1:numel(tarTh)
            tmp = varargin{1};
            rampTime = tmp(t);
            outCmd = sprintf('MOVE;%d\n',round(rampTime));
            fprintf(thermoino(tarTh(t)).H,outCmd);            
            AwaitStatus(thermoino(tarTh(t)),outCmd,verbosity);
        end
        
        % repeat loop for housekeeping
        for t = 1:numel(tarTh)
            tmp = varargin{1};
            rampTime = tmp(t);
            newTemp = (rampTime/1e6)*thermoino(tarTh(t)).P.ROR+thermoino(tarTh(t)).P.T;
            evalin('base',sprintf('thermoino(%d).P.T=%1.2f;',(tarTh(t)),newTemp));
            readOut(t) = round(newTemp,2); %str2double(sprintf('%1.2f',newTemp)); 
        end
        
        if nargout==1
            varargout{1} = readOut; % feed back new temp
        end        

%-----------------------------------------------------------   
    case 'shock'
        % varargin{1} and varargin{2} can be vectors if multiple devices are used
        % varargin{3} is integer
        if nargin<4
            verbosity = 0;
        else
            verbosity = varargin{3};
        end        
        for t = 1:numel(tarTh)
            nReps = varargin{1}(t);
            if nargin>2 && ~isempty(varargin{2}(t))
                ITI = varargin{2}(t);
            else
                ITI = [];
            end
            if isempty(ITI)
                outCmd = sprintf('SHOCK;%d\n',nReps);                
            else
                outCmd = sprintf('SHOCK;%d;%d\n',nReps,ITI);
            end
            fprintf(thermoino(tarTh(t)).H,outCmd);
            AwaitStatus(thermoino(tarTh(t)),outCmd,verbosity);
        end      

%-----------------------------------------------------------   
    case 'complex' 
        error('Deprecated with version UseThermoino version 2.0/Thermode_PWM.ino version 3.0. Use ''initCTC''/''loadCTC''/''execCTC'' instead.');

%-----------------------------------------------------------   
    case 'shock_us'         
        error('Deprecated with version UseThermoino version 2.0/Thermode_PWM.ino version 3.0. Use ''shock'' instead.');

%-----------------------------------------------------------   
    case 'initctc'                 
        if nargin<3
            verbosity = 0;
        else
            verbosity = varargin{2};
        end  
        for t = 1:numel(tarTh)
            outCmd = sprintf('INITCTC;%d\n',varargin{1});
            fprintf(thermoino(tarTh(t)).H,outCmd);
            AwaitStatus(thermoino(tarTh(t)),outCmd,verbosity);
        end         
        
%-----------------------------------------------------------   
    case 'loadctc'
        cTC = varargin{1};
        if nargin<3
            verbosity = 0;
        else
            verbosity = varargin{2};
        end          
        for t = 1:numel(tarTh)
            for m = 1:numel(cTC)
                outCmd = sprintf('LOADCTC;%d\n',cTC(m));
                fprintf(thermoino(tarTh(t)).H,outCmd); % bin by bin, hand over the cTC
                AwaitStatus(thermoino(tarTh(t)),outCmd,verbosity);
            end
        end  

%-----------------------------------------------------------   
    case 'queryctc'                
        
        readOut = '';
        queryLvl = varargin{1};
        if nargin<3
            verbosity = 0;
        else
            verbosity = varargin{2};
        end          
        if ~queryLvl
            for t = 1:numel(tarTh) 
                readOut{t} = [];
            end
        else        
            for t = 1:numel(tarTh)            
                outCmd = sprintf('QUERYCTC;%d\n',queryLvl);
                fprintf(thermoino(tarTh(t)).H,outCmd);
                qCTC = AwaitStatus(thermoino(tarTh(t)),outCmd,verbosity);

                if queryLvl>0
                    readOut{t,1} = cell2mat(regexp(qCTC,'(?<=Status: )\w*','MATCH'));
                end
                
                if queryLvl>1
                    % this is a tad awkward because I could provide the thermoino info (especially the cTC itself) more parseable, but works fine...
                    readOut{t,2} = str2double(cell2mat(regexpi(qCTC,'(?<=ctc_bin_ms\: )\d+','MATCH')));
                    readOut{t,3} = str2double(cell2mat(regexp(qCTC,'(?<=n_ctc\: )\d+','MATCH')));
                end

                if queryLvl>2
                    tmp = regexp(qCTC,'(?<=ctc_data\: ).*','MATCH');
                    tmp = regexp(tmp,'(?<=\d+ )(\-?)\d+(?=\r\n)','MATCH');
                    readOut{t,4} = str2double(tmp{1,1})'; % this is the full time course                    
                end                
            end 
        end
        
        if nargout
            varargout{1} = readOut;
        end

%-----------------------------------------------------------   
    case 'execctc'      
        msOffs = varargin{1};        
        if nargin<3
            verbosity = 0;
        else
            verbosity = varargin{2};
        end           
        for t = 1:numel(tarTh)
            fprintf(thermoino(tarTh(t)).H,'EXECCTC\n');
            AwaitStatus(thermoino(tarTh(t)),'EXECCTC\n',verbosity);
        end
        
        % (sort of) repeat loop for housekeeping
        for t = 1:numel(tarTh)
            newTemp = (msOffs/1000)*thermoino(tarTh(t)).P.ROR+thermoino(tarTh(t)).P.T;
            evalin('base',sprintf('thermoino(%d).P.T=%1.2f;',(tarTh(t)),newTemp));            
            readOut(t,1) = round(msOffs/1000,6); % seconds of difference between cTC(1) and cTC(end)
            readOut(t,2) = round(newTemp,2); % final temperature at cTC(end)
        end        
        
        if nargout==1
            varargout{1} = readOut; % feed back total ramp time and new temp
        end        
        
%-----------------------------------------------------------   
    case 'flushctc'    
        if nargin<2
            verbosity = 0;
        else
            verbosity = varargin{2};
        end        
        for t = 1:numel(tarTh)
            fprintf(thermoino(tarTh(t)).H,'FLUSHCTC\n');
            AwaitStatus(thermoino(tarTh(t)),'flushctc\n',verbosity);
        end                   
        
%-----------------------------------------------------------   
    case 'kill' % closes ALL serial virtual connections, so be careful if you have some you don't want killed        
        warning('UseThermoino will now attempt to close all serial COM objects.');
        if nargin > 1
            if ~ischar(varargin{1}) 
                error('To print a user message, UseThermoino(''kill'') expects a string as an argument.');
            end
            fprintf('%s\n',varargin{1});
        end
        if old
            doManual=1;
            if exist('instrreset','file')
                try
                    instrreset; % requires Instrument Control Toolbox
                    doManual=0;
                end
            end
            if doManual % we do the second best thing
                tmp=instrfind;
                if ~isempty(tmp)
                    fclose(tmp);
                end
            end
        end
        evalin('base','clear thermoino');
        
    otherwise
        error('UseThermoino action not recognized. Aborting.');
        
end

%-----------------------------------------------------
%-----------------------------------------------------
function readOut = AwaitStatus(thermoino,outCmd,verbosity)

    outCmd = regexprep(outCmd,'[\n\r]$','');

    if verbosity
        fprintf('Asked for %s, waiting for Thermoino response... ',upper(outCmd));             
    end
    tQuery = GetSecs;    
    while thermoino.H.BytesAvailable==0 && GetSecs<tQuery+thermoino.P.sMaxWait % wait to get output             
    end            
    readOut = ReadBuffer(thermoino);
    if isempty(readOut)
        error('Query not served within maximum waiting time (%1.1fs).',thermoino.P.sMaxWait)
    elseif str2double(readOut)<0
        error('%s',thermoino.P.ERRORMSG{abs(str2double(readOut))});
    elseif verbosity
        fprintf('received (OK code %d).\n',str2double(readOut));
    end
    flushinput(thermoino.H);


%-----------------------------------------------------
%-----------------------------------------------------
function [str] = ReadBuffer(thermoino)

    str = '';
    while thermoino.H.BytesAvailable
        str = [str fscanf(thermoino.H)];
    end                    
    str = regexprep(str,'\r\n$','');
    

% THEMENSPEICHER
% Find COM port on windows machine https://de.mathworks.com/matlabcentral/answers/110249-how-can-i-identify-com-port-devices-on-windows#answer_120282
% Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
% % Find connected serial devices and clean up the output
% [~, list] = dos(['REG QUERY ' Skey]);
% list = strread(list,'%s','delimiter',' ');
% coms = 0;
% for i = 1:numel(list)
%   if strcmp(list{i}(1:3),'COM')
%       if ~iscell(coms)
%           coms = list(i);
%       else
%           coms{end+1} = list{i};
%       end
%   end
% end
% key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
% % Find all installed USB devices entries and clean up the output
% [~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
% vals = textscan(vals,'%s','delimiter','\t');
% vals = cat(1,vals{:});
% out = 0;
% % Find all friendly name property entries
% for i = 1:numel(vals)
%   if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
%       if ~iscell(out)
%           out = vals(i);
%       else
%           out{end+1} = vals{i};
%       end
%   end
% end
% % Compare friendly name entries with connected ports and generate output
% for i = 1:numel(coms)
%   match = strfind(out,[coms{i},')']);
%   ind = 0;
%   for j = 1:numel(match)
%       if ~isempty(match{j})
%           ind = j;
%       end
%   end
%   if ind ~= 0
%       com = str2double(coms{i}(4:end));
% % Trim the trailing ' (COM##)' from the friendly name - works on ports from 1 to 99
%       if com > 9
%           length = 8;
%       else
%           length = 7;
%       end
%       devs{i,1} = out{ind}(27:end-length);
%       devs{i,2} = com;
%   end
% end
