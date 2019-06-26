%{    
    Extract features for SP
%}
function [SP_Human, SP_FT_Human, SP_FT_hnHuman, SP_FT_enHuman, Igt] = mSP_FeatureExtraction (I,Sp2,SP_OPT,bbs)
    %% Global variables
    HUMAN    = 2;
    hn_HUMAN = 1;
    en_HUMAN = 0;
    %% Initialization variables
    color_hm = [0,0,0];
    color_hnhm = [0.5,0.5,0.5];
    color_enhm = [-0.3,-0.3,-0.3];
    sizeX = size(I,1);
    sizeY = size(I,2);
    
    %% Extract bounding box
    % find the index of human in the current frame
    NoOfHuman   = length(bbs.xp); % bbidx is the human index
    bbX     = bbs.xp;
    bbY     = bbs.yp;
    bbH     = bbs.ht;
    bbW     = bbs.wd;
    % check the superpixel segmentation
%     figure(1); imshow(I); 

    %% Extract feature for the superpixels which are inside human regions
    I_sp2  = segImage(I,Sp2);
    Igt = I_sp2;
    
    % signal the bounding box which is in non-human-like area
    ResBB = [];    
    if(SP_OPT.isCheckBB == true)
        % Check if the current bounding box is in human-like area or not
        for i = 1:NoOfHuman                 
            % form the outside area of the footage
            deltaX = ceil(bbW(i)/8);
            deltaY1 = ceil(bbH(i)/1.5);
            deltaY2 = ceil(bbH(i)/8);
            xRange = [ max(ceil(bbX(i)) - deltaX,1), min(ceil(bbX(i)+bbW(i))+2*deltaX,sizeY)];
            yRange = [ max(ceil(bbY(i)) + deltaY1,1), min(ceil(bbY(i)+bbH(i))+deltaY2,sizeX)]; 
            tmpArea = SP_OPT.HumanlikeMap(yRange(1):yRange(2),xRange(1):xRange(2));
            PostmpArea = size(find(tmpArea>0),1);
            NegtmpArea = size(find(tmpArea==0),1);
            if(NegtmpArea>PostmpArea)
                ResBB = [ResBB;bbIdx(i)];
            end
        end
    end
    
    SP_Human = [];
    allWindowLabels = [];
    for i = 1:NoOfHuman % for every human bounding box        
        isInHumanLikeArea = true;
        % Check if the current bounding box is in human-like area or not
        if(SP_OPT.isCheckBB == true && size((find(ResBB == bbIdx(i))) , 1) > 0) 
            isInHumanLikeArea = false;
        end
        if(isInHumanLikeArea)
            % get the superpixel windows, which are inside human bbs
            xRange = [max(ceil(bbX(i)),1),min(ceil(bbX(i)+bbW(i)),sizeY)];
            yRange = [max(ceil(bbY(i)),1),min(ceil(bbY(i)+bbH(i)),sizeX)];   
            SP_HumanWindows{i} = Sp2(yRange(1):yRange(2),xRange(1):xRange(2));
            bbHumanWindow = SP_HumanWindows{i};
            bbHumanWindowArray = reshape(bbHumanWindow,[1,size(bbHumanWindow,1)*size(bbHumanWindow,2)]);
            allWindowLabels = [allWindowLabels,bbHumanWindowArray];
            % find all unique labels in SP_HumanWindows    
            SP_Human = [SP_Human;unique(bbHumanWindow)];
            % insert the human bounding box
            bb = [bbX(i),bbY(i),bbW(i),bbH(i)];
            Igt = insertShape(Igt,'Rectangle',bb,'LineWidth',6);
        end
    end
    % check the bounding box ground truth value
