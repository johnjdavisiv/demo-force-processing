function [fx_d, fy_d, fz_d, mx_d, my_d, mz_d] = force_undrift(tf,fx,fy,fz,mx,my,mz,...
    fp_fs, lp_cutoff_drift, rollmean_n, window_size, window_step_size, plot_title)

%Leverage the fact that Fz can only be zero or positive (in theory). Not true for other force/moment
%components! 

% Parameters
% tf - time of force, in camera time (seconds)
% fx,fy,fz,mx,my,mz - force plate data *in QTM/Bertec coordinates* - NOT osim coordinates.
% fs - sampling frequency. 2400 Hz at ECU.
% lp_cutoff -  cutoff frequency for lowpass filter for drift correction. Recommend 25 Hz or so.
% rollmean_n - number of samples for rolling mean to use when seeking minimum. REcommend 5 to 11
%

%Window size should be long enough so that there is at least once flight phase during the window.
%COnsider grounded running as a test case, or walking w/ both feet.


%debug
% % tf = sto_data(:,1);
% fx = fx1;
% fy = fy1;
% fz = fz1;
% mx = mx1;
% my = my1;
% mz = mz1;
% fx1 = sto_data(:, matches(sto_cols, 'ground_force_1_fx'));
% fy1 = sto_data(:, matches(sto_cols, 'ground_force_1_fy'));
% fz1 = sto_data(:, matches(sto_cols, 'ground_force_1_fz'));
% mx1 = sto_data(:, matches(sto_cols, 'ground_force_1_mx'));
% my1 = sto_data(:, matches(sto_cols, 'ground_force_1_my'));
% mz1 = sto_data(:, matches(sto_cols, 'ground_force_1_mz'));

% fx2 = sto_data(:, matches(sto_cols, 'ground_force_2_fx'));
% fy2 = sto_data(:, matches(sto_cols, 'ground_force_2_fy'));
% fz2 = sto_data(:, matches(sto_cols, 'ground_force_2_fz'));
% mx2 = sto_data(:, matches(sto_cols, 'ground_force_2_mx'));
% my2 = sto_data(:, matches(sto_cols, 'ground_force_2_my'));
% mz2 = sto_data(:, matches(sto_cols, 'ground_force_2_mz'));


%Filter force and moment components to get a smooth version for finding baseline
filter_order = 1; %second-order filter after zero-lag filtering
norm_cutoff_freq_step = lp_cutoff_drift/(fp_fs/2); %set normalized cutoff frequency
[bee,ayy] = butter(filter_order,norm_cutoff_freq_step, 'low');  
fx_filt = filtfilt(bee, ayy, fx);
fy_filt = filtfilt(bee, ayy, fy);
fz_filt = filtfilt(bee, ayy, fz);
mx_filt = filtfilt(bee, ayy, mx);
my_filt = filtfilt(bee, ayy, my);
mz_filt = filtfilt(bee, ayy, mz);

%Want to do same for fx fy  mx my mz -- filter lowpass, then rollmean
%BUT use the Fz indices! for the rollmean at that point (form the fz indices)
%Rollmean to remove minor remaining fluctuations
fx_rollmean = movmean(fx_filt,rollmean_n);
fy_rollmean = movmean(fy_filt,rollmean_n);
fz_rollmean = movmean(fz_filt,rollmean_n);
mx_rollmean = movmean(mx_filt,rollmean_n);
my_rollmean = movmean(my_filt,rollmean_n);
mz_rollmean = movmean(mz_filt,rollmean_n);

%Leave, will use for figures in appendix
% hold on;
% plot(fz, 'color', [0.5 0 0 0.8]);
% plot(fz_filt, 'color', [0 0 0.5 0.5], 'linewidth', 1);
% plot(fz_rollmean, 'color', [0 0.9 0 0.5], 'linewidth', 1);

% hold on;
% plot(fy, 'color', [0.5 0 0 0.8]);
% plot(fy_filt, 'color', [0 0 0.5 0.5], 'linewidth', 2);
% plot(fz_filt, 'color', [0 0 0 0.5], 'linewidth', 2);

% hold on;
% plot(fx, 'color', [0.5 0 0 0.8]);
% plot(fx_filt, 'color', [0 0 0.5 0.5], 'linewidth', 2);
% plot(fz_filt, 'color', [0 0 0 0.5], 'linewidth', 2);


%% Looping

%Carefully set up correct window indices
start_ind = 1:(fp_fs*window_step_size):(length(fz)-fp_fs*window_size+1);
end_ind = start_ind + fp_fs*window_size - 1;
n_windows = length(start_ind);

if n_windows == 0
    %If less than one window
    %error('Data too short!');
    start_ind = 1;
    end_ind = length(tf);
    n_windows = 1;
end

%Preallocate for speed
t_drift = nan(n_windows, 1);
fx_drift = nan(n_windows, 1);
fy_drift = nan(n_windows, 1);
fz_drift = nan(n_windows, 1);
mx_drift = nan(n_windows, 1);
my_drift = nan(n_windows, 1);
mz_drift = nan(n_windows, 1);

large_drift_flag = 0;


