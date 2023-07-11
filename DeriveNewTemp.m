%% derive new temperature from normal distribution
    function [temp, post] = DeriveNewTemp(temp,painful,tRange,indvar,post)
        % derive normal cumulative distribution
        if painful == 0
            cdfNorm = normcdf(tRange,temp,indvar);
        elseif painful == 1
            cdfNorm = normcdf(tRange,temp,indvar)*-1+1;
        end
        post=post.*cdfNorm;
        
%         % diindvarlay new curves
%         plot(tRange,post)
%         plot(tRange,cdfNorm)
        
        k = 0;
        cdfpost = [];
        for i=1:size(post,2)
            k = k + post(i)/100;
            cdfpost = [cdfpost,k];
        end
        temp = tRange(find(cdfpost >0.5*cdfpost(end),1,'first'));
        temp = round(temp,1);
        
        if painful == 0
            tmpStr = 'NOT PAINFUL';
        elseif painful == 1
            tmpStr = 'PAINFUL';
        end
        fprintf('Stimulus considered %s. ---SET NEXT STIMULUS TO %1.1f°C---.\n',tmpStr,temp);
    end