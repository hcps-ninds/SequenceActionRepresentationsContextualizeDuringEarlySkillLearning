%% Preprocess MEG data

% Extract MEG data
addpath('/path/to/fieldtrip'); % addpath to fieldtrip
ft_defaults

cfg=[];
cfg.dataset = 'name_of_the_folder.ds'; % name of data folder
raw = ft_preprocessing(cfg);

% perform ICA
cfg        = [];
cfg.channel      = {'MEG'};
data_orig        = ft_selectdata(cfg, raw);
cfg.method = 'runica'; % this is the default and uses the implementation from EEGLAB

comp = ft_componentanalysis(cfg, data_orig);


%view components
cfg          = [];
cfg.channel  = 1:20 ; % components to be plotted
cfg.viewmode = 'component';
cfg.layout   = 'CTF275.lay'; % specify the layout file that should be used for plotting
ft_databrowser(cfg, comp)

% the original data can now be reconstructed, excluding those components
cfg           = [];
cfg.component = [38 42 49 51 69 ] ; % example component numbers selected based on visual information
data_clean    = ft_rejectcomponent(cfg, comp, data_orig);

% Data details
fs = raw.fsample;

% Bandpass
Fbp = [1 100]; % bandpass cutoff example
data_f = ft_preproc_bandpassfilter(data_clean.trial{1,1}, fs, Fbp);

clear Fbp grad_ind

% Notch
fn = 60;
data_fn = ft_preproc_dftfilter(data_f, fs, fn); % Preprocessed data

clear data_f fn 
