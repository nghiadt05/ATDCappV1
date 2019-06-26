% Discrete-Continuous Optimization for Multi-Target Tracking
%
% This code contains minor modifications compared
% to the one that was used
% to produce results for our CVPR 2012 paper


% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

function mHumanTracking()
%%
% clear all; close all; clc;
% Config;
% addpath(genpath('../ThirdParties/HumanTracking/dctracking-v1.0'));

global opts; 
global dcStartTime
dcStartTime=tic;
%% seed random for deterministic results
if verLessThan('matlab','7.11'),    rand('seed',1);    randn('seed',1);
else    rng('default'); 
end
%% declare global variables
global detections nPoints sceneInfo opt globiter gtInfo;
globiter=0;

global LOG_allens LOG_allmets2d LOG_allmets3d %for debug output

% fill options struct
opt= mDCOptions;

% Display options
opt.isVisual        = true;
opt.isSave2Video      = true & opt.isVisual;
opt.isDispBB        = true;
opt.isDispFootage   = true;
opt.isDispTrace     = true;
opt.isDispID        = true;

opt.pauseLength     = 0.01;
opt.BBLineWidth     = 2;
opt.FootageWidth    = 30;
opt.TraceLineWidth  = 2;
opt.TraceLength     = 50;

% fill scene info
sceneInfo= mSceneInfoDC;

% frames=1:length(sceneInfo.frameNums);
% frames=1:1000; % do a part of the whole sequence
% sceneInfo.frameNums=sceneInfo.frameNums(frames);
frames = sceneInfo.frameNums;
frames = sceneInfo.frameNums - (opts.StartFrame - 1);

%% cut GT to tracking area
if  sceneInfo.gtAvailable && opt.track3d && opt.cutToTA
    gtInfo=cutGTToTrackingArea(gtInfo);
end

%% remove unnecessary frames from GT
if sceneInfo.gtAvailable
    gtInfo.frameNums=gtInfo.frameNums(frames);
    gtInfo.X=gtInfo.X(frames,:);gtInfo.Y=gtInfo.Y(frames,:);
    gtInfo.W=gtInfo.W(frames,:);gtInfo.H=gtInfo.H(frames,:);
    if opt.track3d
        gtInfo.Xgp=gtInfo.Xgp(frames,:);gtInfo.Ygp=gtInfo.Ygp(frames,:);
    end
    gtInfo=cleanGT(gtInfo);
end

%
if opt.visOptim,  reopenFig('optimization'); end
%% load detections
[detections, nPoints]=parseDetections(sceneInfo,frames); 
[detections, nPoints]=cutDetections(detections,nPoints);
detMatrices=getDetectionMatrices(detections);

%% top image limit
sceneInfo.imTopLimit=min([detections(:).yi]);
computeImBordersOnGroundPlane;

% evaluateDetections(detMatrices,gtInfo);

T=size(detections,2);                   % length of sequence
stateInfo.F=T; stateInfo.frameNums=sceneInfo.frameNums;

%% put all detections into a single vector
alldpoints=createAllDetPoints(detections);

%% create spatio-temporal neighborhood graph
TNeighbors=getTemporalNeighbors(alldpoints);

%% init solution
% generate initial spline trajectories
mhs=getSplineProposals(alldpoints,opt.nInitModels,T);

%
%% get splines from EKF
for ekfexp=1:5
    mhsekf=getSplinesFromEKF(fullfile('demo','ekf',sprintf('e%04d.mat',ekfexp)),frames,alldpoints,T);
    mhs=[mhs mhsekf];
end
nCurModels=length(mhs);
nInitModels=nCurModels;


%% set initial labeling to all outliers
nCurModels=length(mhs);
nLabels=nCurModels+1; outlierLabel=nLabels;
labeling=nLabels*ones(1,nPoints); % all labeled as outliers


%% initialize labelcost
[splineGoodness, goodnessComp]=getSplineGoodness(mhs,1:opt.nInitModels,alldpoints,T);
% [prox proxt proxcost]=getSplineProximity(mhs,1:nInitModels,alldpoints,labeling,T,proxcostFactor,splineGoodness);

