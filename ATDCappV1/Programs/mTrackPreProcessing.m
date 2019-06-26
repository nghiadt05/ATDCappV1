function mTrackPreProcessing

global TrackResult;
global opts;

%% read tracking data from files then format them 
TrackMatDir = dir([opts.TrackFileTmpDir opts.Dataset '*.mat']);
X = []; Y = []; W = []; H = [];
for TrackFileIdx = 1:size(TrackMatDir,1)
    load([opts.TrackFileTmpDir TrackMatDir(TrackFileIdx).name]);
    % padding for the non sufficient stateInfor
    if stateInfo.F < opts.FrameInterval
        pads = zeros(opts.FrameInterval-size(stateInfo.X,1),size(stateInfo.X,2));
        stateInfo.X = [stateInfo.X;pads];
        stateInfo.Y = [stateInfo.Y;pads];
        stateInfo.W = [stateInfo.W;pads];
        stateInfo.H = [stateInfo.H;pads];       
    end   
    X = [X,stateInfo.X];
    Y = [Y,stateInfo.Y];
    W = [W,stateInfo.W];
    H = [H,stateInfo.H];
    % remove dummy tracks
    dummyIndx = [];
    for i = 1:size(X,2)
        tmpX = X(:,i); tmpX = round(tmpX);
        tmpY = Y(:,i); tmpY = round(tmpY);      
        dummyIndX = size(find(tmpX==79),1);
        dummyIndY = size(find(tmpY==940),1);
        if ( ( dummyIndX == dummyIndY) ...
               && dummyIndX > 0 ...
               && dummyIndY > 0 )
           dummyIndx = [dummyIndx;i];
        end
    end
    if ~isempty(dummyIndx)
        X(:,dummyIndx) = [];
        Y(:,dummyIndx) = [];
        H(:,dummyIndx) = [];
        W(:,dummyIndx) = [];
    end
end
TrackResult.X       = X;
TrackResult.Y       = Y;
TrackResult.Xgp     = X;
TrackResult.Ygp     = Y;
TrackResult.H       = H;
TrackResult.W       = W;
TrackResult.AllIDs  = size(TrackResult.X,2);

%% Find the occlusion paths of a person then interpolate it    
mPathOcclusionRefine;    
%% Apply Gaussian filter for all human centroids
mPathCentroidFilter;

