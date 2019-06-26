function mPathTestClassifierV2()    
    fprintf('Evaluate the classifier ... \n');
    global opts;
    if opts.isUseSVM
        mTestSVM;
    end
    
    if opts.isUseNeuralNet
        mTestNN;
    end
end

