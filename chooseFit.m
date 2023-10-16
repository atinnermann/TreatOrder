function t = chooseFit(subID,t)

% if Calib == 0
%     try
%         openfig([t.savePath 'Fig_Calib.fig']);
%     catch
%         disp('Could not open Calib figure');
%     end
% end

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

save(t.saveFile, 't');
save(fullfile(t.savePath,sprintf('Sub%02.2d_tVAS.mat',subID)),'tVAS');
end