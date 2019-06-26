function [ invX, invY ] = mInverseTrack( X,Y )
    TrackLength = length(X);
    for i=1:TrackLength
        invX(TrackLength-i+1) = X(i);
        invY(TrackLength-i+1) = Y(i);
    end
    invX = invX';
    invY = invY';
end

