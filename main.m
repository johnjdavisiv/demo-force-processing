
%Demo data processing from Bertec force treadmill + QTM to OpenSim
%John Davis
%john@johnjdavis.io
%2022-08-12


%Set up params and get files
subject_path = './Data/S999';

addpath('./force data processing');
addpath('./file io');

%Force processing parameters
fp_fs = 2400; % Sample frequency of force plate data (Hz)
force_step_lp_cutoff = 50; %Cutoff frequency for lowpass filter used to detect steps (Hz)
force_data_lp_cutoff = 18; %Cutoff frequency for lowpass filter used before CoP calculations (Hz)
f_threshold = 30; %Cutoff force value - below this number, GRF is considered to be zero (N)

%Demo on one trial from one subject
this_f1_tsv = [subject_path,'/QTM/Exports/', 'JDX_S999_run_0021_f_1.tsv'];
this_motion_tsv = strrep(this_f1_tsv, '_f_1.tsv', '.tsv');


%% Raw TSV to intermediary data

process_one_trial(subject_path, this_motion_tsv, this_f1_tsv);

%% Detrend force data

this_sto = [subject_path, '/Unprocessed TRC and MOT/JDX_S999_run_0021.sto'];

correct_force_drift_one_trial(this_sto, fp_fs);
%Pops up a plot of the drift on each plate


%% Filter and assign running forces
%Also combines plates to one global plate

undrift_sto = strrep(this_sto, '.sto', '_undrift.sto');

filter_and_assign_run_forces(undrift_sto, fp_fs, ...
        force_step_lp_cutoff,force_data_lp_cutoff, f_threshold);

disp('Results are in /Data/S999/Unprocessed TRC and MOT folder/');



