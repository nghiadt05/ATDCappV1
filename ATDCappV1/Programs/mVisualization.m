function mVisualization

global opts;
global SP_OPT;
global TrackResult;


ADMatDir = dir([opts.AbnDetecDir '/' opts.Dataset '*.mat']);    
for ADFileIdx = 1:size(ADMatDir,1)
    load([opts.AbnDetecDir '/' ADMatDir(ADFileIdx).name]);
    
    X = stateInfo.X;
    Y = stateInfo.Y;
    H = stateInfo.H;
    W = stateInfo.W;
      
    if opts.isSave2Vid
        VideoFileName = [opts.AbnDetecDir '/' opts.Dataset sprintf('_AD_s%0.6d_e%0.6d.avi',stateInfo.frameNums(1),stateInfo.frameNums(end))];
        v = VideoWriter(VideoFileName);
        open(v);
    end
    
    % Assign different color for all human ID
    NoOfID = size(X,2);
    HMColor = zeros(NoOfID,3);
    for i = 1:NoOfID
        HMColor(i,1:3) = [rand rand rand];
    end
    
    set(0, 'DefaultFigurePosition', [1300 50 560 420]);
    figure('name','Abnormal Trajectory Detection');
    hold all;
        
    for FrameIdx = stateInfo.frameNums
        t = FrameIdx - stateInfo.frameNums(1) + 1;
        I = double(imread([opts.ImagesDir '\' sprintf(opts.ImageForm,FrameIdx)]))/255;      
        clf; % clear the current display
        imshow(I);
        hold on;
        
        % Form temporal hm bbs
        hmID = find(W(t,:));

        % get the rare track indx in the current frame 
        ProhitbitTrackIdx   = AbnTrackDet.ProhibitTrack{t};
        RareTrackIdx        = AbnTrackDet.RareTrack{t};        
        LowSpeedTrackIdx    = AbnTrackDet.SlowTrack{t};
        HighSpeedTrackIdx   = AbnTrackDet.FastTrack{t};
        
        % Bounding box
        if opts.isDispBB  
            for id = hmID
                bleft=X(t,id)-W(t,id)/2;
                bright=X(t,id)+W(t,id)/2;
                btop=Y(t,id)-H(t,id);
                bbottom=Y(t,id);
                
                % normal display configuration
                Color = HMColor(id,:);      
                BBLineWidth = opts.BBLineWidth;
                
                % warning for abnormal tracks in terms of GOING INTO
                % PROHIBITED AREAS
                if(~isempty((find(ProhitbitTrackIdx==id))))
                    Color = [1 0 0]; % red
                    BBLineWidth = opts.WarningBBLineWidth;                 
                end 
                                        
                % warning for abnormal tracks in terms of ABNORMAL DIRECTION
                % IN NON-PROHIBITTED AREAS                          
                if(~isempty((find(RareTrackIdx==id))))
                    Color = [1 0.65 0]; % orange
                    BBLineWidth = opts.WarningBBLineWidth;                 
                end   
                                         
                rectangle(  'Position',[bleft,btop,W(t,id),H(t,id)],...
                            'Curvature',[.3,.3*(W(t,id)/H(t,id))],...
                            'EdgeColor',Color,...
                            'linewidth',BBLineWidth);
                        
                % warning for abnormals track in terms of LOW OR HIGH SPEED
                if(~isempty((find(HighSpeedTrackIdx==id))))
                    Color = [0 1 0];
                    txt = 'Fast';                 
                end
                if(~isempty((find(LowSpeedTrackIdx==id))))
                    Color = [0 0 1];
                    txt = 'Slow';                 
                end
                if (~isempty((find(HighSpeedTrackIdx==id)))) || (~isempty((find(LowSpeedTrackIdx==id))))
                    tx=X(t,id); 
                    ty=Y(t,id)-H(t,id)-10; % on top
                    text(tx,ty,sprintf(txt),'color',Color, ...
                        'HorizontalAlignment','center', ...
                        'FontSize',W(t,id)/2.5, 'FontUnits','pixels','FontWeight','bold');
                end
            end        
        end
        
        % Footage
            if opts.isDispFootage
                for id = hmID
                    plot(X(t,id),Y(t,id),'.','color',HMColor(id,:),'MarkerSize',opts.FootageWidth);
                end
            end

            % ID
            if opts.isDispID
                for id = hmID
                    tx=X(t,id); 
                    ty=Y(t,id)-H(t,id)-10; % on top
                    text(tx,ty,sprintf('%i',id),'color',HMColor(id,:), ...
                        'HorizontalAlignment','center', ...
                        'FontSize',W(t,id)/6, 'FontUnits','pixels','FontWeight','bold');
                end
            end

            % Trace
            if opts.isDispTrace
                min_t = max(1,t-opts.TraceLength);
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
                    % assign warning signs                    
                    Color = HMColor(id,:);
                    TraceLineWidth = opts.BBLineWidth;                   
                    % Plot the line object
                    line(TraceX,TraceY,'Color',Color,'LineWidth',TraceLineWidth);
                end
            end   

            % save to images
            if opts.isSave2Vid
                im2save = getframe(gcf);
                im2save = im2save.cdata;
                writeVideo(v,im2save);
            end
            pause(opts.pauseLength);
    end    
    if opts.isSave2Vid
        close(v);
    end
    fprintf('All done, check tmp folder for results\n');
end