function filter_and_assign_run_forces(sto_file, fp_fs, force_step_lp_cutoff, ...
    force_data_lp_cutoff, f_threshold)

%This function does the following:

%0) Combines data from FP1 and FP2 to a single plate
%1) Detect steps using conservatively filtered force data (~50 Hz?) and f_threshold
%2) Filter original data at more aggressive cutoff (~20 hz, same as IK filtering)
%3) Compute COP from global coordinate forces and moments
%4) Format forces in OpenSim manner (flip coordinate system)
%5) Using indices from fp_step filter, assign each step to a foot via the virtual force plate
%technique
%6) Save results to a .mot file

%Debug
%sto_file = this_sto;

%Combine force data to create one plate (Run only!)
[tf,fx,fy,fz,mx,my,mz] = combine_force_plate_data(sto_file);
%Data I want to filter
fp_data = [fx, fy, fz, mx, my, mz]; %NOT time

%Sto data - need header for z offset
[~, sto_header] = read_mot(sto_file);
z_cell = strsplit(sto_header{1}, ',');
z_offset = str2double(z_cell{4})/1000; %Get in meters

%Get corresponding trc data for this sto file
this_trc = strrep(sto_file, '_undrift.sto', '.trc');
[trc_data, trc_header] = read_trc(this_trc);
trc_cols = get_trc_columns(trc_data,trc_header);

%Heel markers for assigning footstrikes (in order of priority)
R_heel_markers = {'R_heel_B', 'R_heel_LA', 'R_heel_T', 'R_latfoot'};
L_heel_markers = {'L_heel_B', 'L_heel_LA', 'L_heel_T', 'L_latfoot'};

%% Filtering

filter_order = 1; %second-order filter after zero-lag filtering
%Helps avoid overshoot (just set cutoff higher)

%Get step detection forces from fz
norm_cutoff_freq_step = force_step_lp_cutoff/(fp_fs/2); %set normalized cutoff frequency
[bee_step,ayy_step] = butter(filter_order,norm_cutoff_freq_step);  
f_v_fstep = filtfilt(bee_step, ayy_step, fz);

%Filter actual force plate data
norm_cutoff_freq_data = force_data_lp_cutoff/(fp_fs/2); 
[bee_data,ayy_data] = butter(filter_order,norm_cutoff_freq_data);  
fp_f_data = filtfilt(bee_data, ayy_data, fp_data);


%% Translating to CoP + Tz and OpenSim coordinate system
% Note: Ton vdB says this is not ideal, better to use raw forces/moments and not calculate COP at
% all. I still want to use COP for now to make sure the data are correct by visualizing! 
Fx = fp_f_data(:,1);
Fy = fp_f_data(:,2);
Fz = fp_f_data(:,3);
Mx = fp_f_data(:,4);
My = fp_f_data(:,5);
Mz = fp_f_data(:,6);

%COP calcs - following Kwon3D. Notice use of filtered signals! 
%See http://www.kwon3d.com/theory/grf/pad.html
xp = (z_offset*Fx - My)./Fz;
yp = (z_offset*Fy + Mx)./Fz;
Tz = Mz - xp.*Fy + yp.*Fx;

%Now the big flip...
%osim x is QTM y
%osim y is QTM z
%osim z is QTM x
osim_vx = Fy;
osim_vy = Fz;
osim_vz = Fx;
osim_px = yp;
osim_py = zeros(size(xp)); %COP is on floor
osim_pz = xp;
osim_mx = zeros(size(xp)); %only vertical moments are possible about COP
osim_my = Tz; %Free moment
osim_mz = zeros(size(yp)); %only vertical moments are possible about COP

%Set any negative vertical forces to zero (Important!!!)
osim_vy(osim_vy < 0) = 0;

%The nine colums of osim-formatted forces are: 
osim_fp_f = [osim_vx, osim_vy, osim_vz, ...
    osim_px, osim_py, osim_pz, ...
    osim_mx, osim_my, osim_mz];

%% Next up is force assignment to feet

min_frames = 0.005*fp_fs; %just to cut out fluctuations
%Would be 12 frames of 2400 hz data, i.e. 0.005 seconds
%Find steps in 50 Hz filtered data
step_ind = f_v_fstep > f_threshold;
[n_steps, step_start_ind, step_end_ind, step_length] = get_bouts(step_ind, min_frames);
%Step length may be useful for some error checking later, so leave it in place
% 
% 
% hold on;
% plot(f_v_fstep)
% area(step_ind*f_threshold);
% plot([0 4.5*10e3], [50, 50], 'k-');

%Left or right? 
all_steps = cell(n_steps,1);
all_steps(:) = {''};


