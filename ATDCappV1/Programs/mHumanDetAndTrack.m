function mHumanDetAndTrack
global opts;

%{
    Detect human in the video sequence then used that output as the input
    for human tracking algorithm. The results of human detection and human
    tracking programs are stored in the tmp/mHumanDetection and
    tnp/mHumantracking directories respectively.
%}
for FrameSeg = opts.FrameSeg
    close all;
    opts.StartFrame         = opts.BaseFrame + opts.FrameInterval * (FrameSeg-opts.FrameSeg(1));
    opts.EndFrame           = min(opts.MaxEndFrame,opts.BaseFrame + opts.FrameInterval * (FrameSeg-opts.FrameSeg(1)+1) - 1);
    opts.DetFileName        = [opts.Dataset sprintf('_HD_s%0.6d_e%0.6d.mat',opts.StartFrame,opts.EndFrame)];
    opts.DetFileVidName     = [opts.Dataset sprintf('_HD_s%0.6d_e%0.6d.avi',opts.StartFrame,opts.EndFrame)];
    opts.TrackFileName      = [opts.Dataset sprintf('_HT_s%0.6d_e%0.6d.mat',opts.StartFrame,opts.EndFrame)];
    opts.TrackVideoFileName = [opts.Dataset sprintf('_HT_s%0.6d_e%0.6d.avi',opts.StartFrame,opts.EndFrame)];
    assert(opts.StartFrame>=1);
    assert(opts.EndFrame<=opts.MaxEndFrame,'EndFrame exceeds the maximum frame number.');
%     fprintf('%d %d\n',opts.StartFrame,opts.EndFrame);   
    % detect human
    if ~exist([opts.DetFileTmpDir opts.DetFileName],'file')
        mHumanDetection();
    end
    % track human path
    if ~exist([opts.TrackFileTmpDir opts.TrackFileName],'file')
        mHumanTracking;
    end    
end
fprintf('Human detection and tracking processes are done.\n');