function sto_savename = get_grf_from_tsv(subject_path, motion_tsv_path, f1_tsv_path)

%Write a .sto file with the force data. Convert from global action
%coordinate system to global reaction coordinate system. 

%Still in IUBLM coordinates (Z up)

%Debug
%motion_tsv_path = this_motion_tsv;
%f1_tsv_path = this_f1_tsv;


%Get FP2 data
f2_tsv_path = strrep(f1_tsv_path, 'f_1.tsv', 'f_2.tsv');


%% For output

output_path = [subject_path, '/Unprocessed TRC and MOT/'];
trial_name = strsplit(motion_tsv_path, '/');
trial_name = strrep(trial_name{end}, '.tsv', '');


%% Read data

[fp1_data, ~, fp1_header] = read_qtm_force_tsv(f1_tsv_path);
[fp2_data, ~, fp2_header] = read_qtm_force_tsv(f2_tsv_path);

%FOrce corners and offset
[pxpy1, nxpy1, nxny1, pxny1, offset_vec1] = get_fp_corners(f1_tsv_path);
[pxpy2, nxpy2, nxny2, pxny2, offset_vec2] = get_fp_corners(f2_tsv_path);

if ~any(contains(fp1_header, 'world (lab)')) || ...
        ~any(contains(fp2_header, 'world (lab)'))
    error('Force data not in global coordinates! Re-export from QTM');
end

%% Z offsets

%FP1 origin is at pxny
fp1_origin_x = pxny1(1);
fp1_origin_y = pxny1(2);

fp2_origin_x = nxny2(1);
fp2_origin_y = nxny2(2);


h_offset_f1 = strsplit(fp1_header{24}, '\t');
h_offset_f1 = str2double(h_offset_f1{end});

h_offset_f2 = strsplit(fp2_header{24}, '\t');
h_offset_f2 = str2double(h_offset_f2{end});

%HARDCODING HERE FOR ECU
first_line_string = sprintf('FP1 origin-offset FP2 origin-offset (xyz),%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,mm', ...
    fp1_origin_x, fp1_origin_y, h_offset_f1,...
    fp2_origin_x, fp2_origin_y, h_offset_f2);

%% Write to sto
%Concat into one matrix
%time, ground_force_1_fx, fy, fz, mx, my, mz, ground_force_2_fx, ...
sto_cols = {'time',...
    'ground_force_1_fx','ground_force_1_fy','ground_force_1_fz', ...
    'ground_force_1_mx','ground_force_1_my','ground_force_1_mz',...
    'ground_force_2_fx','ground_force_2_fy','ground_force_2_fz', ...
    'ground_force_2_mx','ground_force_2_my','ground_force_2_mz'};
%          time         FP1: Fx Fy Fz Mx My Mz    FP2: Fx Fy Fz Mx My Mz
fp_data = [fp1_data(:,2), -1*fp1_data(:,3:8), -1*fp2_data(:,3:8)];
% The *-1 flips from global ACTION to global REACTION coordinates
% (the QTM export as "global" option already transforms from force plate
% local action CS to global action CS, which is why we don't perfectly
% replicate the Kwon3D transforms. If you exported as local coords, the
% flips do cancel out and you get Kwon's transforms. 

sto_savename = [output_path, trial_name, '.sto'];

write_sto(fp_data, sto_cols, ...
    sto_savename, ...
    first_line_string);

