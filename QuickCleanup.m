 function QuickCleanup(thermoino)
        fprintf('\nAborting...\n');
        if thermoino
            UseThermoino('Kill');
        end
        sca;                                                               % Close window; also closes io64
        ListenChar(0);                                                     % Use keys again
        commandwindow;
end