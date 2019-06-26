function [tmp_AllPIXLabels] = mSP_Classification( I, Sp2, SPClassifier)    
    global SP_OPT;
    tmp_AllSPLabels = unique(Sp2);
    tmp_AllPIXLabels = Sp2;
    for i = 1:length(tmp_AllSPLabels) % for every superpixel
        % extract features of the current SP
        [tmp_x, tmp_y] = find(Sp2 == tmp_AllSPLabels(i)); % find all pixels in that SP
        tmp_SP_FT = [];        
        for j=1:length(tmp_x) % need faster               
            tmp_cur_pixel = reshape(I(tmp_x(j),tmp_y(j),:),[1,3]);  
            tmp_gray_level = rgb2gray(tmp_cur_pixel);
            tmp_curFT = [tmp_x(j)/1000,tmp_y(j)/1000,tmp_cur_pixel,tmp_gray_level(1)];
            tmp_SP_FT = [tmp_SP_FT;tmp_curFT];
        end
        tmp_SP_FT = mean(tmp_SP_FT);
        % clasifiy the current SP   
        if SP_OPT.isUseNN
            label = SP_OPT.net(tmp_SP_FT');
            label = vec2ind(label);
            if label == 2
                label = 0;
            else
                label = 1;
            end
        else
            [label,~,~] = predict(SPClassifier,tmp_SP_FT);
        end
%         % recheck the labeled human bb, correct human SP       
%         if( label==HUMAN && SP_Seg.isLabelHumanSP == true)
%             tmp = find(SP_Seg.SP_Human == tmp_AllSPLabels(i));
%             if(size(tmp,1)==0) % actually, its not inside a human bb
%                 label = hn_HUMAN; % assume that it is the hhard non-human SP 
%             end
%         end
        % label the pixels (need to find a faster way)
        for j=1:length(tmp_x)                
            tmp_AllPIXLabels(tmp_x(j),tmp_y(j)) =  label;
        end
    end 
    tmp_AllPIXLabels = tmp_AllPIXLabels./2;
end

