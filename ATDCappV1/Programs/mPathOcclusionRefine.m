function mPathOcclusionRefine()
%{
    Due to the occlusion effects that happen for tracked trajectories,
    those paths are discrete at some frames. By interpolatting the missed 
    tracked trajectories, it can significantly raise the quality of training 
    paths.
%}
    global TrackResult;
    fprintf('Fill the occlusion paths ...\n');
    for i = 1:TrackResult.AllIDs
        tmpPath = TrackResult.X(:,i);
        tmpPath = tmpPath ~= 0;
        tmpPathShiftedRight = [tmpPath(1);tmpPath(1:end-1)];
        tmpDiff = tmpPath - tmpPathShiftedRight;
        tmpOccIdx = find(tmpDiff ~= 0);
        fprintf('Occlusion idx and values at HumanID =  %d: \n',i);
        disp(tmpDiff(tmpOccIdx));
        disp(tmpOccIdx);

        % interpolation for occlusion path
        tmpX    = mFillOccPath(TrackResult.X(:,i),tmpOccIdx, tmpDiff);
        tmpY    = mFillOccPath(TrackResult.Y(:,i),tmpOccIdx, tmpDiff);
        tmpH    = mFillOccPath(TrackResult.H(:,i),tmpOccIdx, tmpDiff);
        tmpW    = mFillOccPath(TrackResult.W(:,i),tmpOccIdx, tmpDiff);  
        tmpXgp  = mFillOccPath(TrackResult.Xgp(:,i),tmpOccIdx, tmpDiff);
        tmpYgp  = mFillOccPath(TrackResult.Ygp(:,i),tmpOccIdx, tmpDiff);

        % assign back
        TrackResult.X(:,i) = tmpX;
        TrackResult.Y(:,i) = tmpY;
        TrackResult.H(:,i) = tmpH;
        TrackResult.W(:,i) = tmpW;
        TrackResult.Xgp(:,i) = tmpXgp;
        TrackResult.Ygp(:,i) = tmpYgp;
    end
    fprintf('Fill the occlusion paths ... done\n');
end

