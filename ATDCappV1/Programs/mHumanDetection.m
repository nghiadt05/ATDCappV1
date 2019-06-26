%{
    Perform the human detection algorithm in the designated dataset
    described in the Config.m
%}
function mHumanDetection()
%%
% clc; close all; clear all;
% addpath(genpath('./'));
% addpath(genpath('../ThirdParties/HumanDetection/code3.2.1/'));
% addpath(genpath('../ThirdParties/HumanDetection/toolbox-master/'));
% Config;
global opts;
%%  Get the configurations 
if opts.isSave2Video
    if ~exist('./tmp/mHumanDetection/','dir')
        mkdir('./tmp/mHumanDetection/');
    end
    v = VideoWriter(['./tmp/mHumanDetection/' opts.DetFileVidName]);
    v.FrameRate = 25;
    open(v);
end

%% Load the detector
if exist('./tmp/mHumanDetection/models/CAPP+Detector.mat','file')
    load './tmp/mHumanDetection/models/CAPP+Detector.mat';
else
    fprintf('Train the pedestrian detector !\n');
    mACF_train;
    return;
end

%% modify detector (see acfModify)
pModify=struct('cascThr',-0.5,'cascCal',.025);
detector=acfModify(detector,pModify);

%% Run the detector in the setup frames
if opts.isSave2Video
    fig1 = figure('name','Test');
    hold on;
end
for FrameIdx = opts.StartFrame:opts.EndFrame
    imgName = [opts.ImagesDir '\' sprintf(opts.ImageForm,FrameIdx)];
    I=imread(imgName); tic, bbs=acfDetect(I,detector); toc 
        
    % remove the detection results with low score
    if ~isempty(bbs)
        lowScoreBB = find(bbs(:,5)<=opts.ScoreThres);
        if ~isempty(lowScoreBB)
            bbs(lowScoreBB,:) = [];
        end
    end  
        
    % remove the out of ROI bounding boxes    
    if ~isempty(bbs)   
        outROI = [];
        for i=1:size(bbs,1)
            curHor = bbs(i,1);
            curVer = bbs(i,2);
            if(     (curHor<opts.ROI_minHor)... 
                ||  (curHor>opts.ROI_maxHor)...
                ||  (curVer<opts.ROI_minVer)...
                ||  (curVer>opts.ROI_maxVer)...
                )
                outROI = [outROI,i];
            end
        end
        if ~isempty(outROI)
            bbs(outROI,:) = [];
        end
    end
    
    % In the case the bounding box is empty, which is caused by either there
    % is no detected person in the sence or after the human detection
    % refinement step all existing bouding boxes are removed. To tackle
    % this problem (result an error in the tracking program)insert a dummy 
    % person then remove it later when proceed in the tracking part
    if isempty(bbs)
        bbs = opts.DummyDet; 
    end
          
    % save the detection information in an eligible format that can be used 
    % in the DCT tracking program   
    relFrmIdx = FrameIdx - opts.StartFrame + 1;
    dtInfo(relFrmIdx).xp = bbs(:,1)';
    dtInfo(relFrmIdx).yp = bbs(:,2)';
    dtInfo(relFrmIdx).xi = dtInfo(relFrmIdx).xp;
    dtInfo(relFrmIdx).yi = dtInfo(relFrmIdx).yp;
    dtInfo(relFrmIdx).wd = bbs(:,3)';
    dtInfo(relFrmIdx).ht = bbs(:,4)';
    tmpsc = bbs(:,5)';
%     dtInfo(FrameIdx).sc = tmpsc./opts.ScoreScale;
    dtInfo(relFrmIdx).sc =  opts.BaseScore.*ones(size(tmpsc))+ ...
                            rand(size(tmpsc)).*((1-opts.BaseScore).*ones(size(tmpsc)));

    
    if opts.isSave2Video
%         fig1 = figure(1); im(I); bbApply('draw',bbs); 
        clf;
        imshow(I);
        if ~isempty(bbs)            
            for i=1:size(bbs,1)                
                win = bbs(i,1:4);
                rectangle('Position',win,'EdgeColor','r','LineWidth',3);
            end
        end
        j = getframe(fig1);
        writeVideo(v,j.cdata);
    end
end

detections = dtInfo;
FrameIdx = opts.StartFrame:opts.EndFrame;
save([opts.DetFileTmpDir opts.DetFileName],'detections','FrameIdx');

if opts.isSave2Video
    pause(1);
    close(v);
end