% unary is constant to outlierCost
Dcost = opt.outlierCost * ones(nLabels,nPoints);
Scost=opt.pairwiseFactor-opt.pairwiseFactor*eye(nLabels);
Lcost=getLabelCost(mhs);

[inE, inD, inS, inL] = getGCO_Energy(Dcost, Scost, Lcost, TNeighbors, labeling);
bestE=inE; E=inE; D=inD; S=inS; L=inL;

%%
printDCUpdate(stateInfo,mhs,[],0,0,0,D,S,L);

%% first plot
drawDCUpdate(mhs,1:length(mhs),alldpoints,0,outlierLabel,TNeighbors,frames);


nAddRandomModels=10; % random models
nAddModelsOutliers=10;

nAdded=0; nRemoved=0;

%% start energy minimization loop
itcnt=0; % only count one discrete-continuous cycle as one iteration
iteachcnt=0; % count each discrete and each continuous optimization step
used=[];
mhsafterrefit=[];
lcorig=opt.labelCost;
while 1
%     opt.labelCost=itcnt*lcorig;
    oldN=length(mhs);
    for m=1:length(mhs)
        if ~isempty(intersect(m,used))
            mhs(m).lastused=0; 
        else
            mhs(m).lastused=mhs(m).lastused+1;
        end
    end
    
    mhs_=mhs;
    tokeep=find([mhs.lastused]<3);
    mhs=mhs(tokeep);   
    
    nRemoved=oldN-length(tokeep);
    nCurModels=length(mhs); nLabels=nCurModels+1; outlierLabel=nLabels;
    
    % old labeling
    l_ = labeling;
    E_=E; D_=D; S_=S; L_=L;
    
    %% relabel
    % minimize discrete Energy E(f), (Eq. 4)
    Dcost=getUnarySpline(nLabels,nPoints,mhs,alldpoints,opt.outlierCost,opt.unaryFactor,T);
    Lcost=getLabelCost(mhs);
    Scost=opt.pairwiseFactor-opt.pairwiseFactor*eye(nLabels);
    [E, D, S, L, labeling]=doAlphaExpansion(Dcost, Scost, Lcost, TNeighbors);
    
    % if new energy worse (or same), restore previous labeling and done
    if E >= bestE
        printMessage(2, 'Discrete Optimization did not find a lower energy\n');
        labeling=l_;
        mhs=mhsafterrefit;
        E=E_; D=D_; S=S_; L=L_;
        nCurModels=length(mhs); nLabels=nCurModels+1; outlierLabel=nLabels;
        
        used=setdiff(unique(labeling),outlierLabel); nUsed=numel(used);
        break;
    end
    
    % otherwise refit and adjust models
    bestE=E;
    itcnt=itcnt+1;
    iteachcnt=iteachcnt+1;
    
    outlierLabel=nLabels;
    used=setdiff(unique(labeling),outlierLabel); nUsed=numel(used);
        
    % print update
    drawDCUpdate(mhs,used,alldpoints,labeling,outlierLabel,TNeighbors,frames);
    [m2d, m3d]=printDCUpdate(stateInfo,mhs,used,nAdded,nRemoved,iteachcnt,D,S,L);
    LOG_allens(iteachcnt,:)=double([D S L]);LOG_allmets2d(iteachcnt,:)=m2d;LOG_allmets3d(iteachcnt,:)=m3d;
    
    % now refit models (Eq. 1)
    mhsbeforerefit=mhs;
    mhsusedbeforerefit=mhs(used);
    mhsnew=reestimateSplines(alldpoints,used,labeling,nLabels,mhs,Dcost,T);
    %     mhsnew=reestimateSplines(allpoints,used,labeling,minCPs,ncpsPerFrame);
    mhsafterrefit=mhsnew;
    
    Dcost=getUnarySpline(nLabels,nPoints,mhsnew,alldpoints,opt.outlierCost,opt.unaryFactor,T);
    Lcost = getLabelCost(mhsnew);
    Scost=opt.pairwiseFactor-opt.pairwiseFactor*eye(nLabels);
    h=setupGCO(nPoints,nLabels,Dcost,Lcost,Scost,TNeighbors);
    GCO_SetLabeling(h,labeling);
    [E, D, S, L] = GCO_ComputeEnergy(h);    
    GCO_Delete(h);
    
    
    mhs(used)=mhsnew(used);
    nCurModels=length(mhs);
    clear Scost Dcost Lcost
    
    iteachcnt=iteachcnt+1;

    % print update
    drawDCUpdate(mhs,1:length(mhs),alldpoints,0,outlierLabel,TNeighbors,frames);
