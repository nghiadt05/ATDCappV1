function mPathCentroidFilter
    global TrackResult;  
    fprintf('Apply Gaussian filter for all human centroids ...');    
    FilterSize = 7;
    assert(mod(FilterSize,2)==1,'Filter size must be an odd number');
    GaussWin   = gausswin(FilterSize); 
    PaddingSize = (FilterSize-1)/2;
    GaussWin = GaussWin/sum(GaussWin);   
    % visuallization 
%     close all;
%     figure();
    for i=1:TrackResult.AllIDs
        % take the original path
        Frames = find(TrackResult.X(:,i));
        X   = TrackResult.X(Frames,i);
        Y   = TrackResult.Y(Frames,i);
        Xgp = TrackResult.Xgp(Frames,i);        
        Ygp = TrackResult.Ygp(Frames,i);
        % pad the path for filtering
        X = [X(1)*ones(PaddingSize,1);X;X(end)*ones(PaddingSize,1)];
        Y = [Y(1)*ones(PaddingSize,1);Y;Y(end)*ones(PaddingSize,1)];
        Xgp = [Xgp(1)*ones(PaddingSize,1);Xgp;Xgp(end)*ones(PaddingSize,1)];
        Ygp = [Ygp(1)*ones(PaddingSize,1);Ygp;Ygp(end)*ones(PaddingSize,1)];
        % filter 
        XFilterd = filter(GaussWin,1,X); XFilterd = XFilterd(PaddingSize*2+1:end);
        YFilterd = filter(GaussWin,1,Y); YFilterd = YFilterd(PaddingSize*2+1:end);
        XgpFilterd = filter(GaussWin,1,Xgp); XgpFilterd = XgpFilterd(PaddingSize*2+1:end);
        YgpFilterd = filter(GaussWin,1,Ygp); YgpFilterd = YgpFilterd(PaddingSize*2+1:end);  
        % assign back to the data structure
        TrackResult.X(Frames(1):Frames(end),i) = XFilterd;
        TrackResult.Y(Frames(1):Frames(end),i) = YFilterd;
        TrackResult.Xgp(Frames(1):Frames(end),i) = XgpFilterd;
        TrackResult.Ygp(Frames(1):Frames(end),i) = YgpFilterd;
        % visuallization       
%         clf;
%         line(X,Y,'color','r');
%         line(XFilterd,YFilterd,'color','g');
%         line(Xgp,Ygp,'color','k');
%         line(XgpFilterd,YgpFilterd,'color','b');
    end
    fprintf(' done\n');
end