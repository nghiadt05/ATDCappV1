function [ tmpXn,tmpYn ] = mPathResizeLength( tmpX, tmpY , NormalizeLength )
    global opts;
    tmpTrackLength = length(tmpX);
    if(tmpTrackLength > NormalizeLength)
        d = tmpTrackLength / NormalizeLength;
        tmpXn(1) = tmpX(1);
        tmpYn(1) = tmpY(1);
        for j = 2: (NormalizeLength-1)
            pickIdx = ceil(d*j);
            tmpXn(j) = tmpX(pickIdx);
            tmpYn(j) = tmpY(pickIdx);
%                 disp(pickIdx);
        end
        tmpXn(NormalizeLength) = tmpX(end);
        tmpYn(NormalizeLength) = tmpY(end);
        tmpXn = tmpXn';
        tmpYn = tmpYn';
    elseif (tmpTrackLength< NormalizeLength)              
        % padding the original track before interpolation
        tmpBeginPads = [];
        tmpEndPads = [];
        for j = 1:(opts.FilterSize-1)
            tmpBeginPads(j,1) = tmpX(1);
            tmpEndPads(j,1) = tmpX(end);
            tmpBeginPads(j,2) = tmpY(1);
            tmpEndPads(j,2) = tmpY(end);
        end
        % keep interpolating until the length of the interpolated
        % vector exceeds the normalization length
        while(length(tmpX)<NormalizeLength)
            tmpXpadding = [tmpBeginPads(:,1);tmpX;tmpEndPads(:,1)];
            tmpYpadding = [tmpBeginPads(:,2);tmpY;tmpEndPads(:,2)];
            % interpolation
            tmpXitp = [];
            tmpYitp = [];
            for j=opts.FilterSize:(length(tmpXpadding)-opts.FilterSize)
                tmpWindowX = (tmpXpadding(j-(opts.FilterSize-1):(j+opts.FilterSize)))';
                tmpWindowY = (tmpYpadding(j-(opts.FilterSize-1):(j+opts.FilterSize)))';
                tmpXitp = [tmpXitp;tmpWindowX*opts.GaussWin];
                tmpYitp = [tmpYitp;tmpWindowY*opts.GaussWin];
%                 tmpWindowX = tmpWindowX;
            end
            % join the original part and the interpolated part
            tmpXnew = [];
            tmpYnew = [];
            for j=1:(length(tmpX)-1)
                tmpXnew(2*j-1)  = tmpX(j);
                tmpXnew(2*j)    = tmpXitp(j);
                tmpYnew(2*j-1)  = tmpY(j);
                tmpYnew(2*j)    = tmpYitp(j);
            end
            tmpX = tmpXnew';
            tmpY = tmpYnew';
        end
        % reform to the normalization length
        d = length(tmpX) / NormalizeLength;
        tmpXn(1) = tmpX(1);
        tmpYn(1) = tmpY(1);
        for j = 2: (NormalizeLength-1)
            pickIdx = ceil(d*j);
            tmpXn(j) = tmpX(pickIdx);
            tmpYn(j) = tmpY(pickIdx);
%                 disp(pickIdx);
        end
        tmpXn(NormalizeLength) = tmpX(end);
        tmpYn(NormalizeLength) = tmpY(end);
        tmpXn = tmpXn';
        tmpYn = tmpYn';
    else
        tmpXn = tmpX;
        tmpYn = tmpY;
    end          
end

