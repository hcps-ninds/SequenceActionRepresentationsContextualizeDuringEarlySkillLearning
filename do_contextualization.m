addpath \path\to\codes
addpath \path\to\codes\Matlab-Toolbox-for-Dimensionality-Reduction-master
addpath \path\to\codes\Matlab-Toolbox-for-Dimensionality-Reduction-master\techniques\
load('/path/to/labels.mat');
cd \path\to\hybrid

files = dir('*.mat');
c=1;
for dur = 50:50:300

    for sub = 1:length(files)
        load(files(sub).name);

        data_norm = normalize(data,'range',[0 1]);

        for trial = 1:36
            kp_ind = behav_all{sub,1}{trial,1};
            kp_id = behav_all{sub,2}{trial,1};
            op_id = behav_all{sub,3}{trial,1};
            n_kps(sub, trial) = length(kp_id);

            count1=0;
            count2=0;
            count3=0;
            count4=0;
            count5=0;

            for i = 1:length(kp_ind)
                if isnan(kp_ind(i))
                    i=i+1;
                elseif kp_id(i) ==1
                    count1 = count1+1;
                    n_kp{1}(sub,trial) = count1;
                    kp_idx{1}{sub,trial}(count1) = kp_ind(i);
                    trial_data{1}{sub,trial}{count1} = mean(data_norm(:,kp_idx{1}{sub,trial}(count1):kp_idx{1}{sub,trial}(count1)+dur-1)');
                elseif kp_id(i) == 2
                    count2 = count2+1;
                    n_kp{2}(sub,trial) = count2;
                    kp_idx{2}{sub,trial}(count2) = kp_ind(i);
                    trial_data{2}{sub,trial}{count2} = mean(data_norm(:,kp_idx{2}{sub,trial}(count2):kp_idx{2}{sub,trial}(count2)+dur-1)');
                elseif kp_id(i) == 3
                    count3 = count3+1;
                    n_kp{3}(sub,trial) = count3;
                    kp_idx{3}{sub,trial}(count3) = kp_ind(i);
                    trial_data{3}{sub,trial}{count3} = mean(data_norm(:,kp_idx{3}{sub,trial}(count3):kp_idx{3}{sub,trial}(count3)+dur-1)');
                elseif kp_id(i) == 4 && op_id(i) ==1
                    count4 = count4+1;
                    n_kp{4}(sub,trial) = count4;
                    kp_idx{4}{sub,trial}(count4) = kp_ind(i);
                    trial_data{4}{sub,trial}{count4} = mean(data_norm(:,kp_idx{4}{sub,trial}(count4):kp_idx{4}{sub,trial}(count4)+dur-1)');
                elseif kp_id(i) == 4 && op_id(i) ==5
                    count5 = count5+1;
                    n_kp{5}(sub,trial) = count5;
                    kp_idx{5}{sub,trial}(count5) = kp_ind(i);
                    trial_data{5}{sub,trial}{count5} = mean(data_norm(:,kp_idx{5}{sub,trial}(count5):kp_idx{5}{sub,trial}(count5)+dur-1)');
                end
            end
        end
    end

    lab = [1 2 3 4 5]';
    for i = 1:3
        for sub = 1:26
            for trial = 1:36
                while isempty(trial_data{1,1}{sub,trial})==1
                    trial_data{1,1}{sub,trial} = trial_data{1,1}{sub,trial+1};
                    trial_data{1,2}{sub,trial} = trial_data{1,2}{sub,trial+1};
                    trial_data{1,3}{sub,trial} = trial_data{1,3}{sub,trial+1};
                    trial_data{1,4}{sub,trial} = trial_data{1,4}{sub,trial+1};
                    trial_data{1,5}{sub,trial} = trial_data{1,5}{sub,trial+1};
                    trial=trial+1;
                end
            end
        end
    end

    %% Distance

    %Online
    for sub = 1:26
        for trial = 1:36
            feat_first4{sub}(trial,:) = normalize(trial_data{1,4}{sub,trial}{1,1});
            feat_last4{sub}(trial,:) = normalize(trial_data{1,5}{sub,trial}{1,end});
            on(sub,trial) = pdist2(feat_last4{sub}(trial,:),feat_first4{sub}(trial,:));
        end
    end

    %Offline
    for sub = 1:26
        for trial = 1:35
            off(sub,trial) = pdist2(feat_first4{sub}(trial+1,:),feat_last4{sub}(trial,:));
        end
    end

    % Online2
    for sub = 1:26
        for trial = 1:36
            for i = 1:floor(length(trial_data{1,4}{sub,trial})+length(trial_data{1,5}{sub,trial})/2)
                temp1 = normalize(trial_data{1,4}{sub,trial}{1,i});
                temp2 = normalize(trial_data{1,5}{sub,trial}{1,i});
                d2{sub,trial}(i) = pdist2(temp1,temp2);
            end
            od(sub,trial) = mean(d2{sub,trial});
        end
    end
    results{dur/50} = {on, off, od};
    %% Decoding

    for sub = 1:26
        for trial = 1:36
            temp2 = [];
            lab2 = [];
            for op = 4:5
                j = length(trial_data{1,op}{sub,trial});
                temp= [];
                lab = [];
                for i = 1:j
                    temp(i,:) = trial_data{1,op}{sub,trial}{1,i};
                    lab(i,1) = op;
                end
                temp2 = [temp2; temp];
                lab2 = [lab2;lab];
            end
            feat{sub,trial} = temp2;
            label{sub,trial} = lab2;
        end
    end

    for sub = 1:26
        for trial = 1:36
            feat_test = feat{sub,trial};
            lab_test = label{sub,trial};
            lab_sub_trial{sub,trial} = lab_test;

            t = feat(sub,:);
            t(:,trial) = [];

            y = label(sub,:);
            y(:,trial) = [];

            feat_train = [];
            lab_train = [];
            for i = 1:length(t)
                feat_train = [feat_train; t{1,i}];
                lab_train = [lab_train; y{1,i}];
            end

            all = [feat_train; feat_test];
            all_norm = normalize(all);

            all_norm = [[lab_train; lab_test] all_norm];

            reduced_feat = compute_mapping(all_norm,'LDA',4);
            %reduced_feat = all_norm;

            feat_train_norm = reduced_feat(1:length(feat_train),:);
            feat_test_norm = reduced_feat(length(feat_train)+1:end,:);
            feat_sub_trial{sub,trial} = feat_test_norm;

            for i = 1:3
                Mdl = fitcdiscr(feat_train_norm,lab_train,...
                    'OptimizeHyperparameters','auto',...
                    'HyperparameterOptimizationOptions',...
                    struct('AcquisitionFunctionName',...
                    'expected-improvement-plus',...
                    verbose=0, showplot = 0));


                YPred = predict(Mdl,feat_test_norm);
                a(i) = sum(YPred == lab_test)/length(lab_test)*100;
            end
            best = find(a==max(a));
            best = best(1);
            acc(sub,trial) = a(best);
        end

    end
    accuracy{c} = acc;
    c=c+1;
end

%% tSNE

for sub = 1:26
    for trial = 1:36
        x = feat{sub,trial};
        y = label{sub,trial};
        Y{sub,trial} = tsne(x);
    end
end


%% tsne all labels
clear all
load('tsne_post.mat')
load('for_tsne.mat')
sub=7; % Example subject
for trial = 1:36
    y_tsne{trial} = Y{sub,trial};
end

for trial = 1:36
    labels = lab_sub_trial{sub,trial};
    labels = categorical(labels);
    for i = 1:length(labels)
        if labels(i)=='1'
            labels(i) = 'Little';
        elseif labels(i)=='2'
            labels(i) = 'Ring';
        elseif labels(i) == '3'
            labels(i)='Middle';
        elseif labels(i)=='4'
            labels(i) = 'Index';
        end
    end
    lab_tsne{trial} = labels;
    clear labels
end

for trial = 1:1:36
    figure;gscatter(y_tsne{trial}(:,1), y_tsne{trial}(:,2), lab_tsne{trial},[],[],30)
    xlabel('tsne1')
    ylabel('tsne2')
    title(['Trial: ' num2str(trial)])
    set(gca, 'Box','on',...
        'LineWidth',2,...
        'TickDir','none',...
        'YTickLabel',[], ...
        'XTickLabel',[],...
        'fontsize',16);
    set(gcf, 'color', 'white')
    axis square
    legend('Location', 'bestoutside')
    xlim([-800 800])
    ylim([-1000 1100])
end

%% tsne op labels

lab_op_tsne= lab_tsne;
count=1;
t = [1 11 36];
for k=1:length(t)
    trial = t(k);

    little = find(lab_tsne{1,trial}=='Little');
    ring = find(lab_tsne{1,trial}=='Ring');
    middle = find(lab_tsne{1,trial}=='Middle');
    index = find(lab_tsne{1,trial}=='Index');
    index1 = index(1:1:length(index)-1);
    index2 = index(2:2:length(index));

    for i = 1:length(index1)
        lab_op_tsne{1,trial}(index1(i)) = 'Index_{OP1}';
    end

    for i = 1:length(index2)
        lab_op_tsne{1,trial}(index2(i)) = 'Index_{OP5}';
    end

    lab_tsne2 = lab_op_tsne{1,trial}([little(1:length(little)/2); ...
        ring(1:length(ring)/2); ...
        middle(1:length(middle)/2); ...
        index1; ...
        index2]);
    y_tsne2 = y_tsne{1,trial}([little(1:length(little)/2); ...
        ring(1:length(ring)/2); ...
        middle(1:length(middle)/2); ...
        index1; ...
        index2],:);

    figure;gscatter(y_tsne2(:,1), y_tsne2(:,2), lab_tsne2,[],[],30)
    %count=count+1;
    xlabel('tsne1')
    ylabel('tsne2')
    title(['Trial: ' num2str(trial)])
    set(gca, 'Box','on',...
        'LineWidth',2,...
        'TickDir','none',...
        'YTickLabel',[], ...
        'XTickLabel',[],...
        'fontsize',16);
    set(gcf, 'color', 'white')
    axis square
    legend('Location', 'bestoutside')
    xlim([-700 700])
    ylim([-1000 1100])
end

