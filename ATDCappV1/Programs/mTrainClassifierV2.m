function mTrainClassifierV2()
    global TrackResult;
    global opts;    
    st = clock;
    
    if opts.isUseSVM
        fprintf(' train SVM ...')
        TrackResult.TrackClassifier = fitcecoc( TrackResult.TrackFeature,...
                                                TrackResult.TrackLabel);

        fprintf(' train NN ...')
    end
    
    if opts.isUseNeuralNet
        % train the abnormal trajectory classifier based on direction
        % prepare the data
        fprintf('Train the directional abnormal track classifier \n');
        Feature = TrackResult.TrackFeature';
        Label = TrackResult.TrackLabel';        
        NormIdx = find(Label == 1);
        AnomalIdx = find(Label == 2);
        Label = [Label;Label];   
        Label(1,NormIdx) = 1;
        Label(2,NormIdx) = 0;
        Label(1,AnomalIdx) = 0;
        Label(2,AnomalIdx) = 1;
        % Create the neural net and start training
        net = fitnet(opts.NoOfNeural);
        [net,tr] = train(net,Feature,Label);
        TrackResult.net = net;
        TrackResult.tr = tr;    
        
        % train the abnormal trajectory classifier based on speed
%         fprintf('Train the speed abnormal track classifier \n');
%         speed_net = fitnet(opts.NoOfNeural);
%         [speed_net,speed_tr] = train(speed_net,TrackResult.TrackSpeedFeature,TrackResult.TrackSpeedLabel);
%         TrackResult.speed_net = speed_net;
%         TrackResult.speed_tr = speed_tr;
    end
    fprintf(' took %.2f minutes\n',etime(clock,st)/60);
end

