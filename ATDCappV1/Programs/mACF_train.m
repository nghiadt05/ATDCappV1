%{
 1. Using the ACF detector code to train new pedestrian detector
 2. Evaluating the newly trained detector
%}

%% 
function mACF_train

% clc; close all; clear all;
addpath(genpath('./'));
addpath(genpath('../ThirdParties/HumanDetection/code3.2.1/'));
addpath(genpath('../ThirdParties/HumanDetection/toolbox-master/'));
%% options
global opts;
if strcmp(opts.Dataset,'demoDataset')
    %{
        This toolbox also supplies the training images.
    %}
    isUseInriaDataset       = false;
    isUseCaltechDataset     = false;
    isUseTowCentreDataset   = false;
else
    %{
        Define the datasets that you want to use.
    %}
    isUseInriaDataset       = true;
    isUseCaltechDataset     = false;
    isUseTowCentreDataset   = true;
end

%% Extract training images (using several datasets)
% specify your local datasets here, note that the positive images should
% capture a person or a group of person only (a cropped image of the size 
% 128x64 is the best choice), whereas the negative images should contain 
% no person and there is no need to resize the negative images

% It is optional for the datasets that are involved in the training
% process. User can build their own training datasets for a better
% performance of the specific testing scence.

% Inria dataset: http://pascal.inrialpes.fr/data/human/
% One of the most popular datasets that are used in the literature of human
% detection.
if isUseInriaDataset
    posImgDir{1} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\INRIAPerson\train_64x128_H96\pos';
    negImgDir{1} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\INRIAPerson\train_64x128_H96\neg';
    posImgDir{2} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\INRIAPerson\70X134H96\Test\pos';
    negImgDir{2} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\INRIAPerson\test_64x128_H96\neg';
else
    posImgDir{1} = '';
    negImgDir{1} = '';
    posImgDir{2} = '';
    negImgDir{2} = '';
end

% Towncentre dataset: http://www.robots.ox.ac.uk/ActiveVision/Research/Projects/2009bbenfold_headpose/project.html#datasets
% This dataset captures a narrow scence of a Town Centre in the UK, this 
% data set is suitable for pedestrian tracking
if isUseTowCentreDataset
    posImgDir{3} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\TownCentre\TrainingImages\PosImages';
    negImgDir{3} = '';
else
    posImgDir{3} = '';
    negImgDir{3} = '';
end

% Caltech dataset: http://www.vision.caltech.edu/Image_Datasets/CaltechPedestrians/datasets/USA/
% This is a very extensive dataset in the sense of pedestrian detection
% applied for moving vehicles
global CalTechDataSetDir;
CalTechDataSetDir = 'D:\[2]DATA\[DATASET]\[1]VideoMining\CalTechPedestrian';
if isUseCaltechDataset
    mExtractCalTechData; % extract training images from the Caltech dataset
    posImgDir{4} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\CalTechPedestrian\train\pos';
    %negImgDir{4} = 'D:\[2]DATA\[DATASET]\[1]VideoMining\CalTechPedestrian\train\neg';
    negImgDir{4} = '';
else
    posImgDir{4} = '';
    negImgDir{4} = '';
end

% copy all training images into the temp folder then apply the 
% pre-processing data stp

% temporal directories
tPosImgDir = './tmp/mHumanDetection/trainImages/pos/';
tNegImgDir = './tmp/mHumanDetection/trainImages/neg/';

if ~exist('./tmp/mHumanDetection/','dir')        
    mkdir(tPosImgDir);
    mkdir(tNegImgDir);
    mkdir('./tmp/mHumanDetection/models/');
    fopen('./tmp/mHumanDetection/models/CAPPLog.txt','wt');
end

if ~strcmp(opts.Dataset,'demoDataset')
    % copy all training images of sub dataset to the temporal directory before
    % training the predestrian detector 
    fprintf('Copy training images to the ./tmp/ directory ...');
    for k=1:size(posImgDir,2)
        if ~strcmp(posImgDir{k},'')
            copyfile([posImgDir{k} '\*.png'],tPosImgDir);
        end
        if ~strcmp(negImgDir{k},'')
            copyfile([negImgDir{k} '\*.png'],tNegImgDir);
        end
    end
    fprintf(' done.\n'); 
    % rename positive images and save them with the normalized size 
    % [128,64], for all negative training images, only rename 
    fprintf('Pre-process the training images ... ');
    for j=1:2
        if j==1, tmpDir = dir(tPosImgDir);
        else tmpDir = dir(tNegImgDir); end
        for i = 3:size(tmpDir,1)
            curName = tmpDir(i).name;
            newName = [curName(1:end-3),'jpg'];            
            if ~strcmp(curName,newName)
                if j==1         
                    I = imread([tPosImgDir  curName]);
                    I = imresize(I,[128 64]);                
                    imwrite(I,[tPosImgDir newName]);
                else                
                    if strcmp(curName(end-2:end),'png')
                        I = imread([tNegImgDir  curName]);                
                        imwrite(I,[tNegImgDir newName]);      
                    end
                end
            end
        end
        if j==1, delete([tPosImgDir '*.png']);
        else delete([tNegImgDir '*.png']); end 
    end
    fprintf(' done.\n');
end


%% set up opts for training detector (see acfTrain)
% opts=acfTrain(); 
% opts.modelDs=[100 41]; 
% opts.modelDsPad=[128 64];
% opts.nWeak=[32 128 512 2048];
% opts.posWinDir = tPosImgDir;
% opts.negImgDir = tNegImgDir;
% opts.pJitter=struct('flip',1);
% opts.pBoost.pTree.fracFtrs=1/16;
% opts.pLoad={'squarify',{3,.41}}; 
% opts.name='/tmp/models/CAPP';

opts=acfTrain(); opts.modelDs=[100 41]; opts.modelDsPad=[128 64];
opts.pPyramid.pChns.pColor.smooth=0; opts.nWeak=[64 256 1024 4096];
opts.pBoost.pTree.maxDepth=5; opts.pBoost.discrete=0;
opts.pBoost.pTree.fracFtrs=1/16; opts.nNeg=25000; opts.nAccNeg=50000;
opts.pPyramid.pChns.pGradHist.softBin=1; opts.pJitter=struct('flip',1);
opts.posWinDir = tPosImgDir;
opts.negImgDir = tNegImgDir;
opts.pPyramid.pChns.shrink=2; opts.name='./tmp/mHumanDetection/models/CAPP+';
pLoad={'lbls',{'person'},'ilbls',{'people'},'squarify',{3,.41}};
opts.pLoad = [pLoad 'hRng',[50 inf], 'vRng',[1 1] ];

%% train detector (see acfTrain)
detector = acfTrain( opts );

%% modify detector (see acfModify)
pModify=struct('cascThr',-0.5,'cascCal',.025);
detector=acfModify(detector,pModify);

%% run detector on a sample image (see acfDetect)
imgNms=bbGt('getFiles',{[CalTechDataSetDir 'test/images']});
I=imread(imgNms{100}); tic, bbs=acfDetect(I,detector); toc
figure(1); im(I); bbApply('draw',bbs); pause(.1);

%% test detector and plot roc (see acfTest)
% [~,~,gt,dt]=acfTest('name',opts.name,'imgDir',[CalTechDataSetDir 'test/images'],...
%   'gtDir',[CalTechDataSetDir 'test/annotations'],'pLoad',[pLoad, 'hRng',[50 inf],...
%   'vRng',[.65 1],'xRng',[5 635],'yRng',[5 475]],...
%   'pModify',pModify,'reapply',0,'show',2);
