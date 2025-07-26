function [kp_MEG_data, labels] = get_kp_MEG_data_post(MEG_data,...
                                       kp,...
                                       kp_idx,...
                                       stimulus_duration)
% MEG_Data =   nsensors/nparcels/nvoxels/nspatial_features x nsamples
% get kp, kp_idx using get_behav_data.m

nTrials = length(kp_idx);

stimdur = stimulus_duration;
c1=1; c2=c1; c3=c2; c4=c3;

for t = 1:nTrials
    for i = 1:length(kp{t})
        if isnan(kp_idx{t,1}(i))
            break
        elseif kp{t,1}(i) ==1
                data1(c1,:,:) = MEG_data(:,kp_idx{t,1}(i):kp_idx{t,1}(i)+stimdur); 
                % data1(c1,:,:) = MEG_data(:,kp_idx{t,1}(i)-stimdur+1:kp_idx{t,1}(i)+stimdur); 
                % data1(c1,:,:) = MEG_data(:,kp_idx{t,1}(i)-stimdur+1:kp_idx{t,1}(i));

                c1=c1+1;
        elseif kp{t,1}(i) ==2
                data2(c2,:,:) = MEG_data(:,kp_idx{t,1}(i)-stimdur+1:kp_idx{t,1}(i)+stimdur);
                c2=c2+1;
        elseif kp{t,1}(i) ==3
                data3(c3,:,:) = MEG_data(:,kp_idx{t,1}(i)-stimdur+1:kp_idx{t,1}(i)+stimdur);
                c3=c3+1;
        elseif kp{t,1}(i) ==4
                data4(c4,:,:) = MEG_data(:,kp_idx{t,1}(i)-stimdur+1:kp_idx{t,1}(i)+stimdur);
                c4=c4+1;
        else
            warning('Stimulus other than 1 2 3 4');
        end
    end
end

kp_MEG_data = {data1, data2, data3, data4};

c1 = c1-1;
c2 = c2-1;
c3 = c3-1;
c4 = c4-1;

labels(1:c1,1) = 1;
labels(c1+1:c1+c2,1) = 2;
labels(c1+c2+1:c1+c2+c3,1) = 3;
labels(c1+c2+c3+1:c1+c2+c3+c4,1) = 4;

%% down sampling

% numTrials = min([c1,c2,c3,c4]);

% labels = zeros(4*numTrials,1);
% for tr = 1:numTrials
%     labels(tr)=1;
%     labels(tr+numTrials) = 2;
%     labels(tr+2*numTrials) = 3;
%     labels(tr+3*numTrials) = 4;
% end
% 
% data1 = data1(1:numTrials,:,:);
% data2 = data2(1:numTrials,:,:);
% data3 = data3(1:numTrials,:,:);
% data4 = data4(randi([1 c4], [1 numTrials]),:,:);

% kp_MEG_data = {data1, data2, data3, data4};