%     pause(.2);
    drawDCUpdate(mhs,used,alldpoints,labeling,outlierLabel,TNeighbors,frames);
    printDCUpdate(stateInfo,mhs,used,nAdded,nRemoved,iteachcnt,D,S,L);
    LOG_allens(iteachcnt,:)=double([D S L]);LOG_allmets2d(iteachcnt,:)=m2d;LOG_allmets3d(iteachcnt,:)=m3d;
    
%     %% Expand the hypothesis space
    if nCurModels<opt.maxModels
        nModelsBeforeAdded=nCurModels;
        
        %% get random new proposals
        mhsnew=getSplineProposals(alldpoints,nAddRandomModels,T);
        mhs=[mhs mhsnew];
        
        %% get new proposals from outliers
        outlierPoints=find(labeling==outlierLabel); % indexes
        if length(outlierPoints)>4
            outlpts=selectPointsSubset(alldpoints,outlierPoints);
            mhsnew=getSplineProposals(outlpts,nAddRandomModels,T);
            mhs=[mhs mhsnew];
        end
        
        %% extend existing
        mhs=extendSplines(alldpoints,mhs,used,labeling,T,E);
        
        %% merge existing
        mhs=mergeSplines(alldpoints,mhs,used,labeling,T,E);
        
    end
    nCurModels=length(mhs); nLabels=nCurModels+1; outlierLabel=nLabels;
    nAdded=nCurModels-length(mhsbeforerefit);
    

end
% basically we are done
printMessage(1,'All done (%.2f min = %.2fh = %.2f sec per frame)\n',toc(dcStartTime)/60,toc(dcStartTime)/3600,toc(dcStartTime)/stateInfo.F);

%% final plot
drawDCUpdate(mhs,used,alldpoints,labeling,outlierLabel,TNeighbors,frames);

%%
stateInfo=getStateFromSplines(mhs(used), stateInfo);
stateInfo=postProcessState(stateInfo);

%% if we have ground truth, evaluate results
% printFinalEvaluation(stateInfo)
% displayTrackingResult(sceneInfo,stateInfo)
%% Visuallization
if (~exist('tmp','dir')) 
    mkdir tmp;   
end
if opt.isSave2Video
    v = VideoWriter([opts.TrackFileTmpDir opts.TrackVideoFileName]);
    open(v);
end

% remove all the dummy human detection results and short trajectories
X = []; Y = []; W = []; H = [];
for cIdx = 1:size(stateInfo.X,2)
    cX = stateInfo.X(:,cIdx);
    cY = stateInfo.Y(:,cIdx);
    cW = stateInfo.W(:,cIdx);
    cH = stateInfo.H(:,cIdx);
    % detect dummy track
    for rIdx = 1:stateInfo.F
        if( abs(cX(rIdx)-opts.DummyDet(1)) < 0.01 )
            cX(rIdx) = opts.DummyDet(1);
        end
        if( abs(cY(rIdx)-opts.DummyDet(2)) < 0.01 )
            cY(rIdx) = opts.DummyDet(2);
        end
    end
    dummyX = find(cX==opts.DummyDet(1));
    dummyY = find(cY==opts.DummyDet(2));
    isDummy = isequal(dummyX,dummyY) && (~isempty(dummyX)) && (~isempty(dummyY));                
    % detect short track
    isShort =  size(find(cX),1)<opts.MinLength;  
    % store the track when it is neither the short track nor the dummy 
    % track
    if ( (~isDummy) && (~isShort) )
        X = [X, cX];
        Y = [Y, cY];
        W = [W, cW];
        H = [H, cH];            
    end
