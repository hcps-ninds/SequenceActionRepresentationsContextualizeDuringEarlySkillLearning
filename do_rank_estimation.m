function do_rank_estimation(SubjectID)

addpath '/path/to/data/'
source = get_source_data(SubjectID);
source_data = source.avg.mom;
clear source

source_data_left = source_data(1:length(source_data)/2);
source_data_right = source_data(length(source_data)/2+1:end);

addpath /path/to/fieldtrip/
ft_defaults

atlas_left = ft_read_atlas(['/path/to/freesurfer/' SubjectID '/workbench/' ...
    sprintf('%s.L.aparc.a2009s.8k_fs_LR.label.gii',SubjectID)]);
ind_left= atlas_left.parcellation;

atlas_right = ft_read_atlas(['/path/to/freesurfer/' SubjectID '/workbench/' ...
    sprintf('%s.R.aparc.a2009s.8k_fs_LR.label.gii',SubjectID)]);
ind_right = atlas_right.parcellation;

temp_left = [];
temp_right = [];

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

    templ  = [L{i-1,1}; data_left(i-1,:)];
    temp_left = [temp_left; templ];

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

    tempr  = [R{i-1,1}; data_right(i-1,:)];
    temp_right = [temp_right; tempr];
end

data = [data_left; data_right];
D = [L; R];
clearvars -except temp_right temp_left SubjectID
data_all = [temp_left;temp_right];

%clearvars -except data_all SubjectID

addpath /path/to/parcels
addpath /path/to/codes

Files = dir('/path/to/parcels/*.mat');

for i= 1:length(Files)
    if SubjectID == Files(i).name(1:8)
        sub=i;
    end
end
load(Files(sub).name)

r(1) = rank(data);
r(2) = rank(data_all);

cd /data/HCPS_MEG/Dave
mkdir(fullfile(pwd, 'output', 'Rank'))
save(fullfile(pwd, 'output', 'Rank', SubjectID), 'r');