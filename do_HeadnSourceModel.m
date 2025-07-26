function do_HeadnSourceModel(subjectID)

% subjectID is the name of the folder identification key

addpath('/path/to/data'); % addpath to data

% Initialize Fieldtrip
addpath('/path/to/fieldtrip'); % addpath to fieldtrip
ft_defaults

% Get MRI data
mri_dir = dir(fullfile(pwd, ['/path/to/BrainSightData/' subjectID '_T1.nii.gz']));
file_name = fullfile(mri_dir.folder, mri_dir.name);
mri = ft_read_mri(file_name);
mri.anatomy = double(mri.anatomy);

% Get Coil positions from Brainsight Data
coil_dir = dir(fullfile(pwd, ['/path/to/BrainSightData/' subjectID '_CoilPosAll.txt']));
file_name = fullfile(coil_dir.folder, coil_dir.name);
temp = import_coil(file_name, [8 10]);
coils = [];
coils.labels = cellstr(temp.Labels);
coils.position = [temp.LocX, temp.LocY, temp.LocZ];

% Reslicing
cfg = [];
cfg.resolution = 1;
cfg.range = [256 256 256];
mri = ft_volumereslice(cfg, mri);
mri.coordsys = 'scanras';

% Reallignment to a template MRI
cfg = [];
cfg.method = 'spm';
cfg.coordsys = 'acpc';
cfg.viewresult = 'yes';
cfg.spmversion = 'spm12';
target = ft_read_mri(fullfile('/path/to/fieldtrip_template_data'));
mri_acpc = ft_volumerealign(cfg, mri, target);
scanras2acpc = mri_acpc.transform/mri.transform;

% Reslice to acpc
acpc_nas = ft_warp_apply(scanras2acpc, coils.position(strcmp(coils.labels, 'NEC'), :));
acpc_lpa = ft_warp_apply(scanras2acpc, coils.position(strcmp(coils.labels, 'LEC'), :));
acpc_rpa = ft_warp_apply(scanras2acpc, coils.position(strcmp(coils.labels, 'REC'), :));

cfg = [];
cfg.resolution = 1;
cfg.range = [256 256 256];
mri_acpc = ft_volumereslice(cfg, mri_acpc);
mri_acpc.coordsys = 'acpc';

% get transfermatrix
acpc2ctf = ft_headcoordinates(acpc_nas, acpc_lpa, acpc_rpa, [], 'ctf');
ctf2acpc = inv(acpc2ctf);
mkdir(fullfile(pwd, 'output', 'transfer_matrix'))
save(fullfile(pwd, 'output', 'transfer_matrix', subjectID), 'acpc2ctf', 'ctf2acpc');

cfg = [];
mri_acpc = ft_volumebiascorrect(cfg, mri_acpc);

cfg = [];
cfg.method = 'brain';
%cfg.output    = {'brain','skull','scalp'};
seg = ft_volumesegment(cfg, mri_acpc);

% cfg=[];
% cfg.tissue={'brain','skull','scalp'};
% cfg.numvertices = [3000 2000 1000];
% bnd=ft_prepare_mesh(cfg,seg);

cfg        = [];
%cfg.method = 'openmeeg';
cfg.method = 'singleshell';
%headmodel  = ft_prepare_headmodel(cfg, bnd);
headmodel  = ft_prepare_headmodel(cfg, seg);
mkdir(fullfile(pwd, 'output', 'headmodel'))
save(fullfile(pwd, 'output', 'headmodel', subjectID), 'headmodel');

% cfg = [];
% cfg.intersectmesh = headmodel.bnd;
% cfg.visible = 'off';
% ft_sourceplot(cfg, mri_acpc);
% mkdir(fullfile(pwd, 'figures'))
% print('-djpeg', ['./figures/' subjectID '.jpg']);

freesurfer_fodler = fullfile(pwd, 'output', 'freesurfer');
mkdir(freesurfer_fodler);
cfg = [];
cfg.filename = fullfile(freesurfer_fodler, subjectID);
cfg.filetype = 'mgz';
cfg.parameter = 'anatomy';
ft_volumewrite(cfg, mri_acpc);

[dum, ft_path] = ft_version;
scriptname = fullfile(ft_path,'bin','ft_freesurferscript.sh');
cmd_str    = sprintf("%s %s %s", scriptname, freesurfer_fodler, subjectID);
system(cmd_str)

[dum, ft_path] = ft_version;
scriptname = fullfile(ft_path,'bin','ft_postfreesurferscript.sh');
templ_dir  = fullfile(pwd, '/path/to/HCPpipelines/global/templates/standard_mesh_atlases');
cmd_str    = sprintf("%s %s %s %s", scriptname, freesurfer_fodler, subjectID, templ_dir);
system(cmd_str)

workbench_fodler = fullfile(freesurfer_fodler, subjectID, 'workbench');
filename = fullfile(workbench_fodler, sprintf('%s.L.midthickness.8k_fs_LR.surf.gii', subjectID));
sourcemodel = ft_read_headshape({filename strrep(filename, '.L.', '.R.')});
sourcemodel = ft_determine_units(sourcemodel);
sourcemodel.coordsys = 'acpc';

close all
mkdir(fullfile(pwd,'output', 'sourcemodel'));
sourcemodel_folder = fullfile(pwd,'output', 'sourcemodel', subjectID);
save(sourcemodel_folder, 'sourcemodel');