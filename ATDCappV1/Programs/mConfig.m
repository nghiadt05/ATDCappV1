%{
Specify all setting parameters used in the abnormal trajectory detection 
framework 
%}
function mConfig

addpath(genpath('./'));
addpath(genpath('../ThirdParties/HumanDetection/code3.2.1/'));
addpath(genpath('../ThirdParties/HumanDetection/toolbox-master/'));
addpath(genpath('../ThirdParties/HumanTracking/dctracking-v1.0'));
addpath(genpath('../ThirdParties/SuperpixelSegmentation/superpixels64/'));
addpath(genpath('../ThirdParties/SuperpixelSegmentation/superpixels64/yu_imncut'));
addpath(genpath('../ThirdParties/SuperpixelSegmentation/segbench/'));

global opts;
%% General dataset information
% opts.Dataset        = 'PETS09_S2_L1_V001';
% opts.Dataset        = 'SNUCafe1';
% opts.Dataset        = 'SNUCafe2';
opts.Dataset        = 'demoDataset'; % based on SNUCafe1 dataset

if strcmp(opts.Dataset, 'PETS09_S2_L1_V001')
    opts.ImageForm      = 'frame_%0.4d.jpg';
    opts.ImagesDir      = 'D:\[2]DATA\[DATASET]\[1]VideoMining\Crowd_PETS09\S2\L1\Time_12-34\View_001';
    opts.ImgDirInfo     = dir([opts.ImagesDir '\*.' opts.ImageForm(end-2:end)]);
    opts.BGFrame        = 1;
    opts.BaseFrame      = 1;
    opts.MaxEndFrame    = size(opts.ImgDirInfo,1);
    opts.FrameInterval  = 1000; 
elseif strcmp(opts.Dataset, 'SNUCafe1')
    opts.ImageForm      = '%0.6d.jpg';
    opts.ImagesDir      = 'D:\[2]DATA\[DATASET]\[1]VideoMining\SNUCafeterial\SNUCafe1';    
    opts.ImgDirInfo     = dir([opts.ImagesDir '\*.' opts.ImageForm(end-2:end)]);
    opts.BGFrame        = 1;
    opts.BaseFrame      = 1;
    opts.MaxEndFrame    = 15000;%size(opts.ImgDirInfo,1);
    opts.FrameInterval  = 1000; 
elseif strcmp(opts.Dataset, 'SNUCafe2')
    opts.ImageForm      = '%0.6d.jpg';
    opts.ImagesDir      = 'D:\[2]DATA\[DATASET]\[1]VideoMining\SNUCafeterial\SNUCafe2';
    opts.ImgDirInfo     = dir([opts.ImagesDir '\*.' opts.ImageForm(end-2:end)]);
    opts.BGFrame        = 30;
    opts.BaseFrame      = 3000;
    opts.MaxEndFrame    = 6000;
    opts.FrameInterval  = 1000; 
elseif strcmp(opts.Dataset, 'demoDataset')
    opts.ImageForm      = '%0.6d.jpg';
    opts.ImagesDir      = './demoDataset';    
    opts.ImgDirInfo     = dir([opts.ImagesDir '\*.' opts.ImageForm(end-2:end)]);
    opts.BGFrame        = 0; 
    opts.BaseFrame      = 1;
    opts.MaxEndFrame    = 899;
    opts.FrameInterval  = 899;
end

