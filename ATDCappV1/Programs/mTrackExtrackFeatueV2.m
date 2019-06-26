function [ Feature, meanV] = mTrackExtrackFeatueV2( Trace ) 
    global opts;    
    FrontPad = [Trace(1,1)*ones(opts.FilterSize,1),...
                Trace(1,2)*ones(opts.FilterSize,1)];
    EndPad = [Trace(end,1)*ones(opts.FilterSize,1),...
              Trace(end,2)*ones(opts.FilterSize,1)];
    Trace = [FrontPad;Trace;EndPad]; 
    TraceFilt = filter(opts.GaussWin,1,Trace);
    TraceFilt = TraceFilt(opts.FilterSize*2:end-1,:);  
    % extract position feature        
    meanPos = mean(TraceFilt);
    meanPos = [meanPos(1)/size(opts.SampImage,2),meanPos(2)/size(opts.SampImage,1)]; 
    % extract derivative feature
    TraceShiftedRight = [TraceFilt(1,:);TraceFilt(1:(end-1),:)];
    TraceDer = TraceFilt - TraceShiftedRight;    
    TraceDer(1,:) = TraceDer(2,:);
    meanDer = mean(TraceDer);
    meanDer = meanDer/opts.MaxDer;
    % extract direction feature
%         alpha = atan((TraceFilt(end,2)-TraceFilt(1,2))/(TraceFilt(end,1)-TraceFilt(1,2)));
    alpha =  atan(TraceDer(:,2)./TraceDer(:,1));
    meanAlpha = mean(alpha);
    % extract speed feature
    Vx2 = TraceDer(:,1).^2;
    Vy2 = TraceDer(:,2).^2;
    meanV = mean(Vx2+Vy2)/opts.MaxSpeed;
    
    Feature = [meanPos,meanDer,meanAlpha];
end