end

% convert to a new cordinate where the [X(i),Y(i)] stores the centroid index
% of a human
stateInfo.X = X;
stateInfo.Y = Y;
stateInfo.W = W;
stateInfo.H = H;
X = X+W./2;
Y = Y+H;
stateInfo.X = X;
stateInfo.Y = Y;
    
if opt.isVisual
    % Assign the frame window for evaluation
    FrameWindows = stateInfo.frameNums;
    % Get the number of frame for evaluation frames
    NoOfFrame = length(X);
    % Assign different color for all human ID
    NoOfID = size(X,2);
    Color = zeros(NoOfID,3);
    for i = 1:NoOfID
        Color(i,1:3) = [rand rand rand];
    end

    set(0, 'DefaultFigurePosition', [ 0 0 560 420]);
    fig = figure('name','Abnormal Trajectory Detection');

    for t = 1:NoOfFrame
    % for t = 1:100
        clf; % clear the current display    
        % Read the required image and map files
        FrameNum = FrameWindows(t);
        I = double(imread([sceneInfo.imgFolder,'\',sprintf(sceneInfo.imgFileFormat,FrameNum)]))/255;
        imshow(I);
        hold on;

        % Form temporal hm bbs
        hmID = find(W(t,:));

        % Bounding box
        if opt.isDispBB  
            for id = hmID                
                tW = W(t,id);
                tH = H(t,id);
                bleft=X(t,id)-tW./2;
                btop=Y(t,id)-tH;
                
    %             line([bleft bleft bright bright bleft],[btop bbottom bbottom btop btop],'color',getColorFromID(id),'linewidth',opt.boxLineWidth);
                rectangle(  'Position',[bleft,btop,W(t,id),H(t,id)],...
                            'Curvature',[.3,.3*(W(t,id)/H(t,id))],...
                            'EdgeColor',Color(id,:),...
                            'linewidth',opt.BBLineWidth);
            end        
        end

        % Footage
        if opt.isDispFootage
            for id = hmID
                plot(X(t,id),Y(t,id),'.','color',Color(id,:),'MarkerSize',opt.FootageWidth);
            end
        end

        % ID
        if opt.isDispID
            for id = hmID
                tx=X(t,id); 
                ty=Y(t,id)-H(t,id)*2/3; % inside
%                 ty=Y(t,id)-H(t,id)-10; % on top
                text(tx,ty,sprintf('%i',id),'color',Color(id,:), ...
                    'HorizontalAlignment','center', ...
                    'FontSize',W(t,id)/4, 'FontUnits','pixels','FontWeight','bold');
            end
        end

        % Trace
        if opt.isDispTrace
            min_t = max(1,t-opt.TraceLength);
            for id = hmID
                % Find the started appearing time t0_absolute 
                AppearWindow = W(min_t:t,id);
                t0_relative = find(AppearWindow, 1 ); % first appering moment
                if(t0_relative==1)
                    t0_absolute = min_t;
                elseif (length(AppearWindow) == t0_relative)
                    t0_absolute = t;
                else
                    delta_t = length(AppearWindow) - t0_relative;
                    t0_absolute = t - delta_t;
                end                
                % Form the most recent trace
                TraceX = (X(t0_absolute:t,id))'; 
                TraceY = (Y(t0_absolute:t,id))';   
                % Plot the line object
                line(TraceX,TraceY,'Color',Color(id,:),'LineWidth',opt.TraceLineWidth);
            end
        end   
        
        % save to images
        if opt.isSave2Video
            im2save = getframe(gcf);
            im2save = im2save.cdata;
            writeVideo(v,im2save);
%             im2save = imresize(im2save,0.5);
%             imwrite(im2save,['./tmp/',sprintf(sceneInfo.imgFileFormat,FrameNum)]);
        end
       
        pause(opt.pauseLength);
    end
    if opt.isSave2Video
        close(v);
    end
    fprintf('All done, check the ./tmp/mHumanTracking folder for results\n');
    close all;
end

%% Save all to matfile
save ([opts.TrackFileTmpDir opts.TrackFileName],'stateInfo');
