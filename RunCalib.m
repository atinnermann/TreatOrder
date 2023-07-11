function [abort] = RunCalib(subID)
%if Sub99 is entered, script is run in debug mode with fewer trials,
%shorther ITIs and small/transparent screen

clear mex global
clc

thermoino       = 0; % 0: no thermoino connected; 1: thermoino connected; 2: send trigger directly to thermode via e.g. outp

preExp          = 0;  %40°C preexposure
awisThresh      = 0;  %pain threshold estimation
awisTest        = 0;  %2 stimuli at pain threshold
rangeCalib      = 0;  %3 stimuli to estimate pain range plus adaptive trials
Calib           = 0;  %9 stimuli calibration
chooseFit       = 0;  %choose linear/sigmoid/manual temps
calibTest       = 1;  %2 x 4 stimuli with 4 estimated temps ("25/40/55/70)

[~, hostname]   = system('hostname');

hostname        = deblank(hostname);

language = 'de'; % de or en

if ~any(strcmp(language,{'de','en'}))
    fprintf('Instruction language "%s" not recognized. Aborting...',language);
    QuickCleanup(thermoino);
    return;
end

if nargin == 0
    subID = input('Please enter subject ID.\n');
end

if subID == 99
    toggleDebug = 1;
else
    toggleDebug = 0;
end

if strcmp(hostname,'stimpc1')
    basePath    = '';
else
    basePath    = 'C:\Users\alexandra\Documents\Projects\TreatOrder\Paradigma\Calib';
end

savePath = fullfile(basePath,'LogfilesCalib',sprintf('Sub%02.2d',subID));
mkdir(savePath);
fprintf('Saving data to %s.\n',savePath);


%%%%%%%%%%%%%%%%%%%%%%%
% START
%%%%%%%%%%%%%%%%%%%%%%%

% load all variables
t               = ImportStimvars(toggleDebug);
keys            = ImportKeys(hostname);
com             = ImportCOM(hostname,thermoino);

commandwindow;

t.savePath      = savePath;
t.saveFile      = fullfile(savePath,sprintf('Sub%02.2d_tStruct',subID));

b = load('C:\Users\alexandra\Documents\Projects\TreatOrder\Paradigma\ExpBehav\randOrder_SkinPatches.mat');
t.calib.skinPatch = b.randPatch(subID,:);

if preExp == 1
    warning('Start thermode program AT_preExp and press enter when ready.');
else
    warning('Start thermode program AT_TreatOrd_Calib and press enter when ready.');
end
input(sprintf('Change thermode to skin patch %d and press enter when ready.',t.calib.skinPatch(1)));
WaitSecs(0.5);

% instantiate serial object for thermoino control
if thermoino == 1
    if com.thermoino
        UseThermoino('kill');
        UseThermoino('Init',com.thermoPort,com.thermoBaud,t.glob.baseTemp,t.glob.riseSpeed); % returns handle of serial object
    end
end

s  = ImportScreenvars(toggleDebug,language,hostname);
save([t.savePath '\' sprintf('Sub%02.2d',subID) '_vars_' datestr(now,30)],'t','s','keys','com')

%showing start screen
ShowInstruction(5,keys,s,com,1);
WaitSecs(0.5);

%% Preexposure

if preExp == 1
    
    ShowInstruction(1,keys,s,com,1);
    PreExposure(s,t,com,keys);
    warning('Start thermode program AT_TreatOrd_Calib and press enter when ready.');
    ShowInstruction(4,keys,s,com,1);
    WaitSecs(0.5);
    
end

%% Awiszus pain threshold estimation

if awisThresh == 1
    
    fprintf('\n=======Awiszus Thresholding=======\n');
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_threshold_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %show instructions
    ShowInstruction(2,keys,s,com,1);
    
    %calculate and shuffle ITI and Cue durations
    t.awis.Timings = DetermineITIandCue(t.awis.nTrials,t.awis.ITI,t.awis.Cue);
    
    %estimate pain threshold based on awiszus
    t = AwiszusThresholding(t.awis.Timings,s,t,com,keys);
    fprintf('\nPain threshold estimated at %3.1f°C\n',t.log.awis.thresh);
    
    %plot results
    f1 = figure;
    set(f1,'Visible','off');
    set(f1,'Position',[860 260 500 400]);
    plot(1:t.awis.nTrials,t.log.awis.rating,'ko');
    line([0 t.awis.nTrials+1],[t.log.awis.thresh t.log.awis.thresh]);
    ylim([41 45]);
    
    %control figure appearance and duration appearance
    set(f1, 'Visible', 'on');
    savefig(f1,fullfile(t.savePath,'Awiszus.fig'));
    ShowInstruction(6,keys,s,com,1);
    WaitSecs(0.5);
    close(f1);
    
    %save struct to save all results
    save(t.saveFile, 't');
    
else
    load([t.saveFile '.mat']);
    %delete tmp field to be sure that nothing is mixed up
    if isfield(t,'tmp')
        t = rmfield(t,'tmp');
        save(t.saveFile, 't');
    end
    if ~isfield(t.log.awis,'thresh')
        t.log.awis.thresh = t.glob.defaultThresh;
        warning('Attention! Pain threshold was set to default value (42°C)!');
    else
        fprintf('\nPain threshold was loaded from mat file: %3.1f\n',t.log.awis.thresh);
    end
end


%% Test pain threshold

if awisTest == 1
    
    fprintf('\n=======Test Threshold=======\n');
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_awTest_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %show instructions
    ShowInstruction(3,keys,s,com,1);
    
    %calculate and shuffle ITI and Cue durations
    t.awis.testTimings = DetermineITIandCue(t.awis.testTrials,t.awis.ITI,t.awis.Cue);
    
    %apply test stimuli at threshold temp
    t = RunStim(t.log.awis.thresh,t.awis.testTrials,t.awis.testTimings,s,t,com,keys);
    
    if max(t.tmp.rating) >= 30
        ListenChar;
        commandwindow;
        fprintf('Subject rated pain threshold above 30 with %d VAS\n',max(t.tmp.rating));
        todo = input('How do you want to proceed? Redo thresholding or continue? (thresh/cont): ','s');
        if strcmp(todo,'thresh')
            error('Please restart script to redo thresholding');
        elseif strcmp(todo,'cont')
            testRatings = t.tmp.rating;
            oldThresh = t.log.awis.thresh;
            fprintf('Threshold will be lowered until rating is below 30 VAS\n');
            %necessary step to get focus away from command window
            tFig = figure;set(tFig,'Position',[1200 550 100 100]);pause(1);
            while max(t.tmp.rating) >= 30 && oldThresh > 41
                newThresh = oldThresh - 0.2;
                
                fprintf('Current pain threshold set to %3.1f°C\n',newThresh);
                
                %apply 2 test stimuli at threshold temp
                t = RunStim(newThresh,t.awis.testTrials,t.awis.testTimings,s,t,com,keys);
                testRatings = [testRatings; t.tmp.rating];
                
                oldThresh = newThresh;
            end
            fprintf('\nNew pain threshold estimated at %3.1f°C\n',newThresh);
            t.log.awis.threshOld = t.log.awis.thresh;
            t.log.awis.thresh = newThresh;
            t.tmp.corrRatings = testRatings;
        end
        ListenChar(-1);
        if ishandle(tFig);close(tFig);end
    end
    
    %rename rating fields since they are saved in tmp variable
    t.log.awisTest = t.tmp;
    t = rmfield(t,'tmp');
    
    %save struct to save all results
    save(t.saveFile, 't');
    
end

%% Estimate pain range

if rangeCalib == 1
    
    fprintf('\n=======Estimate pain window=======\n');
    
    %necessary step to get focus away from command window
    tFig = figure;set(tFig,'Position',[1200 550 100 100]);pause(1);
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_range_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %check if pain range has already been estimated
    if isfield(t.log,'range')
        fprintf('\nRange estimation already exists for this sub\n');
        fprintf('\nDeleting old data now\n');
        t.log = rmfield(t.log,'range');
        t.calib.rangeOrder2 = [];
    end
    
    %calculate and shuffle ITI and Cue durations
    t.calib.rangeTimings = DetermineITIandCue(length(t.calib.rangeOrder)+4,t.calib.ITI,t.calib.Cue);
    
    %apply 3 stimuli to estimate pain window
    t = RunStim(t.calib.rangeOrder,[],t.calib.rangeTimings,s,t,com,keys);
    if ishandle(tFig);close(tFig);end
    
    minRat = 35;
    maxRat = 75;
    t.calib.rangeOrder2 = t.calib.rangeOrder;
    %check rating range
    if min(t.tmp.rating) > minRat || max(t.tmp.rating) < maxRat
        newLow = t.calib.rangeOrder(1);
        newHigh = t.calib.rangeOrder(3);
        while min(t.tmp.rating) > minRat
            fprintf('\nLowest pain rating is above %d\n',minRat);
            fprintf('\nAdding a trial with a lower temperature\n');
            newLow = newLow - 0.3;
            if t.log.awis.thresh + newLow < t.glob.minTemp
                fprintf('\nQuitting since a lower temperature than 42 would be applied\n');
                break
            end
            t = RunStim(newLow,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
            t.calib.rangeOrder2 = [t.calib.rangeOrder2 newLow];
        end
        while max(t.tmp.rating) < maxRat
            fprintf('\nHighest pain rating is below %d\n',maxRat);
            fprintf('\nAdding a trial with a higher temperature\n');
            newHigh = newHigh + 0.5;
            if t.log.awis.thresh + newHigh > t.glob.maxTemp
                fprintf('\nQuitting since a higher temperature than 48 would be applied\n');
                break
            end
            t = RunStim(newHigh,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
            t.calib.rangeOrder2 = [t.calib.rangeOrder2 newHigh];
        end
    else
        fprintf('\nAll pain ratings within reasonable range\n');
        fprintf('\nAdding a trial with a middle temperature\n');
        newValue = 1.5;
        t = RunStim(newValue,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
        t.calib.rangeOrder2 = [t.calib.rangeOrder2 newValue];
    end
    
    %estimate linear/sigmoid fit
    t = FitData([t.log.awis.thresh t.tmp.temp],[mean(t.log.awisTest.rating) t.tmp.rating],t.calib.VASrange,t);
    
    %calculate temperatures for next calib step based on better fit
    [~, ind] = ismember(t.calib.VASOrder,t.calib.VASrange);
    
    %choose better fit based on residuals
    if t.tmp.resLin < t.tmp.resSig
        t.calib.temps = round(t.tmp.lin(ind),1);
        fprintf('\nBased on residuals, the linear fit was chosen.\n');
    else
        t.calib.temps = round(t.tmp.sig(ind),1);
        fprintf('\nBased on residuals, the sigmoid fit was chosen.\n');
    end
    
    %control figure appearance and duration appearance
    set(t.hFig, 'Visible', 'on');
    savefig(t.hFig,fullfile(t.savePath,'Fig_Range.fig'));
    ShowInstruction(6,keys,s,com,1);
    close(t.hFig);
    t = rmfield(t,'hFig');
    
    %check fit and either continue, change fit or abort
    f = 0;
    while f == 0
        ListenChar;
        commandwindow;
        yn = input('Do you want to continue? (y/n): ','s');
        if ~isempty(yn)
            f = 1;
        end
    end
    if strcmp(yn,'n')
        fa = input('Do you want to change fit or abort? (fit/abort): ','s');
        if strcmp(fa,'abort')
            return;
        elseif strcmp(fa,'fit')
            fit = input('Which fit do you want to use? (lin/sig): ','s');
            if strcmp(fit,'lin')
                t.calib.temps = round(t.tmp.lin(ind),1);
                fprintf('\nFit has been changed to linear.\n');
            elseif strcmp(fit,'sig')
                t.calib.temps = round(t.tmp.sig(ind),1);
                fprintf('\nFit has been changed to sigmoid.\n');
            end
        end
    end
    ListenChar(-1);
    
    %check for high temperatures
    if any(t.calib.temps > t.glob.maxTemp)
        warning('Caution! Temp higher than 48°C detected, will now lower temp!');
        t.calib.temps(t.calib.temps > t.glob.maxTemp) = t.glob.maxTemp;
    end
    
    %rename rating fields since they are saved in tmp variable
    t.log.range = t.tmp;
    t = rmfield(t,'tmp');
    
    %save struct to save all results
    save(t.saveFile, 't');
    
end

%% Calibration

if Calib == 1
    
    fprintf('\n=======Calibration=======\n');
    
    %necessary step to get focus away from command window
    tFig = figure;set(tFig,'Position',[1200 550 100 100]); pause(1);
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_calib_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %calculate and shuffle ITI and Cue durations
    t.calib.Timings = DetermineITIandCue(length(t.calib.VASOrder),t.calib.ITI,t.calib.Cue);
    
    t = RunStim(t.calib.temps,[],t.calib.Timings,s,t,com,keys);
    if ishandle(tFig);close(tFig);end
    
    %estimate linear and sigmoid fit
    t = FitData([t.log.range.temp t.calib.temps],[t.log.range.rating t.tmp.rating],t.calib.targetVAS,t);
    
    %control figure appearance and duration appearance
    hFig = t.hFig;
    t = rmfield(t,'hFig');
    set(hFig, 'Visible', 'on');
    savefig(hFig,fullfile(t.savePath,'Fig_Calib.fig'));
    ShowInstruction(6,keys,s,com,1);
    set(hFig, 'Visible', 'off');
    
    %check for negative/flat slope and calculate substitute temps for failed
    %calibration
    if any(diff(t.log.calib.sig) < 0.1) ||  any(diff(t.log.calib.lin) < 0.1)
        fprintf('\nSub shows inconsistent ratings with a negative/flat slope.\n');
        fprintf('\nFixed temps are now calculated:\n');
        maxTemp = max(t.tmp.temp);
        maxTempR = t.tmp.rating(t.tmp.temp == maxTemp);
        if maxTemp >= 44
            offset = 1;
        elseif maxTemp < 44
            offset = (maxTemp-t.glob.minTemp)/3;
        end
    if maxTempR > 80
        maxTemp = maxTemp - 0.5;
    elseif maxTempR < 66 && maxTemp <= t.glob.maxTemp - 0.5
        maxTemp = maxTemp + 0.5;
    end
    t.log.calib.fix = [maxTemp-3*offset maxTemp-2*offset maxTemp-offset maxTemp];
    disp(t.log.calib.fix);
    end
    
%rename rating fields since they are saved in tmp variable
t.log.calib =  t.tmp;
t = rmfield(t,'tmp');

%save struct to save all results
save(t.saveFile, 't');

end

%% choose temperatures for calib test and experiment

if chooseFit == 1
    f = 0;
    while f == 0
        ListenChar;
        commandwindow;
        chosenFit = input('What fit do you want to use? (sig/lin/fix/man): ','s');
        if ~isempty(chosenFit)
            f = 1;
        end
    end
    chosenFit = deblank(chosenFit);
    t.log.calib.man = [];
    if strcmpi(chosenFit, 'sig')
        t.calib.test.temps = t.log.calib.sig;
    elseif strcmpi(chosenFit, 'lin')
        t.calib.test.temps = t.log.calib.lin;
    elseif strcmpi(chosenFit, 'fix')
            t.calib.test.temps = t.log.calib.fix;
    elseif strcmpi(chosenFit, 'man')
            temps_vec = input('Which temperatures do you want to use?\nAnswer should be 4 temps in a vector:\n');
            if size(temps_vec,2) ~= 4
                temps_vec = input('\n You did not enter 4 temps in a vector. Please try again:\n');
            end
            t.calib.test.temps = temps_vec;
            t.log.calib.man = temps_vec;
    end
    ListenChar(-1);
    
    tVAS_sig = t.log.calib.sig;
    tVAS_lin = t.log.calib.lin;
    tVAS_man = t.log.calib.man;
    
    %save struct to save all results
    save(t.saveFile, 't');
    save(fullfile(t.savePath,sprintf('Sub%02.2d_tVAS.mat',subID)),'tVAS_sig','tVAS_lin','tVAS_man');  
end

%% Calibration Test
if calibTest == 1
    
    fprintf('\n=======Test Calibration=======\n');
    
    %show wait screen for participant
    ShowInstruction(4,keys,s,com,1);
    WaitSecs(0.5);
    
    t.calib.test.trials = repmat(t.calib.test.temps,1,2);
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_calibTest_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %calculate and shuffle ITI and Cue durations
    t.calib.test.Timings = DetermineITIandCue(size(t.calib.test.trials,2),t.calib.ITI,t.calib.Cue);
    
    %apply 4 experimental temps
    t = RunStim(t.calib.test.trials,[],t.calib.test.Timings,s,t,com,keys);
    
    %rename rating fields since they are saved in tmp variable
    t.log.calibTest = t.tmp;
    t = rmfield(t,'tmp');
    
    %save struct to save all results
    save(t.saveFile, 't');
    
    f2 = figure;
    set(f2,'Position',[860 260 500 400]);
    plot(t.log.calibTest.temp(1:4), mean([t.log.calibTest.rating(1:4)' t.log.calibTest.rating(5:8)'],2), 'kx','MarkerSize',10); hold on
    plot(t.calib.test.temps,t.calib.targetVAS,'ro');
    
    for d = 1:size(t.calib.test.temps,2)
        line([min(t.calib.test.temps)-.3 max(t.calib.test.temps)+.3],repmat(t.calib.targetVAS(d)',1,2),'Color','r','LineStyle', ':');
    end
    
    xlim([min(t.calib.test.temps)-.3 max(t.calib.test.temps)+.3]);
    ylim([0 100]);
    
    savefig(f2,fullfile(t.savePath,'Fig_CalibTest.fig'));
    if ishandle(hFig)
        set(hFig, 'Visible', 'on');
    end
end

%% End

ShowInstruction(4,keys,s,com,1);

QuickCleanup(thermoino);

%%%%%%%%%%%%%%%%%%%%%%%
% END
%%%%%%%%%%%%%%%%%%%%%%%

