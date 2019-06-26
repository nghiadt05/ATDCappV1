%{
    Main program for detecting anomalous pedestrian's trajectories
%}

%%
clc; close all; clear all;
global opts;            % Global configurations 
global SP_OPT;          % Configurations for superpixel segmentation and forming human-like maps
global TrackResult;     % Configurations for rare trajectory detection frameworks

%% Configurations
mConfig;

%% Perform human detection and tracking
mHumanDetAndTrack;

%% Perform superpixel segmentation only for the background scence
mSuperpixel;

%% Anomalous trajectory detection in prohibited areas 
% Build the human-like map
mBuildTheHumanMap;

%% Anomalous trajectory detection in non-prohibitted areas  
% Train the classifier to deal with abnormal tracks in terms of direction and speed
mTrainRareTrackClassifier;

%% Using both detectors to detect anomalous trajectories
% Hierarchical abnormal pedestrian's trajectory detector 
mHierarchicalAbnormalTrackDetectors;

%% Display the detection results
mVisualization;


