function feat_norm = get_MEG_feat(data, feat_type)

nSensors = size(data{1,1},2);

% statistical

for key =1:length(data)
    numTrials = size(data{1,key},1);
    for tr = 1:numTrials
        for sensor = 1:nSensors
            if strcmp(feat_type,'RMS') == 1
               feat{key}(tr,sensor) = rms(data{1,key}(tr,sensor,:));
            elseif strcmp(feat_type,'Mean') ==1
               feat{key}(tr,sensor) = mean(data{1,key}(tr,sensor,:));
            elseif strcmp(feat_type, 'Median') == 1
                feat{key}(tr,sensor) = median(data{1,key}(tr,sensor,:));
            elseif strcmp(feat_type, 'STD') == 1
                feat{key}(tr,sensor) = std(data{1,key}(tr,sensor,:));
            elseif strcmp(feat_type,'Kurtosis')
               feat{key}(tr,sensor) = kurtosis(data{1,key}(tr,sensor,:));
            elseif strcmp(feat_type,'Skewness')
               feat{key}(tr,sensor) = skewness(data{1,key}(tr,sensor,:));
            elseif strcmp(feat_type,'MAV')
               feat{key}(tr,sensor) = mean(abs(data{1,key}(tr,sensor,:)));
            else
               warning('Not the right feature');
            end
        end
    end
end


feat = [feat{1,1};feat{1,2};feat{1,3};feat{1,4}];
%feat = [feat{1,1};feat{1,2};feat{1,3};feat{1,4}; feat{1,5}]; % for op


for tr = 1:size(feat,1)
    feat_norm(tr,:) = (feat(tr,:) - mean(feat(tr,:)))/std(feat(tr,:));
end
