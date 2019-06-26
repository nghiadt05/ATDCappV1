%{
    Download and setup the third party programs
%}

%% 
clc; close all; clear all;

%% Create folders for the third party programs
if ~exist('../ThirdParties','dir')
    mkdir('../ThirdParties');
end
curDir = pwd;
% options
opt.is64bitSystem = true;

%% Dowload and setup the ACF Pedestrian Detector

% Using the ACF pedestrian detector, for more information please visit the
% website: http://vision.ucsd.edu/~pdollar/toolbox/doc/index.html

if ~exist('../ThirdParties/HumanDetection','dir')
    mkdir('../ThirdParties/HumanDetection');  
    cd('../ThirdParties/HumanDetection');      
    fprintf('Download Piotr`s Matlab Tool Box ...');
    urlwrite('https://github.com/pdollar/toolbox/archive/master.zip','master.zip');
    fprintf('done.\n');
    fprintf('Download Matlab evaluation/labeling code (3.2.1) ...');
    urlwrite('http://www.vision.caltech.edu/Image_Datasets/CaltechPedestrians/code/code3.2.1.zip','code3.2.1.zip');
    fprintf('done.\n');
    fprintf('Unziping files ...');
    unzip('master.zip','./');
    unzip('code3.2.1.zip','./code3.2.1');
    fprintf('done.\n');
    addpath(genpath(pwd));
    fprintf('Compile the Piotr`s Tool Box\n');
    toolboxCompile;     % compile the tool box   
end
cd(curDir);

%% Download and setup the Discrete Continuous Tracking (DCT) program
if ~exist('../ThirdParties/HumanTracking/','dir')
    mkdir('../ThirdParties/HumanTracking/');
    cd('../ThirdParties/HumanTracking/');
    
    fprintf('Download DCT tracking V1.0 ...');
    urlwrite('http://www.milanton.de/files/software/dctracking-v1.0.zip','dctracking-v1.0.zip');
    unzip('dctracking-v1.0.zip');
    fprintf(' done\n');
    
    cd('./dctracking-v1.0');
    rmdir('./gco-v3.0','s');   
    mkdir('./gco-v3.0');
    cd('./gco-v3.0');
    fprintf('Download gc0-v3.0 ...');
    urlwrite('http://vision.csd.uwo.ca/code/gco-v3.0.zip','gco-v3.0.zip');    
    fprintf(' done\n');
    unzip('gco-v3.0.zip');
    
    cd ..;
    addpath(genpath('./'));
    fprintf('Compile the DCTracking');
    compileMex;
    fprintf('Demo of the DCT tracker V1.0\n');
end
cd(curDir);

%% Download and setup the Superpixel segmentation
if ~exist('../ThirdParties/SuperpixelSegmentation/','dir')
    mkdir('../ThirdParties/SuperpixelSegmentation/');
    cd('../ThirdParties/SuperpixelSegmentation/');
    
    fprintf('Dowload segbench program ... ');
    urlwrite('http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/segbench/code/segbench.tar.gz','segbench.tar.gz');
    untar('segbench.tar.gz');
    fprintf('done. \n');
    
    if opt.is64bitSystem
        fprintf('Dowload Superpixel Program for 64-bit systesm ... ');
        urlwrite('http://www.cs.sfu.ca/~mori/research/superpixels/superpixels64.tar.gz','superpixels64.tar.gz');
        fprintf('done.\n');
        fprintf('Unziping files ... ');
        untar('superpixels64.tar.gz','./');        
        cd './superpixels64/yu_imncut/';
        mex -largeArrayDims csparse.c;
        mex -largeArrayDims ic.c;
        mex -largeArrayDims imnb.c;
        mex -largeArrayDims parmatV.c;
        mex -largeArrayDims spmd1.c;
        cd ../;        
        addpath(genpath('./'));
        addpath(genpath('../'));
    else
        fprintf('Dowload Superpixel Program for 32-bit systesm ... ');
        urlwrite('http://www.cs.sfu.ca/~mori/research/superpixels/superpixels.tar.gz','superpixels.tar.gz');
        fprintf('done.');
        fprintf('Unziping files ... ');
        untar('superpixels.tar.gz','./');          
        cd ('./superpixels/yu_imncut/');
        mex  csparse.c;
        mex  ic.c;
        mex  imnb.c;
        mex  parmatV.c;
        mex  spmd1.c;
        cd ../../;
        fprintf('done.\n');
    end        
end
cd(curDir);