%     figure(2); imshow(Igt);

    % compute the overlap ratio of the group of superpixels which locate in 
    % both human and non-human areas
    SP_Human(:,2:4)=0;
    ignoreRate = 0.7;
    for i=1:size(SP_Human,1)
        % find the number of pixels labelled as SP_Human(i,1) in the whole
        % frame (1)
        SP_Human(i,2) = length((find(Sp2==SP_Human(i,1))));
        % find the number of pixels labelled as SP_Human(i,1) in the set of
        % human windows (2)
        SP_Human(i,3) = length((find(allWindowLabels==SP_Human(i,1))));
        % calculate the overlaping ratio: (2)/1
        SP_Human(i,4) = SP_Human(i,3)/SP_Human(i,2);
    end
    % diminish the superpixels that spend more space outside the human bbs,
    % decided by the value of ignoreRate
    igrnIdx = find(SP_Human(:,4)<=ignoreRate);
    SP_Human(igrnIdx,:) = [];
    SP_Human = SP_Human(:,1);
    % take all pixels in the human areas
    hmPixel = [];
    for i=1:length(SP_Human)
        [x,y,z] = find(Sp2 == SP_Human(i,1));   
        z = SP_Human(i,1).*ones(size(z));
        hmPixel = [hmPixel;[x,y,z]];
    end

    % extract feature for each superpixel in human areas
    SP_FT_Human = [];
    for i = 1:length(SP_Human)
    %for i = 1:1
       tmp_Idx = find(hmPixel(:,3) == SP_Human(i));
       tmp_hmSP = hmPixel(tmp_Idx,1:2);
       for j=1:length(tmp_hmSP)
           tmp_cur_pixel = reshape(I(tmp_hmSP(j,1),tmp_hmSP(j,2),:),[1,3]);       
           tmp_hmSP(j,1:2) = tmp_hmSP(j,1:2)./1000;
           tmp_hmSP(j,3:5) = tmp_cur_pixel;
           tmp_cur_pixel = rgb2gray(tmp_cur_pixel);
           tmp_hmSP(j,6) = tmp_cur_pixel(1);
       end
       SP_FT_Human = [SP_FT_Human;[mean(tmp_hmSP),HUMAN]];
    end

    % color the human superpixel regions
    for i =1 :length(hmPixel)
        tmp_Igt = Igt(hmPixel(i,1),hmPixel(i,2),:);
        tmp_Igt(1,1,1) = tmp_Igt(1,1,1) + color_hm(1);
        tmp_Igt(1,1,2) = tmp_Igt(1,1,2) + color_hm(2);
        tmp_Igt(1,1,3) = tmp_Igt(1,1,3) + color_hm(3);
        Igt(hmPixel(i,1),hmPixel(i,2),:) = tmp_Igt;
    end
    % check the superpixel inside human regions
%     figure(3), imshow(Igt);

    %% extract the superpixel just outside the human areas (bounding boxes)
    SP_hnHuman = [];
    for i=1:NoOfHuman
        isInHumanLikeArea = true;
        % Check if the current bounding box is in human-like area or not
        if(SP_OPT.isCheckBB == true && size((find(ResBB == bbIdx(i))) , 1) > 0) 
            isInHumanLikeArea = false;
        end        
        if(isInHumanLikeArea)
            % form the extraction areas just outside of human regions
            deltaX = ceil(bbW(i)/8);
            deltaY1 = ceil(bbH(i)/1.5);
            deltaY2 = ceil(bbH(i)/8);
            xRange = [ max(ceil(bbX(i)) - deltaX,1), min(ceil(bbX(i)+bbW(i))+2*deltaX,sizeY)];
            yRange = [ max(ceil(bbY(i)) + deltaY1,1), min(ceil(bbY(i)+bbH(i))+deltaY2,sizeX)];   
            tmpArea = unique(Sp2(yRange(1):yRange(2),xRange(1):xRange(2)));
            tmpSP_hnHuman = reshape(tmpArea,[1,size(tmpArea,1)*size(tmpArea,2)]);
            SP_hnHuman = [SP_hnHuman,tmpSP_hnHuman];
        end
    end

    % delete the human superpixels of SP_hnHuman
    for i=1:length(SP_Human)
        tmp = find(SP_hnHuman == SP_Human(i,1));
        SP_hnHuman(tmp)=[];
    end

    % take all pixels in the hard non-human areas
    hnhmPixel = [];
    SP_hnHuman =  SP_hnHuman';
    for i=1:length(SP_hnHuman)
        [x,y,z] = find(Sp2 == SP_hnHuman(i,1));   
        z = SP_hnHuman(i,1).*ones(size(z));
        hnhmPixel = [hnhmPixel;[x,y,z]];
    end

    % extract feature for each superpixel in hard non-human areas
    SP_FT_hnHuman = [];
    for i = 1:length(SP_hnHuman)
    %for i = 1:1
       tmp_Idx = find(hnhmPixel(:,3) == SP_hnHuman(i));
       tmp_pixel = hnhmPixel(tmp_Idx,1:2);
       for j=1:length(tmp_pixel)
           tmp_cur_pixel = reshape(I(tmp_pixel(j,1),tmp_pixel(j,2),:),[1,3]);    
           tmp_pixel(j,1:2) = tmp_pixel(j,1:2)./1000;
           tmp_pixel(j,3:5) = (tmp_cur_pixel);
           tmp_cur_pixel = rgb2gray(tmp_cur_pixel);
           tmp_pixel(j,6) = tmp_cur_pixel(1);
       end
       SP_FT_hnHuman = [SP_FT_hnHuman;[mean(tmp_pixel),hn_HUMAN]];
    end
    
    % color the hard non-human superpixel regions
    for i =1 :length(hnhmPixel)
        tmp_Igt = Igt(hnhmPixel(i,1),hnhmPixel(i,2),:);
        tmp_Igt(1,1,1) = tmp_Igt(1,1,1) + color_hnhm(1);
        tmp_Igt(1,1,2) = tmp_Igt(1,1,2) + color_hnhm(2);
        tmp_Igt(1,1,3) = tmp_Igt(1,1,3) + color_hnhm(3);
        Igt(hnhmPixel(i,1),hnhmPixel(i,2),:) = tmp_Igt;    
    end
    % check the superpixel which is just outside human regions
