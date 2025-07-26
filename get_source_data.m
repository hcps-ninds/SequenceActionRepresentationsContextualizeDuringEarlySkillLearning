function source = get_source_data(SubjectID)

% Load Fieldtrip
addpath('/path/to/fieldtrip')
ft_defaults

addpath('/path/to/MEG Data')

Files = dir('*.ds');

cd Rest % path to MEG data conrtaining baseline
%cd EmptyRoom
Files_rest = dir('*.ds');
cd ..

for i= 1:length(Files)
if SubjectID == Files(i).name(1:8) % data folder key
sub=i;
end
end

% For trial level spatial filtering 
% cfg                         = [];
% cfg.dataset                 = Files(sub).name;
% cfg.trialdef.eventtype      = 'UPPT001';
% cfg.trialdef.prestim        = 0;        
% cfg.trialdef.poststim       = 10;        
% cfg.continuous              = 'yes';
% cfg = ft_definetrial(cfg);

% if post filtering
cfg = [];
% cfg.bpfilter = 'yes';
% cfg.bpfreq = [1 100];
% cfg.bpfiltord = 2;
% cfg.hilbert = 'no';
% cfg.demean = 'yes';
% cfg.dftfilter = 'yes';
% cfg.dftfreq =60;

cfg.dataset = Files(sub).name;
meg_data = ft_preprocessing(cfg);

cd Rest
%cd EmptyRoom
cfg = [];
% cfg.bpfilter = 'yes';
% cfg.bpfreq = [1 100];
% cfg.bpfiltord = 2;
% cfg.hilbert = 'no';
% cfg.demean = 'yes';
% cfg.dftfilter = 'yes';
% cfg.dftfreq =60;
cfg.dataset = Files_rest(sub).name;
meg_rest = ft_preprocessing(cfg);
% cfg.resamplefs =600;
% meg_rest = ft_resampledata(cfg, meg_rest);

cd ..

% Select MEG channels only
cfg         = [];
cfg.channel = {'MEG'};
meg_data = ft_selectdata(cfg, meg_data);
load(['/path/to/preprocessed/sensor_task_data/' SubjectID '.mat'])
meg_data.trial{1,1} = sensor_data;
meg_rest = ft_selectdata(cfg, meg_rest);
load(['/path/to/preprocessed/sensor_rest_data/' SubjectID '.mat'])
meg_rest.trial{1,1} = sensor_data_R1;


% Noise Covariance
cfg = []; 
cfg.latency = [0 360];
meg_rest = ft_selectdata(cfg, meg_rest);

cfg = [];
cfg.covariance = 'yes';
meg_rest = ft_timelockanalysis(cfg, meg_rest);

% Spatial whitening of the task data, using the activity from the baseline
% [u,s,v] = svd(meg_rest.cov);
% figure;plot(log10(diag(s)),'o');
% 
% d = -diff(log10(diag(s)));
% d = d./std(d);
% kappa = length(find(d>4));

cfg = [];
%cfg.kappa = kappa;
cfg.channel = {'MEG'};

if isfield(meg_data, 'elec')
    meg_data = rmfield(meg_data, 'elec');
end
% meg_data = ft_denoise_prewhiten(cfg, meg_data, meg_rest);

% cfg = [];
% cfg.preproc.demean = 'yes';
% cfg.preproc.baselinewindow = [-0.2 0];
% cfg.covariance = 'yes';
% meg_data = ft_timelockanalysis(cfg, meg_data);

% Computation of the covariance matrix of the prewhitened data

grad = ft_convert_units(meg_data.grad, 'mm');

cd /path/to/saved models

load(['output/sourcemodel/' SubjectID '.mat']);
load(['output/headmodel/' SubjectID '.mat']);
load(['output/transfer_matrix/' SubjectID '.mat']);

headmodel   = ft_convert_units(headmodel,   'mm');
sourcemodel = ft_convert_units(sourcemodel, 'mm');
sourcemodel.inside = sourcemodel.atlasroi>0;

for i_grad = 1:size(grad.chanpos, 1)
    grad.chanpos(i_grad, :) = ft_warp_apply(ctf2acpc, grad.chanpos(i_grad, :));
end

% Prepare leadfield
cfg = [];
cfg.channel = meg_data.label;
cfg.grad = grad;
%cfg.channel = 'meggrad'; 
cfg.sourcemodel = sourcemodel;
cfg.headmodel = headmodel;
cfg.method = 'singleshell';
cfg.singleshell.batchsize = 1000;
leadfield_meg = ft_prepare_leadfield(cfg);

% Prepare MEG covariance
meg_epochs = [];
meg_epochs.time = meg_data.time;
meg_epochs.label = meg_data.label;
meg_epochs.grad = grad;
meg_epochs.trial = meg_data.trial;
meg_epochs.trialinfo = meg_data.label;


cfg = [];
cfg.preproc.demean = 'yes';
cfg.covariance = 'yes';
meg_cov = ft_timelockanalysis(cfg, meg_epochs);

avg = meg_cov;
avg.cov = (meg_rest.cov + meg_cov.cov)/2;

% Source analysis

% [u,s,v] = svd(meg_cov.cov);
% d       = -diff(log10(diag(s)));
% d       = d./std(d);
% kappa   = find(d>5,1,'first');

cfg                 = [];
cfg.method          = 'lcmv';
%cfg.lcmv.kappa      = kappa;
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.fixedori   = 'yes';
%cfg.lcmv.weightnorm = 'unitnoisegain';
cfg.headmodel   = headmodel;
cfg.sourcemodel = leadfield_meg;
sourceavg = ft_sourceanalysis(cfg, avg);

cfg.sourcemodel.filter  = sourceavg.avg.filter; %uses the grid from the whole trial average
source  = ft_sourceanalysis(cfg, meg_cov); 

mkdir(fullfile(pwd, 'output', 'source'))
save(fullfile(pwd, 'output', 'source', SubjectID), 'source');


end

