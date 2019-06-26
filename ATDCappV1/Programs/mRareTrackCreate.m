function [ CreatedRareTrack ] = mRareTrackCreate()
    %{
        Create more rare track samples from the normal ones
        1. Preserve the real properties such as curves and speeds of human
        tracks.
        2. If we generate rare tracks by simulate them -> that properties can
        be so different for the real tracked ones

        Steps:
        1. Randomly pick a normal track
        2. Move to the pointed position
        3. Draw the base line for the normal one
        4. Generate several tracks regarding the based line
    %}
    global opts;
    global TrackResult;

    % Create the set of based lines 
    if ~exist('.\tmp\mAbnormalTrackDetection\SeedTrack.mat','file')
        fprintf('Please creat the seed tracks for rare tracks.\n');
        figure();
        imshow(opts.SampImage);hold all;
        for i=1:opts.NoOfSeedTracks
            fprintf('Create the rare-seed tracks %d/%d\n',i,opts.NoOfSeedTracks);
            [x,y] = ginput(2);    
            SeedTrack{i}.X = x;
            SeedTrack{i}.Y = y;
            line(x,y,'LineWidth',2,'color','k');
        end
        save('.\tmp\mAbnormalTrackDetection\SeedTrack','SeedTrack');
        fprintf('Done creating rare seed tracks and saved. \n');
    else
        load('.\tmp\mAbnormalTrackDetection\SeedTrack.mat');
        figure('name','Seed tracks for rare trajectories');
        imshow(opts.SampImage);hold all;
        for i=1:opts.NoOfSeedTracks
            line(SeedTrack{i}.X,SeedTrack{i}.Y,'LineWidth',2,'color','k');
        end
    end

    isDone = false;
    i = 1;
    NoOfRareTrack = 1;
    CreatedRareTrack = [];
    while ~isDone 
        %
        clf;
        imshow(opts.SampImage);hold all;

        % get a normal line which length is larger than MinLength
        NormalTrack = find(TrackResult.HandLabeledTracks == 1);
        RandIndx =randi(length(NormalTrack));
        normalX = TrackResult.X(:,NormalTrack(RandIndx)); normalX = normalX((find(normalX)));
        normalY = TrackResult.Y(:,NormalTrack(RandIndx)); normalY = normalY((find(normalY)));
        alpha1 =  atan((normalY(end)-normalY(1))/(normalX(end)-normalX(1))) ;
        line(normalX,normalY,'LineWidth',3,'color','r');
        meanX = mean(normalX);
        meanY = mean(normalY);

        % get the current abnormal seed track
        x = SeedTrack{i}.X;
        y = SeedTrack{i}.Y;
        alpha2 = atan((y(end)-y(1))/(x(end)-x(1)));
        meanXp = mean(x);
        meanYp = mean(y);
        line(x,y,'LineWidth',2,'color','k');

        % get the vector of the based line center and the normal line center then
        % translate the normal track to the new position
        vecX = meanXp - meanX;
        vecY = meanYp - meanY;
        normalX = normalX + vecX;
        normalY = normalY + vecY;
        meanX = mean(normalX);
        meanY = mean(normalY);
    %     line(normalX,normalY,'LineWidth',2,'color','b');

        % rotate the normal line to make it lie on the based line, besides, creates
        % more lines by variating the small value of alpha
        alpha = -alpha1 + alpha2;
        for j = 1:opts.RotateSampe
            variation = opts.MaxRotateAngle*(2*rand-1);
            alpha = alpha + variation;
            tmp_normalX = normalX - meanX;
            tmp_normalY = normalY - meanY;
            rotMat = [cos(alpha),sin(alpha);-sin(alpha),cos(alpha)];
            rotateTrace =  [tmp_normalX,tmp_normalY]*rotMat;
            rotateX = rotateTrace(:,1) + meanX;
            rotateY = rotateTrace(:,2) + meanY;        
            line(rotateX,rotateY,'LineWidth',2,'color',[rand rand rand]); 
            CreatedRareTrack{NoOfRareTrack}.Trace = [rotateX,rotateY];
            CreatedRareTrack{NoOfRareTrack}.Label = 2;
            NoOfRareTrack = NoOfRareTrack + 1;            
        end
        prompt = 'Press:" Y: keep results/ B: redo /Q: to quit [Y]:" ';
            str = input(prompt,'s');
            disp(str);
            if isempty(str)
                str = 'Y';
            end
            if (strcmp(str,'Y')||strcmp(str,'y'))              
                i = i + 1;
                fprintf('Keep the current results\n');
            elseif (strcmp(str,'B')||strcmp(str,'b'))                
                NoOfRareTrack = NoOfRareTrack - opts.RotateSampe;                
                if(i<1),i=1;end;
                fprintf('Redo\n');
            elseif (strcmp(str,'Q')||strcmp(str,'q'))            
                isFinish = true;           
                fprintf('Quit\n');
            end     
        if i== (opts.NoOfSeedTracks+1)
            isDone = true;
        end    
    end
end

