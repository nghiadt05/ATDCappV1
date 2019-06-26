function [ outX ] = FillOccPath( tmpX, tmpOccIdx, tmpDiff )
    global opt;
    % assigne the temporal value
%     tmpX = TrackResult.X(:,2);

    % find all possible occlusion paths
    tmpOccPaths = [];
    if length(tmpOccIdx) > 2
        for i = 1:(length(tmpOccIdx)-1)
            if( tmpDiff(tmpOccIdx(i)) == -1 )
                tmpOccPaths = [tmpOccPaths;[tmpOccIdx(i),tmpOccIdx(i+1)-1]];
            end
        end
    end

    % start interpolation for each occlusion path
    for i = 1:size(tmpOccPaths,1)
         FPredictFrames = tmpOccPaths(i,1):(tmpOccPaths(i,1)+floor((tmpOccPaths(i,2)-tmpOccPaths(i,1))/2));
         BPredictFrames = (FPredictFrames(end)+1):tmpOccPaths(i,2);
         LinStep = (tmpX(tmpOccPaths(i,2)+1)-tmpX(tmpOccPaths(i,1)-1))/(tmpOccPaths(i,2)-tmpOccPaths(i,1)+3);
         tmpBase = tmpX(tmpOccPaths(i,1)-1);
         for frameIdx = FPredictFrames
             %disp(frameIdx);         
             Xb             = tmpX((frameIdx-opt.FilterSize):(frameIdx-1));
             XbShiftLeft    = tmpX((frameIdx-1-opt.FilterSize):(frameIdx-2));
             XbDiff         = Xb-XbShiftLeft;
             GaussWinb      = opt.GaussWin(1:opt.FilterSize).*(Xb~=0);   
             pDiff          = 2*sum(XbDiff.*GaussWinb);
             tmpX(frameIdx) = (pDiff + tmpX(frameIdx-1) + (tmpBase+LinStep*(frameIdx-tmpOccPaths(i,1)+2)))/2 ;
%              fprintf('frameIdx = %d pDiff = %0.3f mean = %0.3f\n',frameIdx,pDiff,mean(XbDiff));
         end
          
         if size(BPredictFrames,2)>0
             for frameIdx = BPredictFrames(end):-1:BPredictFrames(1)
                 Xa             = tmpX((frameIdx+1):(frameIdx+opt.FilterSize));
                 XaShiftRight   = tmpX((frameIdx+2):(frameIdx+1+opt.FilterSize));
                 XaDiff         = XaShiftRight - Xa;
                 GaussWina      = opt.GaussWin(opt.FilterSize+1:end).*(Xa~=0);
                 pDiff          = 2*sum(XaDiff.*GaussWina);
                 tmpX(frameIdx) = (tmpX(frameIdx+1) - pDiff + (tmpBase+LinStep*(frameIdx-tmpOccPaths(i,1)+2)))/2;
    %              fprintf('frameIdx = %d pDiff = %0.3f mean = %0.3f\n',frameIdx,pDiff,mean(XaDiff));
             end
         end
    end
    
    outX = tmpX;
end

