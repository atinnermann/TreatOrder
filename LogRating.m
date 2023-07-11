 function LogRating(t)
        
        data = [];
        nTrial = t.tmp.trial;
        data(nTrial,1)    = nTrial; 
        data(nTrial,2)    = t.tmp.temp(nTrial);
        data(nTrial,3)    = t.log.awis.thresh;
        data(nTrial,4)    = t.tmp.temp(nTrial) - t.log.awis.thresh;
        data(nTrial,5)    = t.tmp.rating(nTrial);
        data(nTrial,6)    = t.tmp.response(nTrial);
        data(nTrial,7)    = t.tmp.reactionTime(nTrial);
        save(t.tmp.saveName, 'data');      
    end