opts.SampImage      = imread([opts.ImagesDir '\' sprintf(opts.ImageForm,opts.BGFrame)]);
opts.MaxHor         = size(opts.SampImage,2);
opts.MaxVer         = size(opts.SampImage,1);

if mod(opts.MaxEndFrame ,opts.FrameInterval)
    opts.FrameSeg   = floor(opts.BaseFrame/opts.FrameInterval) : ceil(opts.MaxEndFrame/opts.FrameInterval);
else
    opts.FrameSeg   = floor(opts.BaseFrame/opts.FrameInterval) : (ceil(opts.MaxEndFrame/opts.FrameInterval)-1);
end

if strcmp(opts.Dataset, 'PETS09_S2_L1_V001')
    opts.ROI_minHor = 10;
    opts.ROI_maxHor = opts.MaxHor - 10;
    opts.ROI_minVer = 120;
    opts.ROI_maxVer = opts.MaxVer - 10;
    opts.ROI_Region = [ opts.ROI_minHor,...
                        opts.ROI_minVer,...
                        opts.ROI_maxHor - opts.ROI_minHor,...
                        opts.ROI_maxVer - opts.ROI_minVer];    
elseif strcmp(opts.Dataset, 'SNUCafe1')
    opts.ROI_minHor = 10;
    opts.ROI_maxHor = opts.MaxHor - 10;
    opts.ROI_minVer = 10;
    opts.ROI_maxVer = opts.MaxVer - 10;
    opts.ROI_Region = [ opts.ROI_minHor,...
                        opts.ROI_minVer,...
                        opts.ROI_maxHor - opts.ROI_minHor,...
                        opts.ROI_maxVer - opts.ROI_minVer];    
elseif strcmp(opts.Dataset, 'SNUCafe2')
    opts.ROI_minHor = 10;
    opts.ROI_maxHor = opts.MaxHor - 10;
    opts.ROI_minVer = 120;
    opts.ROI_maxVer = opts.MaxVer - 10;
    opts.ROI_Region = [ opts.ROI_minHor,...
                        opts.ROI_minVer,...
                        opts.ROI_maxHor - opts.ROI_minHor,...
                        opts.ROI_maxVer - opts.ROI_minVer];    
elseif strcmp(opts.Dataset, 'demoDataset')
    opts.ROI_minHor = 10;
    opts.ROI_maxHor = opts.MaxHor - 10;
    opts.ROI_minVer = 10;
    opts.ROI_maxVer = opts.MaxVer - 10;
    opts.ROI_Region = [ opts.ROI_minHor,...
                        opts.ROI_minVer,...
                        opts.ROI_maxHor - opts.ROI_minHor,...
                        opts.ROI_maxVer - opts.ROI_minVer];        
end
% Visualize the region of interest
%     close all;
%     figure();
%     imshow(opts.SampImage);
%     rectangle('Position',opts.ROI_Region,'EdgeColor','r','LineWidth',3);
%     pause();

%% Human detection
opts.isSave2Video = true;
opts.DetFileTmpDir  = './tmp/mHumanDetection/';  
if strcmp(opts.Dataset, 'PETS09_S2_L1_V001')  
    opts.ScoreThres     = 70;
    opts.ScoreScale     = 200; % this can effect the accuracy of the tracking algorithm
    opts.BaseScore      = 0.8;
    opts.DummyDet       = [10,10,10,10,10,10,0.958];
elseif strcmp(opts.Dataset, 'SNUCafe1')
    opts.ScoreThres     = 30;
    opts.ScoreScale     = 200; % this can effect the accuracy of the tracking algorithm
    opts.BaseScore      = 0.8;
    opts.DummyDet       = [1,470,1,470,10,10,0.9];
elseif strcmp(opts.Dataset, 'SNUCafe2')
    opts.ScoreThres     = 0;
    opts.ScoreScale     = 200; % this can effect the accuracy of the tracking algorithm
    opts.BaseScore      = 0.8;
    opts.DummyDet       = [10,10,10,10,10,10,0.9];
elseif strcmp(opts.Dataset, 'demoDataset')
    opts.ScoreThres     = 50;
    opts.ScoreScale     = 200; % this can effect the accuracy of the tracking algorithm
    opts.BaseScore      = 0.8;
    opts.DummyDet       = [1,470,1,470,10,10,0.9];
end

%% Human tracking  
opts.TrackFileTmpDir    = './tmp/mHumanTracking/'; 

%% Abnormal trajectory detection
opts.AbnDetecDir = './tmp/mAbnormalTrackDetection'; 

% Display options
opts.isVisual                = true;
opts.isSave2Vid              = true & opts.isVisual;
opts.isDispTracksOnly        = true;
opts.isDispBB                = true;
opts.isDispFootage           = false;
opts.isDispTrace             = true;
opts.isDispID                = false;
opts.pauseLength             = 0.01;
opts.BBLineWidth             = 2;
opts.FootageWidth            = 30;
opts.TraceLineWidth          = 2;
opts.TraceLength             = 50;
opts.TraceDisappear          = 20;
opts.WarningColor            = [1.0 0 0];
opts.WarningTraceLineWidth   = 3.5*opts.TraceLineWidth;
opts.WarningBBLineWidth      = 3.5*opts.BBLineWidth;

% options for the pre-processing step
% refining the training data
opts.isCameraModel = false;
opts.MinLength = 30; % minimum number of continuous frames that a person is tracked 
opts.FilterSize = 4; % define the size of the filter (n*2)-tap filter    
opts.GaussWin   = gausswin(opts.FilterSize*2); opts.GaussWin = opts.GaussWin/sum(opts.GaussWin); % gaussian filter parameters 
opts.NormalizeLength = 1000;
opts.NoOfMaximumSample = 50000;

% feature extraction configuration
opts.CurveDet.NoOfSubPart = 20;
opts.CurveDet.CurveThresh = pi/4;
opts.MaxDer = 20;
opts.MaxSpeed = 100;
opts.LowSpeedGain = 0.7;
opts.HighSpeedGain = 4;

% options for generate more samples
opts.NoOfSeedTracks = 45;
opts.MaxRotateAngle = 0.25;
opts.RotateSampe = 10;
opts.Rescale = [0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8];
opts.SampleFrameDist = 5;

% options for testing
opts.WindowSize = 100;
opts.StartFrame = 100; 
opts.StopFrame  = 4500;

% option for training method
opts.isUseSVM = false;
opts.isUseNeuralNet = true;
opts.NoOfNeural = 10;
assert((opts.isUseSVM || opts.isUseNeuralNet)==1,'Atleast one of the training method should be used');
assert((opts.isUseSVM && opts.isUseNeuralNet)==0,'Atmost one of the trainning method should be used');

%% Superpixel
global SP_OPT;
SP_OPT.IsUseBGSP            = true;
SP_OPT.SPTmpDir             = './tmp/mSuperpixel';
SP_OPT.SPSampleInterval     = 10;
SP_OPT.N_sp                 = 200;  % Number of superpixels coarse/fine.
SP_OPT.N_sp2                = 1000; 
SP_OPT.N_ev                 = 40;   % Number of eigenvectors.
SP_OPT.N                    = opts.MaxVer;
SP_OPT.M                    = opts.MaxHor;

SP_OPT.SampleLength         = 20000;                % the maximum length of training samples
SP_OPT.TrInteral            = 5;                    % the frame intervals between two consequent online learning
SP_OPT.HumanScore           = 0.7;                  % the score that indicating a superpixel (SP) is a human SP
SP_OPT.HistoricalMapNum     = 5;                    % the number of history area map used for refinment step
SP_OPT.Historymap{SP_OPT.HistoricalMapNum} = [];    % historical human-like area map 
SP_OPT.isLabelHumanSP       = false;                % using human-pixel or not
SP_OPT.RefinedCnt           = 2;                    % the number of refinement applied for area map
SP_OPT.StartWeightedPar     = 1;                    % start value for the weighted filter
SP_OPT.EndtWeightedPar      = 100;                  % end value for the weighted filter
SP_OPT.HardNonHumanThres    = 0.25;                 % threshold which determines the non-human-like area and human-like area
SP_OPT.isCheckBB = false;                           % when enable, only sample the confident superpixels, which are in human-like area
SP_OPT.WeightedParam =  SP_OPT.StartWeightedPar:...
                        ((SP_OPT.EndtWeightedPar-SP_OPT.StartWeightedPar)/(SP_OPT.HistoricalMapNum-1)):...
                        SP_OPT.EndtWeightedPar;
SP_OPT.WeightedParam        = SP_OPT.WeightedParam./sum(SP_OPT.WeightedParam); % parameters for the weighted filter
SP_OPT.IsUseGT              = false;
SP_OPT.LearningData         = [];
SP_OPT.isClassifierAvailable = false;
SP_OPT.isUseNN              = true;
SP_OPT.NoOfNeural           = 10;
SP_OPT.net                  = fitnet(SP_OPT.NoOfNeural);
SP_OPT.AbnormalThres        = round(0.5*opts.MinLength);

       