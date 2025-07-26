
function [idx_new,kp,op] = get_behav_data(MEG_data,Behav_data)

addpath('/path/to/fieldtrip'); % addpath to fieldtrip
ft_defaults

addpath ('/path/to/BehaviorData')
addpath ('/path/to/MEGData')

%Import MEG data
hdr = ft_read_header(MEG_data); %Load MEG header info
d = ft_read_data(MEG_data); %Load MEG data
tMEG = (0:hdr.nSamples-1)'.*(1e3/hdr.Fs); %Create MEG time vector using sample length and sampling frequency
tTrialStartMEG = tMEG(find(diff(d(strcmp('UPPT001',hdr.label),:))==2)+1); %Find all rising edges in UPPT001 for trial start event codes
nTrialsMEG = length(tTrialStartMEG);

%Import Behavioral Data
load(Behav_data) %Load corresponding MAT file with behavioral data
tTrialStartBehav = trial.start;
nTrialsBehav = length(tTrialStartBehav);

%Initialize new output variable with MEG indices for keypress events
trial.MEGidx = cell(nTrialsMEG,1);
if nTrialsMEG == nTrialsBehav %Only proceed if trials numbers match
    for iTr = 1:nTrialsMEG
        localMEGoffset = tTrialStartBehav(iTr) - tTrialStartMEG(iTr);
        tKP_MEG = trial.experTime{iTr} - localMEGoffset;
        [~,jKP] = min(abs(tKP_MEG-tMEG),[],1);
        trial.MEGidx{iTr} = jKP(:)';
    end
else
    warning('Trial numbers for MEG and behavioral datasets do not match.');
end

%Extract Finger labels
idx = trial.MEGidx;
cKP = trial.isCorrSeqMem;
kp = trial.seq;
op = trial.ordPos';

%Remove all error key presses and repalce with NaN
idx_new = idx;
for t = 1:length(idx)
    e = find(cKP{t,1}==0);
        if length(e)~=0
           idx_new{t,1}(1,e) = NaN;
        end
end




