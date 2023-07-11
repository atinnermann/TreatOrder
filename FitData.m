function t = FitData(temps,rating,target_vas,t)

X = temps';
y = round(rating)';

X = X(~isnan(y));
y = y(~isnan(y));
trials = [1:numel(X)]';

if length(y) == 3
    warning('Only 3 ratings detected, fit might not be reliable');
elseif length(y) < 3
    error('Less than 3 ratings detected, please repeat this part of the calibration');
end

% estimate linear function
blin = [ones(numel(X),1) X]\y;
for vas = 1:size(target_vas,2)
    est_lin(vas) = linreverse(blin,target_vas(vas));
end

% estimate sigmoid function
a = mean(X); b = 1; % L = 0; U = 100; % l/u bounds to be fitted
beta0 = [a b];
options = statset('Display','final','Robust','on','MaxIter',10000);
[bsig,~] = nlinfit(X,y,@localsigfun,beta0,options);

for vas = 1:size(target_vas,2)
    est_sig(vas) = sigreverse([bsig -1 101],target_vas(vas));
end

t.tmp.sig = est_sig;
t.tmp.lin = est_lin;

% plot
t.hFig = figure;
set(t.hFig,'Visible','off');
set(t.hFig,'Position',[860 260 500 400]);
xplot = 40:.1:48;
plot(X,y,'kx',xplot,localsigfun(bsig,xplot),'r',...
    est_sig,localsigfun(bsig,est_sig),'ro',est_lin,target_vas,'bd',...
    xplot,blin(1)+xplot.*blin(2),'b--');hold on
plot(X,y,'kx','MarkerSize',12);
xlim([min(xplot)-.5 max(xplot)+.5]); ylim([0 100]);

% calculate residuals for linear function and  sigmoid function
res_lin_sum = 0;
res_sig_sum = 0;
for nTrial = 1:length(trials)
    est_lin_ind = linreverse(blin,y(nTrial));
    res_lin_ind = abs(est_lin_ind - X(nTrial));
    res_lin_sum = res_lin_sum + res_lin_ind;
    
    est_sig_ind = sigreverse([bsig -1 101],y(nTrial));
    res_sig_ind = abs(est_sig_ind - X(nTrial));
    res_sig_sum = res_sig_sum + res_sig_ind;
end

t.tmp.resLin = res_lin_sum;
t.tmp.resSig = res_sig_sum;

% display
results = [trials X y];
results = sortrows(results,2);
for vas = 1:size(results,1)
    fprintf('Trial %d : \tTemp: %2.1f °C \tVAS: %d\n',results(vas,1),results(vas,2),results(vas,3));
end

fprintf('\nEstimates from  fit (n=%d)\n',length(trials));
for vas = 1:size(target_vas,2)
    fprintf('VAS %d : \tsigmoid: %2.1f °C \tlinear: %2.1f °C\n',target_vas(vas),est_sig(vas),est_lin(vas));
end

fprintf('\nResidual sum of sigmoid fit : %2.1f\n',res_sig_sum);
fprintf('Residual sum of linear fit  : %2.1f\n',res_lin_sum);

% Check - was the whole scale used?
fprintf('\nCheck for minimal and maximal rating:\n');
fprintf('Minimal rating: %d, Temperature: %3.1f \n', min(y), X(y == min(y)));
fprintf('Maximal rating: %d, Temperature: %3.1f \n', max(y), X(y == max(y)));
fprintf('Rating range(max-min rating): %d\n\n', max(y)-min(y));

end
%% estimate sigmoid fit
    function xsigpred = sigreverse(bsig1,ytarget)
        v=.5; a1 = bsig1(1); b1 = bsig1(2); L1 = bsig1(3); U1 = bsig1(4);
        xsigpred = a1 + 1/-b1 * log((((U1-L1)/(ytarget-L1))^v-1)./v);
    end

%% estimate linear fit
    function xlinpred = linreverse(blin1,ytarget)
        a1 = blin1(1); b1 = blin1(2);
        xlinpred = (ytarget - a1) / b1;
    end

%%
    function yhat = localsigfun(b0,x)    
        a = b0(1);
        b = b0(2);
        L = 0;%b0(3);
        U = 100;%b0(4);
        v = 0.5;
        
        yhat = (L + ((U-L) ./ (1+v.*exp(-b.*(x-a))).^(1/v)));
    end