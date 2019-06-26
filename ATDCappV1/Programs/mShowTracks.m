function mShowTracks(FigName,I,X,Y,LineWidth,isGP)   
    set(0, 'DefaultFigurePosition', [ 1300 50 560 420]);
    figure('name',FigName);
    if ~isGP
        imshow(I); 
    end
    hold on;
    for idx = 1:size(X,2)        
        tmpX = X(:,idx); 
        tmpY = Y(:,idx);
        nonZIndx = find(tmpX);
        TraceX = tmpX(nonZIndx);
        TraceY = tmpY(nonZIndx);  
        color = [rand rand rand];          
        line(TraceX,TraceY,'Color',color,'LineWidth',LineWidth);
        plot(TraceX(1),TraceY(1),'.','MarkerEdgeColor',color,'MarkerFaceColor',color,'MarkerSize',20);
        plot(TraceX(end),TraceY(end),'.','MarkerEdgeColor',color,'MarkerFaceColor',color,'MarkerSize',20);
    end
end

