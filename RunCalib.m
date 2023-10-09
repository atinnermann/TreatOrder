function [abort] = RunCalib(subID)
%if Sub99 is entered, script is run in debug mode with fewer trials,
%shorther ITIs and small/transparent screen

clear mex global
clc

thermoino       = 1; % 0: no thermoino connected; 1: thermoino connected; 2: send trigger directly to thermode via e.g. outp

preExp          = 1;  %40°C preexposure
awisThresh      = 1;  %pain threshold estimation
awisTest        = 1;  %2 stimuli at pain threshold
rangeCalib      = 1;  %3 stimuli to estimate pain range plus adaptive trials
Calib           = 1;  %9 stimuli calibration
chooseFit       = 1;  %choose linear/sigmoid/manual temps
calibTest       = 1;  %2 x 4 stimuli with 4 estimated temps ("25/40/55/70)

[~, hostname]   = system('hostname');

t.hostname        = deblank(hostname);

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

if strcmp(t.hostname,'stimpc1')
    t.basePath    = 'D:\tinnermann\TreatOrd\';
elseif strcmp(t.hostname,'isn0068ebea3a78')
    t.basePath    = 'C:\Users\alexandra\Documents\Projects\TreatOrder\Paradigma\';
else
    t.basePath    = 'C:\Users\Mari Feldhaus\Documents\Tinnermann\TreatOrd\';
end

%calibPath = fullfile(t.basePath,'Calib');
savePath = fullfile(t.basePath,'LogfilesCalib',sprintf('Sub%02.2d',subID));
mkdir(savePath);
fprintf('Saving data to %s.\n',savePath);


%%%%%%%%%%%%%%%%%%%%%%%
% START
%%%%%%%%%%%%%%%%%%%%%%%

% load all variables
t               = ImportStimvars(t,toggleDebug);
keys            = ImportKeys(t);
com             = ImportCOM(t,thermoino);

commandwindow;

t.savePath      = savePath;
t.saveFile      = fullfile(savePath,sprintf('Sub%02.2d_tStruct',subID));

% b = load(fullfile(t.basePath,'ExpMRI','randOrder_SkinPatches.mat'));
% t.calib.skinPatch = b.randPatch(subID,:);

% warning('Start thermode program AT_TreatOrd and press enter when ready.');

% input(sprintf('Change thermode to skin patch %d and press enter when ready.',t.calib.skinPatch(1)));
% WaitSecs(0.5);

% instantiate serial object for thermoino control
if thermoino == 1
    if com.thermoino
        UseThermoino('kill');
        UseThermoino('Init',com.thermoPort,com.thermoBaud,t.glob.baseTemp,t.glob.riseSpeed); % returns handle of serial object
    end
end

s  = ImportScreenvars(toggleDebug,language,t.hostname);
save([t.savePath '\' sprintf('Sub%02.2d',subID) '_vars_' datestr(now,30)],'t','s','keys','com')

%showing start screen
ShowInstruction(6,keys,s,com,1);
WaitSecs(0.5);

%% Preexposure

if preExp == 1
    
    ShowInstruction(1,keys,s,com,1);
    PreExposure(s,t,com,keys);

%     ShowInstruction(4,keys,s,com,1);    
%     TestStimuli(s,t,com,keys);
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
    t.awis.timings = DetermineITIandCue(t.awis.nTrials,t.awis.ITI,t.awis.cue);
    
    %estimate pain threshold based on awiszus
    t = AwiszusThresholding(t.awis.timings,s,t,com,keys);
    fprintf('\nPain threshold estimated at %3.1f°C\n',t.log.awis.thresh);
    
    %plot results
    f1 = figure;
    set(f1,'Visible','off');
    set(f1,'Position',[s.screenRes.width*0.05 s.screenRes.height*0.3 s.screenRes.width*0.25 s.screenRes.height*0.3]);
    plot(1:t.awis.nTrials,t.log.awis.rating,'ko');
    line([0 t.awis.nTrials+1],[t.log.awis.thresh t.log.awis.thresh]);
    ylim([41 45]);
    
    %control figure appearance and duration appearance
    set(f1, 'Visible', 'on');
    savefig(f1,fullfile(t.savePath,'Awiszus.fig'));
    fprintf('Please check data/figure and press enter when ready.\n');
    KbWaitKeyPress(keys.name.resume);
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
    t.awis.testTimings = DetermineITIandCue(t.awis.testTrials,t.awis.ITI,t.awis.cue);
    
    %apply test stimuli at threshold temp
    t = RunStim(t.log.awis.thresh,t.awis.testTrials,t.awis.testTimings,s,t,com,keys);
    
    if max(t.tmp.rating) >= 30
        ListenChar;
        commandwindow;
        fprintf('Subject rated pain threshold above 30 with %d VAS\n',max(t.tmp.rating));
        testRatings = t.tmp.rating;
        oldThresh = t.log.awis.thresh;
        fprintf('Threshold will be lowered until rating is below 30 VAS\n');
        %necessary step to get focus away from command window
        tFig = figure;set(tFig,'Position',[s.screenRes.width*0.7 s.screenRes.height*0.6 100 100]);pause(1);
        while max(t.tmp.rating) >= 30 && oldThresh >= t.glob.minThresh + 0.3
            newThresh = oldThresh - 0.3;
            
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
    tFig = figure;set(tFig,'Position',[s.screenRes.width*0.7 s.screenRes.height*0.6 100 100]);pause(1);
    
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
    t.calib.rangeTimings = DetermineITIandCue(length(t.calib.rangeOrder)+t.calib.maxAdapTrials*2,t.calib.ITI,t.calib.cue);
    
    %apply 3 stimuli to estimate pain window
    t = RunStim(t.calib.rangeOrder,[],t.calib.rangeTimings,s,t,com,keys);
    if ishandle(tFig);close(tFig);end
    
    %check rating range
    %when rating is above 35 and/or below 75, adaptive trials will be
    %added. For lower trials, temp will be reduced by 0.3°C while for 
    %higher trials 0.5°C are added per trial. Maximum of 6 adaptive trials,
    %2 for lower and 4 for higher temps
    minRat = 35;
    maxRat = 70;
    t.calib.rangeOrder2 = t.calib.rangeOrder;
    if min(t.tmp.rating) > minRat || max(t.tmp.rating) < maxRat 
        newLow = t.calib.rangeOrder(1);
        newHigh = t.calib.rangeOrder(3);
        aT = 1;
        while min(t.tmp.rating) > minRat && aT <= 2
            fprintf('\nLowest pain rating is above %d\n',minRat);
            fprintf('\nAdding a trial with a lower temperature\n');
            newLow = newLow - 0.3;
            if t.log.awis.thresh + newLow < t.glob.minTemp
                fprintf('\nQuitting since a lower temperature than %d°C would be applied\n',t.glob.minTemp);
                break
            end
            t = RunStim(newLow,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
            t.calib.rangeOrder2 = [t.calib.rangeOrder2 newLow];
            aT = aT + 1;
        end
        while max(t.tmp.rating) < maxRat && aT <= t.calib.maxAdapTrials
            fprintf('\nHighest pain rating is below %d\n',maxRat);
            fprintf('\nAdding a trial with a higher temperature\n');
            newHigh = newHigh + 0.5;
            if t.log.awis.thresh + newHigh > t.glob.maxTemp
                fprintf('\nQuitting since a higher temperature than %d°C would be applied\n',t.glob.maxTemp);
                break
            end
            t = RunStim(newHigh,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
            t.calib.rangeOrder2 = [t.calib.rangeOrder2 newHigh];
            aT = aT + 1;
            %if after 6 adaptive trials the rating is still below maxRat,
            %temps will be increased by 1° until 48° are reached
            if max(t.tmp.rating) < maxRat && aT == t.calib.maxAdapTrials
                fprintf('\nAfter 6 trials highest pain rating is still below %d\n',maxRat);
                while max(t.tmp.rating) < maxRat && t.log.awis.thresh + newHigh <= t.glob.maxTemp
                    newHigh = newHigh + 1;
                    t = RunStim(newHigh,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
                    t.calib.rangeOrder2 = [t.calib.rangeOrder2 newHigh];
                end           
            end
        end      
    else
        fprintf('\nAll pain ratings within reasonable range\n');
        fprintf('\nAdding a trial with a middle temperature\n');
        newValue = 1.5;
        t = RunStim(newValue,[length(t.calib.rangeOrder2) 1],t.calib.rangeTimings,s,t,com,keys);
        t.calib.rangeOrder2 = [t.calib.rangeOrder2 newValue];
    end
    
    %estimate linear/sigmoid fit
    t = FitData([t.log.awis.thresh t.tmp.temp],[mean(t.log.awisTest.rating) t.tmp.rating],t.calib.VASrange,t,s);
    
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
    
    %check for high temperatures
    if any(t.calib.temps > t.glob.maxTemp)
        warning('Caution! Temp higher than 48°C detected, will now lower temp!');
        t.calib.temps(t.calib.temps > t.glob.maxTemp) = t.glob.maxTemp;
    end
    
    %control figure appearance and duration appearance
    set(t.hFig, 'Visible', 'on');
    savefig(t.hFig,fullfile(t.savePath,'Fig_Range.fig'));
    fprintf('Please check data/figure and press enter when ready.\n');
    KbWaitKeyPress(keys.name.resume);
    close(t.hFig);
    t = rmfield(t,'hFig');

    %rename rating fields since they are saved in tmp variable
    t.log.range = t.tmp;
    t = rmfield(t,'tmp');
    
    %estimate linear/sigmoid fit for target VAS based on range ratings
    t = FitData([t.log.awis.thresh t.log.range.temp],[mean(t.log.awisTest.rating) t.log.range.rating],t.calib.targetVAS,t,s);
    if t.tmp.resLin < t.tmp.resSig
        t.log.range.targetFit = t.tmp.lin;
    elseif t.tmp.resLin > t.tmp.resSig
        t.log.range.targetFit = t.tmp.sig;
    end
    t = rmfield(t,'tmp');
    
    %save struct to save all results
    save(t.saveFile, 't');
    
end

%% Calibration

if Calib == 1
    
    fprintf('\n=======Calibration=======\n');
    
    %necessary step to get focus away from command window
    tFig = figure;set(tFig,'Position',[s.screenRes.width*0.7 s.screenRes.height*0.6 100 100]); pause(1);
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_calib_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %calculate and shuffle ITI and Cue durations
    t.calib.timings = DetermineITIandCue(length(t.calib.VASOrder),t.calib.ITI,t.calib.cue);
    
    t = RunStim(t.calib.temps,[],t.calib.timings,s,t,com,keys);
    if ishandle(tFig);close(tFig);end
    
    %estimate linear and sigmoid fit
    t = FitData([t.log.range.temp t.calib.temps],[t.log.range.rating t.tmp.rating],t.calib.targetVAS,t,s);
    
    %control figure appearance and duration appearance
    hFig = t.hFig;
    t = rmfield(t,'hFig');
    set(hFig, 'Visible', 'on');
    savefig(hFig,fullfile(t.savePath,'Fig_Calib.fig'));
    
    fprintf('Please check data/figure and press enter when ready.\n');
    KbWaitKeyPress(keys.name.resume);
    set(hFig, 'Visible', 'off');
    
    %rename rating fields since they are saved in tmp variable
    t.log.calib =  t.tmp;
    t = rmfield(t,'tmp');
    
    %save struct to save all results
    save(t.saveFile, 't');
    
end

%% choose temperatures for calib test and experiment

if chooseFit == 1
    
    if Calib == 0
        try
            openfig([t.savePath 'Fig_Calib.fig']);
        catch
            disp('Could not open Calib figure');
        end
    end
    
    %check fit before choosing
    if t.log.calib.resLin < t.log.calib.resSig
        fprintf('\nBased on residuals, linear fit is better.\n');
        t.log.calib.bestFit = 1;
    elseif t.log.calib.resSig < t.log.calib.resLin
        fprintf('\nBased on residuals, sigmoid fit is better.\n');
        t.log.calib.bestFit = 2;
    end
    if (any(diff(t.log.calib.lin) <= 0) && t.log.calib.bestFit == 1) || (any(diff(t.log.calib.sig) <= 0) && t.log.calib.bestFit == 2)
        fprintf('\nSub shows inconsistent ratings with a negative slope.\n');
        fprintf('\nConsider other fit or fixed temperatures.\n');
    elseif (any(diff(t.log.calib.lin) <= 0.2) && t.log.calib.bestFit == 1) || (any(diff(t.log.calib.sig) <= 0.2) && t.log.calib.bestFit == 2)
        fprintf('\nSub needs temperatures that are 0.2° or less apart.\n');
        fprintf('\nConsider other fit or fixed temperatures.\n');
    elseif (any(diff(t.log.calib.lin) >= 2) && t.log.calib.bestFit == 1) || (any(diff(t.log.calib.sig) >= 2) && t.log.calib.bestFit == 2)
        fprintf('\nSub needs temperatures that are 2° or more apart.\n');
        fprintf('\nConsider other fit or fixed temperatures.\n');
    end

    %calculate fixed temperatures in case they are needed
    maxTemp = max(t.log.calib.temp);
    maxRat = max(t.log.calib.rating(t.log.calib.temp == maxTemp));
%     if maxTemp >= 45.5 && (max(t.log.calib.rating)-min(t.log.calib.rating)) < 50 && any(diff(t.log.calib.temp) >= 1)
%         offset = 1.5;
    if maxTemp <= 44
        offset = (maxTemp-t.glob.minTemp)/3;
    else
        offset = 1;
    end
    if maxRat > 80
        maxTemp = maxTemp - 0.5;
    elseif maxRat < 66 && maxTemp <= t.glob.maxTemp - 0.5
        maxTemp = maxTemp + 0.5;
    end
    t.log.calib.fix = [maxTemp-3*offset maxTemp-2*offset maxTemp-offset maxTemp];
    
    %if range fit was good but calib ratings are too narrow, range fit is changed accordingly
    if (max(t.log.calib.rating)-min(t.log.calib.rating)) < 60
        fprintf('\nRating range is small. Consider range or fixed fit.\n');
        if max(t.log.calib.rating) < 60
            fprintf('\nSub rated all temps below 60 VAS.\n');
            if (max(t.log.range.rating)-min(t.log.range.rating)) > 50
                t.log.range.targetFit = t.log.range.targetFit + 0.5;
                fprintf('\nRange fit was changed based on calib ratings.');
            end
        elseif min(t.log.calib.rating) > 50
            fprintf('\nSub rated all temps above 50 VAS.\n');
            if (max(t.log.range.rating)-min(t.log.range.rating)) > 50
                t.log.range.targetFit = t.log.range.targetFit - 0.5;
                fprintf('\nRange fit was changed based on calib ratings.');
            end
        elseif min(t.log.calib.rating) > 30 && max(t.log.calib.rating) < 60
            fprintf('\nSub rated all temps between 30 and 60 VAS.\n');
            if (max(t.log.range.rating)-min(t.log.range.rating)) > 50
               t.log.range.targetFit = [t.log.range.targetFit(1)-0.75 t.log.range.targetFit(2)-0.25 t.log.range.targetFit(3)+0.25 t.log.range.targetFit(4) + 0.75];
               fprintf('\nRange fit was changed based on calib ratings.');
            end 
        end
    end
    
    fprintf('\nSuggested temps are:\n');
    fprintf('   sig       lin       ran       fix\n');
    disp([t.log.calib.sig' t.log.calib.lin' t.log.range.targetFit' t.log.calib.fix']);
    
    
    f = 0;
    while f == 0
        ListenChar;
        commandwindow;
        chosenFit = input('What fit do you want to use? (sig/lin/ran/fix/man): ','s');
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
        elseif strcmpi(chosenFit, 'ran')
        t.calib.test.temps = t.log.range.targetFit;
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
    
    tVAS.sig = t.log.calib.sig;
    tVAS.lin = t.log.calib.lin;
    tVAS.ran = t.log.range.targetFit;
    tVAS.fix = t.log.calib.fix;
    tVAS.man = t.log.calib.man;
    
    %save struct to save all results
    save(t.saveFile, 't');
    save(fullfile(t.savePath,sprintf('Sub%02.2d_tVAS.mat',subID)),'tVAS');
end

%% Calibration Test
if calibTest == 1
    
    fprintf('\n=======Test Calibration=======\n');
    
%     %show wait screen for participant
%     ShowInstruction(4,keys,s,com,1);
%     WaitSecs(0.5);
    
    t.calib.test.trials = repmat(t.calib.test.temps,1,2);
    
    %define file name for saving results
    fileName        = [sprintf('Sub%02.2d',subID) '_calibTest_' datestr(now,30)];
    t.tmp.saveName  = fullfile(t.savePath,fileName);
    
    %calculate and shuffle ITI and Cue durations
    t.calib.test.timings = DetermineITIandCue(size(t.calib.test.trials,2),t.calib.ITI,t.calib.cue);
    
    %apply 4 experimental temps
    t = RunStim(t.calib.test.trials,[],t.calib.test.timings,s,t,com,keys);
    
    %rename rating fields since they are saved in tmp variable
    t.log.calibTest = t.tmp;
    t = rmfield(t,'tmp');
    
    %save struct to save all results
    save(t.saveFile, 't');
    
    f2 = figure;
    set(f2,'Position',[s.screenRes.width*0.05 s.screenRes.height*0.3 s.screenRes.width*0.25 s.screenRes.height*0.3]);
    plot(t.log.calibTest.temp(1:4), nanmean([t.log.calibTest.rating(1:4)' t.log.calibTest.rating(5:8)'],2), 'kx','MarkerSize',10); hold on
    plot(t.calib.test.temps,t.calib.targetVAS,'ro');
    
    for d = 1:size(t.calib.test.temps,2)
        line([min(t.calib.test.temps)-.3 max(t.calib.test.temps)+.3],repmat(t.calib.targetVAS(d)',1,2),'Color','r','LineStyle', ':');
    end
    
    xlim([min(t.calib.test.temps)-.3 max(t.calib.test.temps)+.3]);
    ylim([0 100]);
    
    savefig(f2,fullfile(t.savePath,'Fig_CalibTest.fig'));
end

%% End

ShowInstruction(5,keys,s,com,1);

QuickCleanup(thermoino);

%%%%%%%%%%%%%%%%%%%%%%%
% END
%%%%%%%%%%%%%%%%%%%%%%%

