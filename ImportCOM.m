function com = ImportCOM(hostname,thermoino)

if thermoino == 1
    if strcmp(hostname,'stimpc1')
        addpath('');
        com.thermoPort    = 'COM11';
        com.thermoBaud    = 115200;
        com.thermoino     = thermoino;  
        com.CEDTrigger = 4; % Trigger bits for device
    elseif strcmp(hostname,'isn0068ebea3a78')   
        addpath('C:\Users\alexandra\Documents\MATLAB\toolbox\Thermoino');
        com.thermoPort    = 'COM5';
        com.thermoBaud    = 115200;
        com.thermoino     = thermoino;
        com.CEDTrigger = 255; % Trigger bits for thermode
    else
        addpath('C:\Users\Mari Feldhaus\Documents\MATLAB\thermoino');
        com.thermoPort    = 'COM5';
        com.thermoBaud    = 115200;
        com.thermoino     = thermoino; 
        com.CEDTrigger = 255; % Trigger bits for thermode     
    end
elseif thermoino == 2 
    com.CEDport     = 255; % Trigger bits for thermode
    com.CEDaddress  = 888;
    com.CEDduration = 0.005;
    addpath('C:\Users\Mari Feldhaus\Documents\MATLAB\IO_64bit');
    config_io;
    outp(com.CEDaddress,0);
    
end

com.thermoino     = thermoino;