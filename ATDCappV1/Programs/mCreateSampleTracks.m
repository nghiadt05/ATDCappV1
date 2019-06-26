function mCreateSampleTracks()
    % The output results of this function are the normal and rare tracks.
    % Normal tracks are derived directly from the labeled tracks from human
    % tracking outputs. Owing to the fact that the number of rare tracks
    % are small and they are often 'rare' in a part of the whole track;
    % therefore, we need to create the rare tracks manually. All of those
    % sample tracks have the same length which is defined by opts.MinLength.
    % Furthermore, the speed variant problems are also addressed by
    % sampling the tracks with various number of samples.
    
    global opts;
    global TrackResult;
    % Generate the sub-samples of the normal trajectories from the labelled
    % ones
    TrackResult.AllSamplePaths = [];
    
    % Take all positive samples from the pre-refined tracks and create a
    % little more :D
    fprintf('Load the normal tracks from file ...'); 
    if ~exist('.\tmp\mAbnormalTrackDetection\LabelledNormTrack.mat','file')
        NormalID = find(TrackResult.HandLabeledTracks==1);
        X = TrackResult.X(:,NormalID);
        Y = TrackResult.Y(:,NormalID);
        NormTrackCnt = 1;    
%         debug
        close all;
        figure();
        for i = 1:size(X,2)
            pathIdx = find(X(:,i));
            normalX = X(pathIdx,i);
            normalY = Y(pathIdx,i);
            meanX = mean(normalX);
            meanY = mean(normalY);       
            %debug
            clf
            imshow(opts.SampImage); hold all;
            line(normalX,normalY,'LineWidth',2,'color','r');
            for j = 1:ceil(opts.RotateSampe/2)
                alpha = (opts.MaxRotateAngle/5)*(2*rand-1);    
                tmp_normalX = normalX - meanX;
                tmp_normalY = normalY - meanY;
                rotMat = [cos(alpha),sin(alpha);-sin(alpha),cos(alpha)];
                rotateTrace =  [tmp_normalX,tmp_normalY]*rotMat;
                rotateX = rotateTrace(:,1) + meanX;
                rotateY = rotateTrace(:,2) + meanY;                    
                TrackResult.LabelledNormTrack{NormTrackCnt}.Trace = [rotateX,rotateY];
                TrackResult.LabelledNormTrack{NormTrackCnt}.Label = 1;
                NormTrackCnt = NormTrackCnt + 1;            
                %debug
                line(rotateX,rotateY,'LineWidth',2,'color',[rand rand rand]); hold all;
            end
            TrackResult.LabelledNormTrack{NormTrackCnt}.Trace = [normalX,normalY];
            TrackResult.LabelledNormTrack{NormTrackCnt}.Label = 1;
            NormTrackCnt = NormTrackCnt + 1;
        end    
        LabelledNormTrack = TrackResult.LabelledNormTrack;
        save('.\tmp\mAbnormalTrackDetection\LabelledNormTrack.mat','LabelledNormTrack');
        fprintf(' done\n');
    else
        load '.\tmp\mAbnormalTrackDetection\LabelledNormTrack.mat';
        TrackResult.LabelledNormTrack = LabelledNormTrack;
        fprintf(' done\n');
    end 
    
    % Create samples for rare tracks
    if ~exist('.\tmp\mAbnormalTrackDetection\CreatedRareTrack.mat','file')
        fprintf('Create the rare paths from the normal ones ... \n');
        CreatedRareTrack = mRareTrackCreate();
        TrackResult.CreatedRareTrack = CreatedRareTrack;
        save('.\tmp\mAbnormalTrackDetection\CreatedRareTrack','CreatedRareTrack');
        fprintf('Create the rare paths from the normal ones ... done \n');        
    else
        load('.\tmp\mAbnormalTrackDetection\CreatedRareTrack.mat');
        fprintf('Load the created rare tracks from file ...');
        TrackResult.CreatedRareTrack = CreatedRareTrack;
        fprintf(' done\n');
    end
               
    % Split normal/abnormal tracks to smaller tracks with different scale lengths      
    if ~exist('.\tmp\mAbnormalTrackDetection\AllSamplePaths.mat','file')
        % Split normal tracks to smaller tracks with different scale lengths
        fprintf('Sampling multiple scales of the labelled normal tracks ... ');
        st=clock;
        for i = 1:size(TrackResult.LabelledNormTrack,2)
            X = TrackResult.LabelledNormTrack{i}.Trace(:,1);
            Y = TrackResult.LabelledNormTrack{i}.Trace(:,2);
            CurrentLength = length(X);
            for j=1:length(opts.Rescale)
                NewLength = floor(opts.Rescale(j)*CurrentLength);
                if(NewLength>=opts.MinLength)
                    [Xnew, Ynew] = mPathResizeLength(X,Y,NewLength);
                    [invXnew, invYnew] = mInverseTrack(Xnew,Ynew);
                    [ SampleTrack, ~ ] = mTrackSplit([Xnew,invXnew],[Ynew,invYnew],1);                
                    TrackResult.AllSamplePaths = [TrackResult.AllSamplePaths,SampleTrack];
                end
            end
        end
        fprintf(' took %.2f minutes\n',etime(clock,st)/60);    

        % Split anomalous tracks to smaller tracks with different scale lengths
        st=clock;
        fprintf('Sampling multiple scales of the created rare tracks ... ');
        for i = 1:size(TrackResult.CreatedRareTrack,2)
            X = TrackResult.CreatedRareTrack{i}.Trace(:,1);
            Y = TrackResult.CreatedRareTrack{i}.Trace(:,2);
            CurrentLength = length(X);
            for j=1:length(opts.Rescale)
                NewLength = floor(opts.Rescale(j)*CurrentLength);
                if(NewLength>=opts.MinLength)
                    [Xnew, Ynew] = mPathResizeLength(X,Y,NewLength);
                    [invXnew, invYnew] = mInverseTrack(Xnew,Ynew);
                    [ SampleTrack, ~ ] = mTrackSplit([Xnew,invXnew],[Ynew,invYnew],2);
                    TrackResult.AllSamplePaths = [TrackResult.AllSamplePaths,SampleTrack];
                end
            end
        end
        AllSamplePaths = TrackResult.AllSamplePaths;
        save('.\tmp\mAbnormalTrackDetection\AllSamplePaths.mat','AllSamplePaths');
        fprintf(' took %.2f minutes\n',etime(clock,st)/60);
    else
        load '.\tmp\mAbnormalTrackDetection\AllSamplePaths.mat';
        fprintf('Load all sample paths ... ');
        TrackResult.AllSamplePaths = AllSamplePaths;
        fprintf(' done. \n');
    end
end

