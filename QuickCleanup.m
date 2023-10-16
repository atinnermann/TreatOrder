 function QuickCleanup(thermoino)
        fprintf('\nAborting...\n');
        if thermoino
            UseThermoino('Kill');
        end
        sca;                                                               % Close window; also closes io64
        ListenChar;                                                     % Use keys again
        commandwindow;
        clear all
end