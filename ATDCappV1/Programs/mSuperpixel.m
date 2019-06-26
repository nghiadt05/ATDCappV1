%{
    Segmenting the input frames using superpixel approach.
    Only extract superpixels for background scenes only. It is way
    more sufficient than extracting superpixels for each individual frame.
%}

%%
function mSuperpixel
% clc; close all; clear all;
global SP_OPT; 
global opts;
% Config;
% addpath(genpath('../ThirdParties/SuperpixelSegmentation/superpixels64/'));
% addpath(genpath('../ThirdParties/SuperpixelSegmentation/superpixels64/yu_imncut'));
% addpath(genpath('../ThirdParties/SuperpixelSegmentation/segbench/'));

%% Extract superpixels for all frames then store them in the tmp folder
if ~exist(SP_OPT.SPTmpDir,'dir')
    mkdir(SP_OPT.SPTmpDir);
end

if ~exist('cncut')
    addpath('yu_imncut');
end

if SP_OPT.IsUseBGSP
    % check the mat file before doing anything
    FrameIdx = opts.BGFrame;
    fileName = [opts.Dataset '_SP','.mat'];
    fullName = [SP_OPT.SPTmpDir '/' fileName];
    if(~exist(fullName,'file'))
        % read the image
        imgName = [opts.ImagesDir '\' sprintf(opts.ImageForm,FrameIdx)];
        I = im2double(imread(imgName));       

        % ncut parameters for superpixel computation
        diag_length = sqrt(SP_OPT.N*SP_OPT.N + SP_OPT.M*SP_OPT.M);
        par = imncut_sp;
        par.int=0;
        par.pb_ic=1;
        par.sig_pb_ic=0.05;
        par.sig_p=ceil(diag_length/50);
        par.verbose=0;
        par.nb_r=ceil(diag_length/60);
        par.rep = -0.005;  % stability?  or proximity?
        par.sample_rate=0.2;
        par.nv = SP_OPT.N_ev;
        par.sp = SP_OPT.N_sp;

        % Intervening contour using mfm-pb
        fprintf('running PB\n');
        [emag,ephase] = pbWrapper(I,par.pb_timing);
        emag = pbThicken(emag);
        par.pb_emag = emag;
        par.pb_ephase = ephase;
        clear emag ephase;

        st=clock;
        fprintf('Ncutting...');
        [Sp,Seg] = imncut_sp(I,par);
        fprintf(' took %.2f minutes\n',etime(clock,st)/60);

        st=clock;
        fprintf('Fine scale superpixel computation...');
        Sp2 = clusterLocations(Sp,ceil(SP_OPT.N*SP_OPT.M/SP_OPT.N_sp2));
        fprintf(' took %.2f minutes\n',etime(clock,st)/60);

        % save to file    
        save(fullName,'Sp2');

        I_sp2 = segImage(I,Sp2);
        figure();
        imshow(I_sp2);
    end
else
    for FrameIdx = SP_OPT.StartFrame:SP_OPT.SPSampleInterval:SP_OPT.EndFrame    
        % check the mat file before doing anything
        fileName = [SP_OPT.Dataset '_SP_',num2str(FrameIdx),'.mat'];
        fullName = [SP_OPT.SPTmpDir '/' fileName];
        if(~exist(fullName,'file'))
            % read the image
            imgName = [SP_OPT.ImagesDir '\' sprintf(SP_OPT.ImageForm,FrameIdx)];
            I = im2double(imread(imgName));       

            % ncut parameters for superpixel computation
            diag_length = sqrt(SP_OPT.N*SP_OPT.N + SP_OPT.M*SP_OPT.M);
            par = imncut_sp;
            par.int=0;
            par.pb_ic=1;
            par.sig_pb_ic=0.05;
            par.sig_p=ceil(diag_length/50);
            par.verbose=0;
            par.nb_r=ceil(diag_length/60);
            par.rep = -0.005;  % stability?  or proximity?
            par.sample_rate=0.2;
            par.nv = SP_OPT.N_ev;
            par.sp = SP_OPT.N_sp;

            % Intervening contour using mfm-pb
            fprintf('running PB\n');
            [emag,ephase] = pbWrapper(I,par.pb_timing);
            emag = pbThicken(emag);
            par.pb_emag = emag;
            par.pb_ephase = ephase;
            clear emag ephase;

            st=clock;
            fprintf('Ncutting...');
            [Sp,Seg] = imncut_sp(I,par);
            fprintf(' took %.2f minutes\n',etime(clock,st)/60);

            st=clock;
            fprintf('Fine scale superpixel computation...');
            Sp2 = clusterLocations(Sp,ceil(SP_OPT.N*SP_OPT.M/SP_OPT.N_sp2));
            fprintf(' took %.2f minutes\n',etime(clock,st)/60);

            % save to file    
            save(fullName,'Sp2');

%             I_sp2 = segImage(I,Sp2);
%             figure();
%             imshow(I_sp2);
        end
    end
end
fprintf('Superpixel segmentation for a background image is done. \n');