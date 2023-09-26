function t = ImportStimvars(t,toggleDebug)

%% Preexposure

t.exp.temp            = 40;
t.exp.ITI             = 3;

%test stimuli
t.testStim.dur        = 6;
t.testStim.ITI        = [6 8 5 7];

%% Awiszus

t.awis.tRange         = 41.0:0.01:47.0;  % temperature range (°C)
t.awis.popvar         = 1.2;  % assumed sd of threshold (population level)
t.awis.indvar         = 0.4;  % assumed spread of threshold (individual level)
t.awis.temp           = 43.0; % starting value, based on assumed population mu forearm; may be overridden after preexposure check
t.awis.post           = normpdf(t.awis.tRange,t.awis.temp,t.awis.popvar);

t.awis.testTrials     = 2;

%% CORE VARIABLES: Other protocol parameters

t.glob.baseTemp       = 34; % to determine approximate wait time
t.glob.riseSpeed      = 15; % to determine approximate wait time
t.glob.fallSpeed      = 15; % to determine approximate wait time

t.glob.minTemp        = 40;
t.glob.maxTemp        = 48;
t.glob.minThresh      = 41;
t.glob.maxThresh      = 45;
t.glob.defaultThresh  = 42;


t.glob.ratingDur      = 6;
t.glob.sBlank         = 0.5;
t.glob.firstITI       = 3; 
t.glob.lastITI        = 3;

t.glob.cueing         = 1; %switch cueing on or off

t.calib.maxAdapTrials = 6;
t.calib.targetVAS     = [25 40 55 70];
t.calib.VASrange      = 0:10:100;
t.calib.rangeOrder    = [0.5 1 2];

if ~toggleDebug
    t.glob.debug      = 0;
    
    t.awis.nTrials    = 8;         % number of trials for threshold estimation 
    t.awis.stimDur    = 6;
    t.awis.ITI        = [8 12]; % seconds between stimuli; will be randomized between two values - to use constant ITI, use two identical values
    t.awis.cue        = [1.5 2.5]; % jittered time prior to the stimulus that the white cross turns red; can be [0 0] (to turn off red cross altogether), but else MUST NOT BE LOWER THAN 0.5
    
    t.exp.dur         = 20;
    t.testStim.temps  = [42 44 43 45]; 
    
    t.calib.VASOrder  = [10 30 50 70 20 40 60 80];
    t.calib.stimDur   = 6; % to determine approximate wait time % pain stimulus duration
    t.calib.ITI       = [11 15];  
    t.calib.cue       = [1.5 2.5]; 
    
else
    t.glob.debug      = 1;
    
    t.exp.dur         = 2;
    t.testStim.temps  = [42]; 
    
    t.awis.nTrials    = 3;
    t.awis.stimDur    = 2; % to determine approximate wait time
    t.awis.ITI        = [4 5];
    t.awis.cue        = [0.5 1.5];
    
    t.calib.VASOrder  = [10 30 50 70];
    t.calib.stimDur   = 2; % to determine approximate wait time
    t.calib.ITI       = [4 5];
    t.calib.cue       = [0.5 1.5];
    
end

