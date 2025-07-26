function data = get_parcel_data(SubjectID)

% SubjectID is the key to identify the folder for a specific subject

addpath ('/path/to/functions')
addpath ('/path/to/MEGData')

source = get_source_data(SubjectID);
source_data = source.avg.mom;
source_data_left = source_data(1:length(source_data)/2);
source_data_right = source_data(length(source_data)/2+1:end);

addpath('/path/to/fieldtrip');
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
    
    ind = find(ind_right==i);
    right = cell2mat(source_data_right(ind));
    neg_ind = find(right(:,1) < 0);
    if length(neg_ind) > length(right)/2
        right(~neg_ind,:) = -right(~neg_ind,:);
    else
        right(neg_ind,:) = -right(neg_ind,:);
    end

    data_right(i-1,:) = mean(right);

end

data = [data_left; data_right];

mkdir(fullfile(pwd, 'output', 'parcels'))
save(fullfile(pwd, 'output', 'parcels',SubjectID), 'data');
end