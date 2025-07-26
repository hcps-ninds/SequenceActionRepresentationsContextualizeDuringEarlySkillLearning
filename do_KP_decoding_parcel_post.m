function do_KP_decoding_parcel_post(SubjectID)

load('/path/to/behav_data.mat');
load('/path/to/rest_start_data.mat');
load('/path/to/labels.mat');

addpath /path/to/parcels
addpath /path/to/codes

tr_dur = 6000;
nTrials = 36;
stimdur = 5:5:200;

Files = dir('/path/to/parcels/*.mat');

for i= 1:length(Files)
    if SubjectID == Files(i).name(1:8)
        sub=i;
    end
end


% data = get_parcel_data(SubjectID); % load saved data or call the fun 

load(Files(sub).name)

feats = {'Mean', 'Median', 'RMS', 'STD', 'Kurtosis', 'Skewness', 'MAV'};

for s = 1:length(stimdur)

    [kp_MEG_data, label] = get_kp_MEG_data_post(data,...
        behav_all{sub,2},...
        behav_all{sub,1},...
        stimdur(s));

    feat_type = 1;

    feat = get_MEG_feat(kp_MEG_data,feats(feat_type));

    folds = 8;
    cv = cvpartition(labels{sub},'KFold',folds);

    for fold = 1:folds
        ids{fold} = training(cv,fold);
        feat_train{fold} = feat(ids{fold},:);
        feat_test{fold} = feat(~ids{fold},:);
        lab_train{fold} = labels{sub}(ids{fold});
        lab_test{fold} = labels{sub}(~ids{fold});

        for kp = 1:4
            n_orig(kp) = length(find(lab_train{fold}==kp));
            idx = find(lab_train{fold}==kp);
            id(kp) = idx(1);
            feat_kp{kp} = feat_train{fold}(id(kp):id(kp)+n_orig(kp)-1,:);
            lab_kp{kp} = lab_train{fold}(id(kp):id(kp)+n_orig(kp)-1,:);
        end

        feat_all{fold} = [feat_kp{1}; feat_kp{1};...
            feat_kp{2}; feat_kp{2};...
            feat_kp{3}; feat_kp{3};...
            feat_kp{4}];

        lab_all{fold} =  [lab_kp{1}; lab_kp{1};...
            lab_kp{2}; lab_kp{2};...
            lab_kp{3}; lab_kp{3};...
            lab_kp{4}];


        %% LDA
               Mdl{fold} = fitcdiscr(feat_all{fold},lab_all{fold},...
                    'OptimizeHyperparameters','auto',...
                    'HyperparameterOptimizationOptions',...
                    struct('AcquisitionFunctionName',...
                    'expected-improvement-plus',...
                    verbose=0, showplot = 0));

        %SVM
%         template = templateSVM(...
%             'KernelFunction', 'RBF', ...
%             'Standardize', true);
% 
%         Mdl{fold} = fitcecoc(...
%             feat_all{fold}, ...
%             lab_all{fold}, ...
%             'Learners', template, ...
%             'ClassNames', {'1';'2';'3';'4'},...
%             'OptimizeHyperparameters','auto',...
%             'HyperparameterOptimizationOptions',...
%             struct('AcquisitionFunctionName',...
%             'expected-improvement-plus',...
%             verbose=1, showplot = 0));

        % ANN
         % Mdl{fold} = fitcnet(feat_all{fold},lab_all{fold},...
         %            'OptimizeHyperparameters','auto',...
         %            'HyperparameterOptimizationOptions',...
         %            struct('AcquisitionFunctionName',...
         %            'expected-improvement-plus',...
         %            "MaxObjectiveEvaluations",100,...
         %            verbose=0, showplot = 0));

        %close all

        YPred = predict(Mdl{fold},feat_test{fold});
        acc(fold) = sum(YPred == lab_test{fold})/length(lab_test{fold})*100;

        [cm{fold},numcorrect,precision,recall,f{fold}] = getcm(lab_test{fold},...
            YPred,...
            1:4);

        for key = 1:4
            c(key) = length(find(lab_test{fold}==key));
        end
        c_sum = sum(c);
        weight = [c(1)/c_sum, c(2)/c_sum, c(3)/c_sum, c(4)/c_sum];

        f_mean(fold) = sum(weight.*f{fold});

        % clear Mdl

    end

    best = find(acc == max(acc));
    best= best(1);
    acc_final(1,s) = acc(best)
    f_final{1,s} = f{best};
    f_mean_final(1,s)= f_mean(best);
    cm_final{1,s} = cm{best};
    mdl_final{1,s} = Mdl{best};

end

result.acc =acc_final;
result.f = f_final;
result.f_mean = f_mean_final;
result.cm = cm_final;
%result.Mdl = mdl_final;

cd /path/to/results_folder
mkdir(fullfile(pwd,  'output', 'parcels','results'))
save(fullfile(pwd,'output', 'parcels', 'results', SubjectID), 'result');