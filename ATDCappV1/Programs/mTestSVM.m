function TestSVM()
    global TrackResult;
    RandTestIdx = randi(size(TrackResult.TrackLabel,1),1,100000);
    trueLabel = TrackResult.TrackLabel(RandTestIdx)';
    testFeature = TrackResult.TrackFeature(RandTestIdx,:); 
    predictLabel = [];
    for i= 1:length(RandTestIdx)    
        [label,~,~] = predict(TrackResult.TrackClassifier,testFeature(i,:)); 
        if label == 1
            predictLabel = [predictLabel,[1;0]];
        else
            predictLabel = [predictLabel,[0;1]];
        end       
    end     
    NormIdx = find(trueLabel == 1);
    AnomalIdx = find(trueLabel == 2);
    trueLabel = [trueLabel;trueLabel];   
    trueLabel(1,NormIdx) = 1;
    trueLabel(2,NormIdx) = 0;
    trueLabel(1,AnomalIdx) = 0;
    trueLabel(2,AnomalIdx) = 1;    
    plotconfusion(predictLabel,trueLabel);
    [c,~] = confusion(trueLabel,predictLabel);
    fprintf('Test SVM classifier results\n');
    fprintf('Percentage Correct Classification   : %f%%\n', 100*(1-c));
    fprintf('Percentage Incorrect Classification : %f%%\n', 100*c);
    fprintf('\n');
end

