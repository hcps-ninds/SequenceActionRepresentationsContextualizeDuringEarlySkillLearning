function source = do_KP_decoding_voxel_post(SubjectID)

addpath '/path/to/main_dir/'
addpath /path/to/parcels_data
addpath /path/to//codes


source = get_source_data(SubjectID);
data = cell2mat(source.avg.mom);

clearvars -except data SubjectID 

%% Decoding
load('/path/to/behav_data.mat');
load('/path/to/rest_start_data.mat');
load('/path/to/labels.mat');

tr_dur = 6000;
nTrials = 36;
stimdur = 5:5:200;

Files = dir('/path/to/parcels/*.mat');

for i= 1:length(Files)
    if SubjectID == Files(i).name(1:8)
        sub=i;
    end
end

feats = {'Mean', 'Median', 'RMS', 'STD', 'Kurtosis', 'Skewness', 'MAV'};

for s = 1:length(stimdur)

    [kp_MEG_data, label] = get_kp_MEG_data_post(data,...
        behav_all{sub,2},...
        behav_all{sub,1},...
        stimdur(s));

    feat_type= 1;

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

        Mdl{fold} = fitcdiscr(feat_all{fold},lab_all{fold},...
            'OptimizeHyperparameters','auto',...
            'HyperparameterOptimizationOptions',...
            struct('AcquisitionFunctionName',...
            'expected-improvement-plus',...
            verbose=0, showplot = 0));

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
    acc_final(fb,s) = acc(best);
    f_final{fb,s} = f{best};
    f_mean_final(fb,s)= f_mean(best);
    cm_final{fb,s} = cm{best};
    %mdl_final{feat_type,s} = Mdl{best};
end
fb
result.acc =acc_final;
result.f = f_final;
result.f_mean = f_mean_final;
result.cm = cm_final;
%result.Mdl = mdl_final;

cd /path/to/results_folder
mkdir(fullfile(pwd, 'output', 'Voxel','results'))
save(fullfile(pwd, 'output', 'Voxel', 'results', SubjectID), 'result');

end


