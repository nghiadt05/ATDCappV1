function mBuildTheHumanMap
%{
    Using human detection results to build human-like and non-human-like
    areas. Based on that map, any tracks that lay in the non-human-like
    areas are treated as the abnormal trajectories.
%}
global opts;
global SP_OPT;

if strcmp(opts.Dataset,'demoDataset')
    fprintf('Load human-like and non-human-like map ... done\n');
else
    SPMapDir = dir([SP_OPT.SPTmpDir '/' opts.Dataset '_hmmap_*.jpg']); 
    if size(SPMapDir,1)==0
        fprintf('Building human-like and non-human-like area ...');
        DetectMatDir = dir([opts.DetFileTmpDir opts.Dataset '*.mat']);    
        if SP_OPT.IsUseBGSP
            load([SP_OPT.SPTmpDir '/' opts.Dataset '_SP.mat']);
            SP_OPT.MaxIdx = max(max(Sp2));
        end
        for DetFileIdx = 1:size(DetectMatDir,1)
            load([opts.DetFileTmpDir DetectMatDir(DetFileIdx).name]);
            for FrmIdx  = FrameIdx(1):FrameIdx(end)
                % get the human detection results
                bbIdx   = FrmIdx - FrameIdx(1) + 1;
                bbs     = detections(bbIdx);
                % if there exists a person in the scence, extract features of the
                % appropriate superpixels as the preparation for the online
                % training process
                DummyDet = [bbs.xp(1),bbs.yp(1),bbs.xi(1),bbs.yi(1),bbs.wd(1),bbs.ht(1)];
                if ~(sum(opts.DummyDet(1:end-1) == DummyDet) == 6) % human in the scence
                    % read the image
                    ImgName = [opts.ImagesDir '\' sprintf(opts.ImageForm,FrmIdx)];
                    I       = double(imread(ImgName))/255;           
                    % sample and extract the superpixel features
                    [SP_Human, ~, SP_FT_Human, SP_FT_nHuman, I_SP_Sample] = ...
                        mSP_FeatureExtraction(I,Sp2,SP_OPT,bbs);            
                    % form the learning data with respects to the most recent
                    % sampling features (only keep the most SampleLength recent
                    % sampling data)
                    SP_OPT.LearningData = [SP_OPT.LearningData;SP_FT_Human;SP_FT_nHuman];
                    if size(SP_OPT.LearningData,1) > SP_OPT.SampleLength
                        SP_OPT.LearningData = SP_OPT.LearningData( end - SP_OPT.SampleLength + 1: end,:);                        
        %                 disp(size(SP_OPT.LearningData,1));
                    end            
        %             close all;
        %             figure;imshow(I_SP_Sample);  
        %             I = I;
                end
                % online training      
                if ( (mod(FrmIdx,SP_OPT.TrInteral)==0)  && ...
                   (size(SP_OPT.LearningData,1) == SP_OPT.SampleLength))
                    SP_OPT.isClassifierAvailable = true;
                    st = clock;
                    fprintf('Online training at frame %d \n',FrmIdx);
                    % Create the neural net and start training                          
                    if SP_OPT.isUseNN
                        SPFeatureVectors = SP_OPT.LearningData(:,1:(end-1))';
                        SPFeatureLabels  = SP_OPT.LearningData(:,end)';  
                        SPFeatureLabels  = [SPFeatureLabels;~SPFeatureLabels];
                        [SP_OPT.net,SP_OPT.tr] = train(SP_OPT.net,SPFeatureVectors,SPFeatureLabels);
                    else
                        SP_OPT.SPClassifier = fitcecoc(SP_OPT.LearningData(:,1:(end-1)), SP_OPT.LearningData(:,end));
                    end
                    fprintf(' took %.2f minutes\n',etime(clock,st)/60);            
                end
                % classify the current image (resulting in a raw map)
                if SP_OPT.isClassifierAvailable
                    close all;
                    if SP_OPT.isUseNN
                        tmp_AllPIXLabels = mSP_Classification(I, Sp2, SP_OPT.net);
                    else
                        tmp_AllPIXLabels = mSP_Classification(I, Sp2, SP_OPT.SPClassifier);
                    end
                    if(mod(FrmIdx,5*SP_OPT.TrInteral)==0)
                        imwrite(tmp_AllPIXLabels,[SP_OPT.SPTmpDir '/' opts.Dataset '_hmmap_' num2str(FrmIdx) '.jpg']);
        %             figure;imshow(tmp_AllPIXLabels);
                    end
                end
            end
        end
        fprintf('\n');
    else
        fprintf('Load human-like and non-human-like map ... done\n');
    end
end
