function mAllFeatureExtractionV2()    
    global TrackResult;   
    global opts;
%     close all;
%     figure();   
    if ~exist('./tmp/mAbnormalTrackDetection/Feature.mat','file')      
        TrackFeature = [];
        TrackLabel = [];
        TrackSpeed = [];
        TrackSpeedLabel = [];
        st=clock;
        fprintf('Feature extraction ...\n');      
        LearningDataSize = size(TrackResult.AllSamplePaths,2);
        for i=1:LearningDataSize
            fprintf('Feature extraction %d/%d\n',i,LearningDataSize);
            % filt the trace using Gaussian filter        
            Trace = TrackResult.AllSamplePaths{i}.Trace; 
            Label = TrackResult.AllSamplePaths{i}.Label; 
            % extract the features
            [Feature, meanV] = mTrackExtrackFeatueV2( Trace ); 
            % add to the feature matrix
            TrackFeature = [TrackFeature;Feature];
            TrackLabel = [TrackLabel;Label];
            TrackSpeed = [TrackSpeed,meanV];
    %         clf;
    %         line(Trace(:,1),Trace(:,2),'color','b'); hold all;
    %         line(TraceFilt(:,1),...
    %              TraceFilt(:,2),'color','r');
        end

        % classify the speed feature into three main labels: slow, normal and
        % fast based on the collected speed then extract speed feature from
        % that
        TrackMeanSpeed = mean(TrackSpeed);
        TrackSpeedStdDev = sqrt(mean((TrackSpeed - TrackMeanSpeed).^2));
        LowSpeed = TrackMeanSpeed - opts.LowSpeedGain*TrackSpeedStdDev;
        HighSpeed = TrackMeanSpeed + opts.HighSpeedGain*TrackSpeedStdDev;

        for i=1:LearningDataSize
            CurSpeed = TrackSpeed(i);
            CurSpeedLabel = [0;0;0];
            if (CurSpeed<=LowSpeed)
                CurSpeedLabel = [1;0;0];
            elseif( (CurSpeed>LowSpeed) && (CurSpeed<HighSpeed))
                CurSpeedLabel = [0;1;0];
            else
                CurSpeedLabel = [0;0;1];
            end
            TrackSpeedLabel = [TrackSpeedLabel,CurSpeedLabel];
        end
        
        fprintf('Feature extraction ... took %0.3f minutes\n',etime(clock,st)/60);
        fprintf('save features matfile ...');
        save('./tmp/mAbnormalTrackDetection/Feature.mat','TrackFeature','TrackLabel','TrackSpeed','TrackSpeedLabel','LowSpeed','HighSpeed');
        fprintf(' done\n');
    else
        fprintf('load features file ... ');
        load './tmp/mAbnormalTrackDetection/Feature.mat';
        fprintf(' done\n');
    end
    TrackResult.TrackFeature        = TrackFeature;
    TrackResult.TrackLabel          = TrackLabel;
    TrackResult.TrackSpeedFeature   = TrackSpeed;
    TrackResult.TrackSpeedLabel     = TrackSpeedLabel; 
    TrackResult.LowSpeed            = LowSpeed;
    TrackResult.HighSpeed           = HighSpeed;
end 
