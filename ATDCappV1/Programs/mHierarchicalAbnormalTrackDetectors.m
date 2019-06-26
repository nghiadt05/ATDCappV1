function mHierarchicalAbnormalTrackDetectors

global opts;
global SP_OPT;
global TrackResult;

TrackMatDir = dir([opts.TrackFileTmpDir opts.Dataset '*.mat']);
for TrackFileIdx = 1:size(TrackMatDir,1)
    load([opts.TrackFileTmpDir TrackMatDir(TrackFileIdx).name]);
    if strcmp(opts.Dataset,'demoDataset')
        hmmap = imread([SP_OPT.SPTmpDir '/' opts.Dataset '_hmmap.jpg']);
    else
        % need to change the code in here to get the most recent trained
        % superpixel human-like and non-human-like maps
        hmmap = imread([SP_OPT.SPTmpDir '/' opts.Dataset sprintf('_hmmap_%0.5d.png',11050)]);
    end
    
    % Declare the abnormal trajectories set
    AbnTrackDet.ProhibitTrack = [];
    AbnTrackDet.RareTrack = [];
    AbnTrackDet.SlowTrack = [];
    AbnTrackDet.FastTrack = [];
    
    for frmIdx = 1:stateInfo.F
        tmpAbnProhibitTrack = [];
        tmpAbnRareTrack     = [];
        tmpAbnSlowTrack     = [];
        tmpAbnFastTrack     = [];
        % find the track that contains human in the current frame
        trackIdx = find(stateInfo.X(frmIdx,:));
        if ~isempty(trackIdx)            
            % find the track which is long enough 
            for subTrackIdx = trackIdx
                winX = stateInfo.X(max(1,(frmIdx-opts.MinLength+1)):frmIdx,subTrackIdx);
                if (size(find(winX),1) == opts.MinLength) 
                    winY = stateInfo.Y(max(1,(frmIdx-opts.MinLength+1)):frmIdx,subTrackIdx);   
                    % check whether the current track is in the prohibited
                    % area or not                               
                    tmpTrace = [winX,winY];
%                     mShowTracks('Abnormal tracks',opts.SampImage,winX,winY,1.5,false);
                    isInProhibitedArea = false;
                    zeroCnt = 0;
                    for pathIdx = 1:opts.MinLength
                        tmpX = floor(winX);
                        tmpY = floor(winY);
                        Idx = max(tmpX(pathIdx),1); 
                        Idx = min(Idx,opts.MaxHor);
                        Idy = max(tmpY(pathIdx),1);
                        Idy = min(Idy,opts.MaxVer);                        
                        if( hmmap(Idy,Idx) == 0)
                            zeroCnt = zeroCnt + 1;
                        end
                    end
                    if zeroCnt >= SP_OPT.AbnormalThres
                         tmpAbnProhibitTrack = [tmpAbnProhibitTrack, subTrackIdx];
                         isInProhibitedArea = true;
                    end                    
                    % check whether the current track is abnormal interms
                    % of direction or not
                    if ~isInProhibitedArea                        
                        % extract track's features for learning
                        [tmpFeature, tmpSpeed] = mTrackExtrackFeatueV2( tmpTrace );
                        % classify the track using NN 
                        label = TrackResult.net(tmpFeature');
                        label = vec2ind(label);
                        if label ~= 1
                            tmpAbnRareTrack = [tmpAbnRareTrack, subTrackIdx];
%                             mShowTracks('Abnormal tracks',opts.SampImage,winX,winY,1.5,false);
                        end        
                        
                        % check whether the current track is slow, normal or
                        % fast in terms of speed
                        if tmpSpeed <= TrackResult.LowSpeed
                            tmpAbnSlowTrack = [tmpAbnSlowTrack, subTrackIdx];
                        elseif tmpSpeed >= TrackResult.HighSpeed
                            tmpAbnFastTrack = [tmpAbnFastTrack, subTrackIdx];
                        end
                    end                                   
                end
            end
        end 
        
        % assign zero index if there is no abnormal track is
        % detected coresponding to each type of rare
        % trajectories
        if isempty(tmpAbnProhibitTrack)
            tmpAbnProhibitTrack = 0;
        end
        
        if isempty(tmpAbnRareTrack)
            tmpAbnRareTrack = 0;
        end
        
        if isempty(tmpAbnSlowTrack)
            tmpAbnSlowTrack = 0;
        end
        
        if isempty(tmpAbnFastTrack)
            tmpAbnFastTrack = 0;
        end
        
        % accumulate abnormal detection results
        AbnTrackDet.ProhibitTrack{frmIdx} = tmpAbnProhibitTrack;
        AbnTrackDet.RareTrack{frmIdx}     = tmpAbnRareTrack;
        AbnTrackDet.SlowTrack{frmIdx}     = tmpAbnSlowTrack;
        AbnTrackDet.FastTrack{frmIdx}     = tmpAbnFastTrack;
    end
    
    % save to file    
    ADFileName = [opts.AbnDetecDir '/' opts.Dataset sprintf('_AD_s%0.6d_e%0.6d.mat',stateInfo.frameNums(1),stateInfo.frameNums(end))];
    save(ADFileName,'AbnTrackDet','stateInfo');
end