%     figure(4), imshow(Igt);

    %% extract the superpixels which are far from human bounding boxes
    % each human box contributes 4 far non-human superpixels randomly
    SP_enHuman = [];
    for i=1:NoOfHuman
        isInHumanLikeArea = true;
        % Check if the current bounding box is in human-like area or not
        if(SP_OPT.isCheckBB == true && size((find(ResBB == bbIdx(i))) , 1) > 0) 
            isInHumanLikeArea = false;
        end
        if(isInHumanLikeArea)
            % form the extraction areas far from human regions 
            deltaX = ceil(bbW(i));
            deltaY = ceil(bbH(i));
            StartX = max(ceil(bbX(i)) - deltaX,0);
            StartY = max(ceil(bbY(i)) - deltaY,0);   
            % chose a superpixel value randomly from the far regions satisfying the
            % conditions hereby
            spCnt = 0;
            while(spCnt<8)
                % get the superpixel randomly
                x = 1;
                y = 1;
                if(spCnt < 4)               
                        x = randi(max(sizeX-StartX,1));
                        y = randi(sizeY,1);               
                elseif(spCnt < 6)
                        x = randi([min(StartX+2*deltaX+ceil(bbW(i)),sizeX),sizeX]);
                        y = randi(sizeY,1);               
                elseif(spCnt < 8)
                        x = randi(sizeX);
                        y = randi(max(StartY-deltaY,1));               
                elseif(spCnt < 10)
                        x = randi(sizeX);
                        y = randi([min(StartY+2*deltaY+ceil(bbH(i)),sizeY),sizeY]);               
                end
                % check if the random superpixel is found in SP_hnHuman
                % and SP_Human (it can happen)
                isInSP_Human = find(SP_Human == Sp2(x,y));
                isInSP_hnHuman = find(SP_hnHuman == Sp2(x,y));
                if( size(isInSP_Human,1) == 0 && ...
                    size(isInSP_hnHuman,1) == 0 )
                    SP_enHuman = [SP_enHuman,Sp2(x,y)];
                    spCnt = spCnt + 1;
                end
            end
        end
    end 

    % extract all pixels in the easy non-human superpixels
    enhmPixel = [];
    SP_enHuman =  SP_enHuman';
    for i=1:length(SP_enHuman)
        [x,y,z] = find(Sp2 == SP_enHuman(i,1));   
        z = SP_enHuman(i,1).*ones(size(z));
        enhmPixel = [enhmPixel;[x,y,z]];
    end

    % extract feature for each superpixel in easy non-human areas
    SP_FT_enHuman = [];
    for i = 1:length(SP_enHuman)
    %for i = 1:1
       tmp_Idx = find(enhmPixel(:,3) == SP_enHuman(i));
       tmp_pixel = enhmPixel(tmp_Idx,1:2);
       for j=1:length(tmp_pixel)
           tmp_cur_pixel = reshape(I(tmp_pixel(j,1),tmp_pixel(j,2),:),[1,3]); 
           tmp_pixel(j,1:2) = tmp_pixel(j,1:2)./1000;
           tmp_pixel(j,3:5) = (tmp_cur_pixel);
           tmp_cur_pixel = rgb2gray(tmp_cur_pixel);
           tmp_pixel(j,6) = tmp_cur_pixel(1);
       end
       SP_FT_enHuman = [SP_FT_enHuman;[mean(tmp_pixel),en_HUMAN]];
    end
    
    % color the easy non-human superpixel regions
    for i =1 :length(enhmPixel)
        tmp_Igt = Igt(enhmPixel(i,1),enhmPixel(i,2),:);
        tmp_Igt(1,1,1) = tmp_Igt(1,1,1) + color_enhm(1);
        tmp_Igt(1,1,2) = tmp_Igt(1,1,2) + color_enhm(2);
        tmp_Igt(1,1,3) = tmp_Igt(1,1,3) + color_enhm(3);
        Igt(enhmPixel(i,1),enhmPixel(i,2),:) = tmp_Igt;    
    end
    % check the superpixels which are far from human bounding boxes    
%     figure(5), imshow(Igt);    
end

