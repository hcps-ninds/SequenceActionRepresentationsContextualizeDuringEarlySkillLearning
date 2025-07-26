function do_KP_decoding_ROI_post(SubjectID)

addpath '/path/to/main_dir/'
source = get_source_data(SubjectID);
source_data = source.avg.mom;
source_data_left = source_data(1:length(source_data)/2);
source_data_right = source_data(length(source_data)/2+1:end);

addpath /path/to/FieldTrip/
ft_defaults

atlas_left = ft_read_atlas(['/path/to/freesurfer/' SubjectID '/workbench/' ...
    sprintf('%s.L.aparc.a2009s.8k_fs_LR.label.gii',SubjectID)]);
ind_left= atlas_left.parcellation;

atlas_right = ft_read_atlas(['/path/to/freesurfer/' SubjectID '/workbench/' ...
    sprintf('%s.R.aparc.a2009s.8k_fs_LR.label.gii',SubjectID)]);
ind_right = atlas_right.parcellation;

for i = 2:75
    ind = find(ind_left==i);
    left = cell2mat(source_data_left(ind));
    neg_ind = find(left(:,1) < 0);
    if length(neg_ind) > length(left)/2
        left(~neg_ind,:) = -left(~neg_ind,:);
    else
        left(neg_ind,:) = -left(neg_ind,:);
    end

    data_left(i-1,:) = mean(left);
    L{i-1,1} = left;

    ind = find(ind_right==i);
    right = cell2mat(source_data_right(ind));
    neg_ind = find(right(:,1) < 0);
    if length(neg_ind) > length(right)/2
        right(~neg_ind,:) = -right(~neg_ind,:);
    else
        right(neg_ind,:) = -right(neg_ind,:);
    end

    data_right(i-1,:) = mean(right);
    R{i-1,1} = right;
end

data = [data_left; data_right];
D = [L; R];

clearvars -except D SubjectID

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

%load(Files(sub).name)

feats = {'Mean', 'Median', 'RMS', 'STD', 'Kurtosis', 'Skewness', 'MAV'};

for s = 1:length(stimdur)
    for roi = 1:148
        if roi==32 
            roi=roi+1;
        end

        [kp_MEG_data, label] = get_kp_MEG_data_post(D{roi},...
            behav_all{sub,2},...
            behav_all{sub,1},...
            stimdur(s));

        for feat_type= 1:1 % can choose multiple features

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

                [cm{fold},numcorrect,precision,recall,f{fold}] = getcm (lab_test{fold},...
                    YPred,...
                    1:4);

                for key = 1:4
                    c(key) = length(find(lab_test{fold}==key));
                end
                c_sum = sum(c);
                weight = [c(1)/c_sum, c(2)/c_sum, c(3)/c_sum, c(4)/c_sum];

                f_mean(fold) = sum(weight.*f{fold});

                %clear Mdl

            end

            best = find(acc == max(acc));
            best= best(1);
            acc_final(roi,s) = acc(best);
            f_final{roi,s} = f{best};
            f_mean_final(roi,s)= f_mean(best);
            cm_final{roi,s} = cm{best};
            %mdl_final{vox,s} = Mdl{best};

        end
        disp(['ROI ', num2str(roi), ' finished' ])
    end
    disp(['s ', num2str(s), ' finished' ])

end

result.acc =acc_final;
result.f = f_final;
result.f_mean = f_mean_final;
result.cm = cm_final;
%result.Mdl = mdl_final;

cd /path/to/results_folder
mkdir(fullfile(pwd, 'output', 'ROI','results'))
save(fullfile(pwd, 'output', 'ROI', 'results', SubjectID), 'result');