% Extract gaze data and labels
for sub = 1:26
    for trial = 1:36
        label{sub,1} = behav_all{sub,3};
        gaze{sub,1} = behav_all{sub,4};
        gaze{sub,2} = behav_all{sub,5};
    end
end

num_subjects = 26;
num_trials = 36;
num_labels = 5; 


for subj = 1:26

    X = []; % Gaze data 
    y = []; %  labels

    for trial = 1:36

        trial_gaze_x = gaze{subj, 1}{trial}; % x 
        trial_gaze_y = gaze{subj, 2}{trial}; % y 

        trial_labels = label{subj}{trial};
      
        for epoch = 1:length(trial_gaze_x)
            
            gaze_position = [trial_gaze_x(epoch), trial_gaze_y(epoch)];
            
            % Append the feature vector
            X = [X; gaze_position];
            % Append the corresponding label
            y = [y; trial_labels(epoch)];

        end

    end

    % Normalize the gaze data 
    X = normalize(X);
    % Train LDA Model with Hyperparameter Optimization
    mdl = fitcdiscr(X, y, ...
                    'OptimizeHyperparameters', 'auto', ...
                    'HyperparameterOptimizationOptions', struct(...
                    'AcquisitionFunctionName', 'expected-improvement-plus', ...
                    'Verbose', 0, ...
                    'ShowPlots', false ...
                    ));
   
    models{subj} = mdl;
    cv = crossval(mdl);
    classLoss = kfoldLoss(cv);
    accuracy = 1 - classLoss;
    overall_accuracy(subj) = accuracy;

    % Display accuracy for each subject
    disp(['Subject ' num2str(subj) ' Accuracy: ' num2str(accuracy)]);
end

mean_accuracy = mean(overall_accuracy);
disp(['Overall Mean Accuracy across subjects: ' num2str(mean_accuracy)]);
