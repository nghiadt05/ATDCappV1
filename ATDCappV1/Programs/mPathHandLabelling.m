function mPathHandLabelling()
    global TrackResult;
    global opts;    
    if ~exist('./tmp/mAbnormalTrackDetection/','dir')
        mkdir('./tmp/mAbnormalTrackDetection/');
    end
    if exist('./tmp/mAbnormalTrackDetection/HandLabeledTracks.mat','file')
        load './tmp/mAbnormalTrackDetection/HandLabeledTracks.mat';
        TrackResult.HandLabeledTracks = HandLabeledTracks;
        clear HandLabeledTracks;
    else   
        set(0, 'DefaultFigurePosition', [ 1300 50 560 420]);
        figure('name','Hand-classfy trajectories');hold on;

        fprintf('Collect training trajectories ... \n');       
        TrackResult.TrainingTrackID = [];
        curIndx = 1;
        isFinish = false;    
        while(~isFinish)                     
            clf; % clear the current display 
            imshow(opts.SampImage);
            hold on;
            fprintf('HumanID = %d/%d,press akey to continue\n',curIndx,TrackResult.AllIDs);
            pathIdx = find(TrackResult.X(:,curIndx));
            line(TrackResult.X(pathIdx,curIndx),TrackResult.Y(pathIdx,curIndx),'Color','r','LineWidth',3*opts.TraceLineWidth);
            prompt = 'Press:" Y: normal track/ T: abnormal track /B: redo /Q: to quit [Y]:" ';
            str = input(prompt,'s');
            disp(str);
            if isempty(str)
                str = 'Y';
            end
            if (strcmp(str,'Y')||strcmp(str,'y'))             
                TrackResult.HandLabeledTracks(curIndx) = 1;    
                curIndx = curIndx + 1;
                fprintf('Classified as a NORMAL path\n');
            elseif (strcmp(str,'T')||strcmp(str,'t'))            
                TrackResult.HandLabeledTracks(curIndx) = 2;
                curIndx = curIndx + 1;
                fprintf('Classified as an ABNORMAL path\n');
            elseif (strcmp(str,'E')||strcmp(str,'e'))            
                TrackResult.HandLabeledTracks(curIndx) = 3;
                curIndx = curIndx + 1;
                fprintf('Classified as ERROR path\n');
            elseif (strcmp(str,'B')||strcmp(str,'b'))                
                curIndx = curIndx-1;
                if(curIndx<1),curIndx=1;end;
                fprintf('Redo\n');
            elseif (strcmp(str,'Q')||strcmp(str,'q'))            
                isFinish = true;           
                fprintf('Quit hand classifying process\n');
            end     
            if(curIndx>TrackResult.AllIDs)
                isFinish = true;
            end
        end
        fprintf('Collect training trajectories ... done \n');                 
        HandLabeledTracks = TrackResult.HandLabeledTracks;
        save('./tmp/mAbnormalTrackDetection/HandLabeledTracks.mat','HandLabeledTracks');
    end 
end

