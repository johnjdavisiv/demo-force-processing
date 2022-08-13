function correct_force_drift_one_trial(this_sto, fp_fs)
% Correct drift in walk, run, jump trials and save as an "undrifted" file

%Sorta an adaptation of Alcantara et al. "Dryft" algorithm, with some tweaks and simplifications

%Setup params
%fs = 2400;
lp_cutoff_drift = 25; %Recommend 25 Hz
rollmean_n = 11; %Recommend 11-21 samples
window_size = 5; %sec
window_step_size = 1; %sec

%% Loop through all grf files
%The Heisenbug is here, somewhere...

[sto_data, sto_header] = read_mot(this_sto);
sto_cols = strip(strsplit(sto_header{end}, '\t'));

%Get each force component
tf = sto_data(:,1);
fx1 = sto_data(:, matches(sto_cols, 'ground_force_1_fx'));
fy1 = sto_data(:, matches(sto_cols, 'ground_force_1_fy'));
fz1 = sto_data(:, matches(sto_cols, 'ground_force_1_fz'));
mx1 = sto_data(:, matches(sto_cols, 'ground_force_1_mx'));
my1 = sto_data(:, matches(sto_cols, 'ground_force_1_my'));
mz1 = sto_data(:, matches(sto_cols, 'ground_force_1_mz'));

title_string = ['Demo data', ' - FP1'];

[fx1_d, fy1_d, fz1_d, mx1_d, my1_d, mz1_d] = force_undrift(tf, fx1, fy1, fz1, mx1, my1, mz1,...
    fp_fs, lp_cutoff_drift, rollmean_n, window_size, window_step_size, title_string);

%Drop in detrended data
sto_data(:, matches(sto_cols, 'ground_force_1_fx')) = fx1_d;
sto_data(:, matches(sto_cols, 'ground_force_1_fy')) = fy1_d;
sto_data(:, matches(sto_cols, 'ground_force_1_fz')) = fz1_d;
sto_data(:, matches(sto_cols, 'ground_force_1_mx')) = mx1_d;
sto_data(:, matches(sto_cols, 'ground_force_1_my')) = my1_d;
sto_data(:, matches(sto_cols, 'ground_force_1_mz')) = mz1_d;

%Samesies for FP2
fx2 = sto_data(:, matches(sto_cols, 'ground_force_2_fx'));
fy2 = sto_data(:, matches(sto_cols, 'ground_force_2_fy'));
fz2 = sto_data(:, matches(sto_cols, 'ground_force_2_fz'));
mx2 = sto_data(:, matches(sto_cols, 'ground_force_2_mx'));
my2 = sto_data(:, matches(sto_cols, 'ground_force_2_my'));
mz2 = sto_data(:, matches(sto_cols, 'ground_force_2_mz'));

title_string = ['Demo data', ' - FP2'];

[fx2_d, fy2_d, fz2_d, mx2_d, my2_d, mz2_d] = force_undrift(tf, fx2, fy2, fz2, mx2, my2, mz2,...
    fp_fs, lp_cutoff_drift, rollmean_n, window_size, window_step_size, title_string);

%Drop in detrended data
sto_data(:, matches(sto_cols, 'ground_force_2_fx')) = fx2_d;
sto_data(:, matches(sto_cols, 'ground_force_2_fy')) = fy2_d;
sto_data(:, matches(sto_cols, 'ground_force_2_fz')) = fz2_d;
sto_data(:, matches(sto_cols, 'ground_force_2_mx')) = mx2_d;
sto_data(:, matches(sto_cols, 'ground_force_2_my')) = my2_d;
sto_data(:, matches(sto_cols, 'ground_force_2_mz')) = mz2_d;

save_name = strrep(this_sto, '.sto', '_undrift.sto');

%Save *not* in-situ for demo
write_mot(sto_header, sto_data, save_name);


disp('Force data detrended!');
    
