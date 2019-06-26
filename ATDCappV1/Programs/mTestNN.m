function TestNN()
    % test NN classifier
    global TrackResult;
    Feature = TrackResult.TrackFeature';
    Label = TrackResult.TrackLabel';        
    NormIdx = find(Label == 1);
    AnomalIdx = find(Label == 2);
    Label = [Label;Label];   
    Label(1,NormIdx) = 1;
    Label(2,NormIdx) = 0;
    Label(1,AnomalIdx) = 0;
    Label(2,AnomalIdx) = 1;
    % test for abnormal tracks detection in term of direction 
    testFeature = Feature(:,TrackResult.tr.testInd);
    trueLabel = Label(:,TrackResult.tr.testInd);
    predictLabel = TrackResult.net(testFeature);        
    plotconfusion(predictLabel,trueLabel);
    [c,~] = confusion(trueLabel,predictLabel);
    fprintf('Test NN classifier for abnormal track detection in term of DIRECTION\n');
    fprintf('Percentage Correct Classification   : %f%%\n', 100*(1-c));
    fprintf('Percentage Incorrect Classification : %f%%\n', 100*c);
    
    % test for abnormal tracks detection in term of speed
%     testFeature = TrackResult.TrackSpeedFeature(:,TrackResult.speed_tr.testInd);
%     trueLabel = TrackResult.TrackSpeedLabel(:,TrackResult.speed_tr.testInd);
%     predictLabel = TrackResult.speed_net(testFeature);        
%     plotconfusion(predictLabel,trueLabel);
%     [c,~] = confusion(trueLabel,predictLabel);
%     fprintf('Test NN classifier for abnormal track detection in term of SPEED\n');
%     fprintf('Percentage Correct Classification   : %f%%\n', 100*(1-c));
%     fprintf('Percentage Incorrect Classification : %f%%\n', 100*c);
end

