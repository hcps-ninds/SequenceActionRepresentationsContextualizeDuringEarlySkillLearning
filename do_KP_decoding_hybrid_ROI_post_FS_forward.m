function do_KP_decoding_hybrid_ROI_post_FS_forward(SubjectID)

addpath /path/to/codes/Matlab-Toolbox-for-Dimensionality-Reduction-master
addpath /path/to/codes/Matlab-Toolbox-for-Dimensionality-Reduction-master/techniques/

addpath '/data/HCPS_MEG/Dave/'
source = get_source_data(SubjectID);
source_data = source.avg.mom;
clear source

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

% temp_left = [];
% temp_right = [];

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

%     templ  = [L{i-1,1}; data_left(i-1,:)];
%     temp_left = [temp_left; templ];

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

%     tempr  = [R{i-1,1}; data_right(i-1,:)];
%     temp_right = [temp_right; tempr];
end

data = [data_left; data_right];
D = [L; R];

clearvars -except data D SubjectID

load(['/path/to//ROI_results/' SubjectID '.mat'])

[best_rois, best_win] = find(result.acc == max(result.acc(:)));
temp1 = sort(best_rois);
temp2 = sort(best_win);
best_rois = temp1(end);
best_win = temp2(end);
acc_forward = result.acc(best_rois,best_win);
f_forward = result.f(best_rois,best_win);
f_mean_forward  = result.f_mean(best_rois,best_win);
cm_forward = result.cm(best_rois,best_win);
clear result


load('/data/HCPS_MEG/Dave/Dave/output2/preprocessed/behav_all.mat');
load('/data/HCPS_MEG/Dave/Dave/output2/preprocessed/rest_start.mat');
load('/data/HCPS_MEG/Dave/Dave/output2/preprocessed/labels_orig.mat');

addpath /data/HCPS_MEG/Dave/Dave/output2/parcels
addpath /data/HCPS_MEG/Dave/codes

tr_dur = 6000;
nTrials = 36;
stimdur = 5:5:200;

Files = dir('/data/HCPS_MEG/Dave/Dave/output2/parcels/*.mat');

for i= 1:length(Files)
    if SubjectID == Files(i).name(1:8)
        sub=i;
    end
end

%load(Files(sub).name)

feats = {'Mean', 'Median', 'RMS', 'STD', 'Kurtosis', 'Skewness', 'MAV'};

load(['/data/HCPS_MEG/Dave/Dave/output2/KPDecoding/OS/Parcel/Pre/LDA/Broadband/' SubjectID '.mat'])
best_win = find(result.acc == max(result.acc(:)));
s = best_win(1);
clear result

for ii = 1:146

for roi = 1:148

if ismember(roi,best_rois) ~=1

    data_current = [data_all; D{roi}];

    [kp_MEG_data, label] = get_kp_MEG_data_pre(data_current,...
        behav_all{sub,2},...
        behav_all{sub,1},...
        stimdur(s));

    feat_type= 1;

    feat = get_MEG_feat(kp_MEG_data,feats(feat_type));
    feat = [label feat];
    
    for k = 1:3
    reduced_feat = compute_mapping(feat,'LDA',k);

    folds = 8;
    cv = cvpartition(labels{sub},'KFold',folds);

    for fold = 1:folds
        ids{fold} = training(cv,fold);
        
        feat_train{fold} = reduced_feat(ids{fold},:);
        feat_test{fold} = reduced_feat(~ids{fold},:);

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
    acc_final(k) = acc(best);
    f_final{k} = f{best};
    f_mean_final(k)= f_mean(best);
    cm_final{k} = cm{best};
    %mdl_final{roi,k} = Mdl{best};
end

    best = find(acc_final == max(acc_final));
    best= best(1); 
    acc_current(roi) = acc_final(best);
    f_current{roi} = f_final{best};
    f_mean_current(roi)= f_mean_final(best);
    cm_current{roi} = cm_final{best};
end

end
    
    best = find(acc_current == max(acc_current));
    best= best(end); 
    temp_acc  = acc_current(best);
    %if temp_acc > acc_forward(end)
        acc_forward = [acc_forward;temp_acc]

        f_forward = [f_forward;f_current(best)];
        f_mean_forward = [f_mean_forward; f_mean_current(best)];
        cm_forward = [cm_forward; cm_current(best)];

        best_rois = [best_rois; best];
        data_all = [data_all; D{best}];
    %end

%     disp(['roi ', num2str(roi), ' finished' ])

    result.acc =acc_forward;
    result.f = f_forward;
    result.f_mean = f_mean_forward;
    result.cm = cm_forward;
    result.rois = best_rois;
    %result.Mdl = mdl_final;

    cd /path/to/results_folder
    mkdir(fullfile(pwd, 'output', 'Hybrid_ROI_Forward_FS','results'))
    save(fullfile(pwd, 'output', 'Hybrid_ROI_Forward_FS', 'results', SubjectID), 'result');
end