for a=1:n_steps
    step_start = step_start_ind(a);
    step_end = step_end_ind(a);
    %Get midpoint of this step
    step_mid = round(mean([step_start, step_end]));
    
    %What timepoint corresopnds to midpoint of this step?
    t_mid = tf(step_mid); 
    %what marker index corresponds to midstance?
    [~, marker_mid_ix] = min(abs(trc_data(:,2) - t_mid));
    
    %Which foot was on the ground?
    foot = which_foot(trc_data, trc_cols, marker_mid_ix, R_heel_markers, L_heel_markers);
    all_steps{a} = foot;
end


%Deal with the weird edge cases: starting/ending with a half-step
if step_start_ind(1) == 1
    %Just have first step be opposite of second step
    if matches(all_steps{2}, 'R')
        all_steps{1} = 'L';
    else
        all_steps{1} = 'R';
    end
end
if step_end_ind(end) == length(tf)
    %Same as above, just use second-to-last step instead
    if matches(all_steps{end-1}, 'R')
        all_steps{end} = 'L';
    else
        all_steps{end} = 'R';
    end
end


%Quick check for doouble steps (i.e. R step then R step, or L and L
if any(abs(diff(matches(all_steps, 'R'))) == 0)
    fprintf('Double step detected on file %s\n', sto_file)
    warning('DOUBLE STEP DETECTED! Investigate further!');
end

%% Create the virtual force plate

%Forces must be applied to the corresponding segment (left or right foot), and the best way to do
%this is split the GRF into two "virtual" force plates on top of each other.

R_steps = matches(all_steps, 'R');
L_steps = matches(all_steps, 'L');

%Remember, these indices are for the force data...
n_steps_R = sum(R_steps);
step_start_ind_R = step_start_ind(R_steps);
step_end_ind_R = step_end_ind(R_steps);

n_steps_L = sum(L_steps);
step_start_ind_L = step_start_ind(L_steps);
step_end_ind_L = step_end_ind(L_steps);

%Initialize the columns with zeros, then drop in the steps using step start/stop indices
R_mot_data = zeros(size(osim_fp_f));
L_mot_data = zeros(size(osim_fp_f));


%Drop in force data for each step!
for a=1:n_steps_R
    ix_start = step_start_ind_R(a);
    ix_end = step_end_ind_R(a);
    %Drop in the force data filtered with thte _data cutoff!
    R_mot_data(ix_start:ix_end,:) = osim_fp_f(ix_start:ix_end,:);
end

for a=1:n_steps_L
    ix_start = step_start_ind_L(a);
    ix_end = step_end_ind_L(a);
    %Drop in the force data filtered with thte _data cutoff!
    L_mot_data(ix_start:ix_end,:) = osim_fp_f(ix_start:ix_end,:);
end

%Preview
% ax1 = subplot(2,1,1);
% plot(R_mot_data)
% ax2 = subplot(2,1,2);
% plot(L_mot_data);
% linkaxes([ax1, ax2]);

%This is some real slick stuff
R_mot_data = interpolate_cop(R_mot_data, step_start_ind_R, step_end_ind_R, n_steps_R);
L_mot_data = interpolate_cop(L_mot_data, step_start_ind_L, step_end_ind_L, n_steps_L);


%% Recombine and save as a .mot file

new_save_path = strrep(sto_file, '.sto', '.mot');

%L comes first because ECU's FP1 is left one (helps for using same config
%for walking as well) so fp1 is assigned to left foot in all cases
virtual_mot_data = [tf, L_mot_data, R_mot_data];
%Heh if we had a reversible treadmill with incline this would not be so
%easy!

%This is a lil messy but there's no great alternative that is fast
mot_cols = {'time', 'ground_force_1_vx', 'ground_force_1_vy', 'ground_force_1_vz', ...
    'ground_force_1_px', 'ground_force_1_py', 'ground_force_1_pz', ...
    'ground_moment_1_mx', 'ground_moment_1_my',	'ground_moment_1_mz', ...
    'ground_force_2_vx', 'ground_force_2_vy', 'ground_force_2_vz', ...
    'ground_force_2_px', 'ground_force_2_py', 'ground_force_2_pz', ...
    'ground_moment_2_mx', 'ground_moment_2_my', 'ground_moment_2_mz'};

col_line = sprintf([strip(sprintf('%s\t', mot_cols{:})), '\n']);

%Mot needs specialized header
mot_header = {sprintf('nColumns=19\n'), ...
    sprintf('nRows=%i\n', size(virtual_mot_data,1)), ...
    sprintf('DataType=double\n'),...
    sprintf('version=3\n'),...
    sprintf('OpenSimVersion=4.2-2021-03-12-fcedec9\n'),...
    sprintf('endheader\n'), ...
    col_line}'; %Transpose is necessary!

write_mot(mot_header, virtual_mot_data, new_save_path);

disp('Done!');
