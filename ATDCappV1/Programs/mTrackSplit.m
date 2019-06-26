function [ SampleTrack, NoOfSample ] = mTrackSplit(X,Y,TrackLabel)
    global opts;
    NoOfSample = 1;
    for i=1:size(X,2)
        NoOfTrackFrame = find(X(:,i));
        if(size(NoOfTrackFrame,1)>=opts.MinLength)
            tmpX = X(NoOfTrackFrame,i);
            tmpY = Y(NoOfTrackFrame,i);
            lastFrame = opts.MinLength;
            while(lastFrame<=size(tmpX,1))
                Xshort = tmpX(lastFrame-opts.MinLength+1:lastFrame);
                Yshort = tmpY(lastFrame-opts.MinLength+1:lastFrame);
                SampleTrack{NoOfSample}.Trace = [Xshort,Yshort];
                SampleTrack{NoOfSample}.Label = TrackLabel;
                NoOfSample = NoOfSample + 1;
                lastFrame = lastFrame + opts.SampleFrameDist;
            end
        end
    end
    NoOfSample = NoOfSample -1;
end