%Loop through windows, sliding along as we go...
for n=1:n_windows
    %Get this window
    this_t = tf(start_ind(n):end_ind(n));
    
    this_fx_roll = fx_rollmean(start_ind(n):end_ind(n));
    this_fy_roll = fy_rollmean(start_ind(n):end_ind(n));
    this_fz_roll = fz_rollmean(start_ind(n):end_ind(n));
    
    this_mx_roll = mx_rollmean(start_ind(n):end_ind(n));
    this_my_roll = my_rollmean(start_ind(n):end_ind(n));
    this_mz_roll = mz_rollmean(start_ind(n):end_ind(n));
    
    %Find min of smoothed GRFz
    [min_fz, ix_min_fz] = min(this_fz_roll);
    t_min_fz = this_t(ix_min_fz);
    
    %Quick sanity chieck
    if abs(min_fz) > 100
        large_drift_flag = 1;
    end
    
    %Drift correct for fx fy fz mx my mz using fz timepoints (since we know GRF is ~~zero here
    t_drift(n) = t_min_fz;
    %Notice how we use the index of minimum of *fz*, even for fx,fy, mx, ... 
    fx_drift(n) = this_fx_roll(ix_min_fz);
    fy_drift(n) = this_fy_roll(ix_min_fz);
    fz_drift(n) = min_fz;
    mx_drift(n) = this_mx_roll(ix_min_fz);
    my_drift(n) = this_my_roll(ix_min_fz);
    mz_drift(n) = this_mz_roll(ix_min_fz);
end

if large_drift_flag
    warning('minimum force magnitude greater than 100 N! Is this right?');
end

%Deal with edge effects
%Get distortion early and late bc rollmean so use second window as first window
if n_windows > 1
    fx_drift(1) = fx_drift(2);
    fy_drift(1) = fy_drift(2);
    fz_drift(1) = fz_drift(2);
    mx_drift(1) = mx_drift(2);
    my_drift(1) = my_drift(2);
    mz_drift(1) = mz_drift(2);

    fx_drift(end) = fx_drift(end-1);
    fy_drift(end) = fy_drift(end-1);
    fz_drift(end) = fz_drift(end-1);
    mx_drift(end) = mx_drift(end-1);
    my_drift(end) = my_drift(end-1);
    mz_drift(end) = mz_drift(end-1);
end

%Want our datapoints to range the full range of data
%So use constant extrapolation
if t_drift(1) ~= tf(1)
    t_drift = [tf(1); t_drift];
    fx_drift = [fx_drift(1); fx_drift];
    fy_drift = [fy_drift(1); fy_drift];
    fz_drift = [fz_drift(1); fz_drift];
    mx_drift = [mx_drift(1); mx_drift];
    my_drift = [my_drift(1); my_drift];
    mz_drift = [mz_drift(1); mz_drift];
end

if t_drift(end) ~= tf(end)
    t_drift = [t_drift; tf(end)];
    fx_drift = [fx_drift; fx_drift(end)];
    fy_drift = [fy_drift; fy_drift(end)];
    fz_drift = [fz_drift; fz_drift(end)];
    mx_drift = [mx_drift; mx_drift(end)];
    my_drift = [my_drift; my_drift(end)];
    mz_drift = [mz_drift; mz_drift(end)];
end

%Detrend with a 2nd degree polynomial and subtract out
%(this essentially imposes a strong smoothness prior on drift)

%Edge cases for very short recordings
if n_windows == 1
    poly_degree = 0;
elseif n_windows == 2
    poly_degree = 1;
else
    poly_degree = 2;
end

fx_detrend_fit = polyfit(t_drift,fx_drift,poly_degree);
fx_d = fx - polyval(fx_detrend_fit, tf);

fy_detrend_fit = polyfit(t_drift,fy_drift,poly_degree);
fy_d = fy - polyval(fy_detrend_fit, tf);

fz_detrend_fit = polyfit(t_drift,fz_drift,poly_degree);
fz_d = fz - polyval(fz_detrend_fit, tf);

mx_detrend_fit = polyfit(t_drift,mx_drift,poly_degree);
mx_d = mx - polyval(mx_detrend_fit, tf);

my_detrend_fit = polyfit(t_drift,my_drift,poly_degree);
my_d = my - polyval(my_detrend_fit, tf);

mz_detrend_fit = polyfit(t_drift,mz_drift,poly_degree);
mz_d = mz - polyval(mz_detrend_fit, tf);


%% Plot all in subplot

figure();

ax1 = subplot(3,2,1);
hold on;
plot(fx, 'color', [0.6 0 0 0.5], 'linewidth', 1);
plot(fx_d, 'color', [0 0 0.5 0.9], 'linewidth', 1);
title('Fx');

ax2 = subplot(3,2,2);
hold on;
plot(fy, 'color', [0.6 0 0 0.5], 'linewidth', 1);
plot(fy_d, 'color', [0 0 0.5 0.9], 'linewidth', 1);
title('Fy');

ax3 = subplot(3,2,3);
hold on;
plot(fz, 'color', [0.6 0 0 0.5], 'linewidth', 1);
plot(fz_d, 'color', [0 0 0.5 0.9], 'linewidth', 1);
title('Fz');

ax4 = subplot(3,2,4);
hold on;
plot(mx, 'color', [0.6 0 0 0.5], 'linewidth', 1);
plot(mx_d, 'color', [0 0 0.5 0.9], 'linewidth', 1);
title('Mx');

ax5 = subplot(3,2,5);
hold on;
plot(my, 'color', [0.6 0 0 0.5], 'linewidth', 1);
plot(my_d, 'color', [0 0 0.5 0.9], 'linewidth', 1);
title('My');

ax6 = subplot(3,2,6);
hold on;
plot(mz, 'color', [0.6 0 0 0.5], 'linewidth', 1);
plot(mz_d, 'color', [0 0 0.5 0.9], 'linewidth', 1);
title('Mz');

linkaxes([ax1,ax2,ax3,ax4,ax5,ax6]);
sgtitle([plot_title, '  ||   Red = original, Blue = corrected'], 'interpreter', 'none');

end

