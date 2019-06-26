function mTrainRareTrackClassifier
%{
    Abnormal trajectory detection in term of direction and speed -
    classifier training phase. 
    Thre procedure for training such classifier are:
    1. Pre-process
    . Re-format tracking results from a human tracking algorithm
    . Calculate center position in world coordinate system for each
    person
    . Remove short trajectories
    . Interpolation for occlusion paths        .
    . Remove out of frame paths
    . Apply Gaussian filter for all paths
    2. Data preparation 
    . Automatically find dominant paths (explicit ways or unsupervised
    learning methods)
    . Increasing the amount of training data for normal and abnormal
    tracks
    . Rescaling and subsampling training data
    3. Feature extracton
    . Extract path features
    . Extract speed features
    4. Train classifier
    . Train classifier using NN
    . Verify classifier   
%}

global opts;
global SP_OPT;
global TrackResult;

if ~exist('./tmp/mAbnormalTrackDetection','dir')
    mkdir './tmp/mAbnormalTrackDetection';    
end
if exist('./tmp/mAbnormalTrackDetection/TrackResult.mat','file')
    load './tmp/mAbnormalTrackDetection/TrackResult.mat';
else
    % 1. Pre-process
    mTrackPreProcessing;
    % 2. Data preparation 
    mPathHandLabelling;     % hand labelling normal trajectories
    mCreateSampleTracks;    % surge the number of sample data 
    % 3. Feature extracton
    mAllFeatureExtractionV2;
    % 4. Train the classifier
    mTrainClassifierV2;
    mPathTestClassifierV2;
    % Save the refined TrackResult  
    save('./tmp/mAbnormalTrackDetection/TrackResult','TrackResult');
    fprintf('TrackResult is saved\n');    
end

% Visualization
% mShowTracks('Refined tracks in image plane',opts.SampImage,TrackResult.X,TrackResult.Y,1.5,false);
% mShowTracks('Refined tracks in ground plane',opts.SampImage,TrackResult.Xgp,TrackResult.Ygp,1.5,true);
% normalIdx = find(TrackResult.HandLabeledTracks == 1);    
% mShowTracks('Normal tracks',opts.SampImage,TrackResult.X(:,normalIdx),TrackResult.Y(:,normalIdx),1.5,false);
% abnormalIdx = find(TrackResult.HandLabeledTracks == 2);    
% mShowTracks('Abnormal tracks',opts.SampImage,TrackResult.X(:,abnormalIdx),TrackResult.Y(:,abnormalIdx),1.5,false);

% show all normal tracks
figure('name','Labelled normal tracks');
load([opts.AbnDetecDir '/' 'LabelledNormTrack.mat']);
imshow(opts.SampImage);
hold all;
for i=1:size(LabelledNormTrack,2)
    X = LabelledNormTrack{i}.Trace(:,1);    
    Y = LabelledNormTrack{i}.Trace(:,2);
    line(X,Y,'Color',[rand rand rand],'LineWidth',2);
end
hold off;

% show all abnormal track base lines
figure('name','Abnormal seed tracks');
load([opts.AbnDetecDir '/' 'SeedTrack.mat']);
imshow(opts.SampImage);
hold all;
for i=1:opts.NoOfSeedTracks
    line(SeedTrack{1,i}.X,SeedTrack{1,i}.Y,'Color','k','LineWidth',2);
end
hold off;
