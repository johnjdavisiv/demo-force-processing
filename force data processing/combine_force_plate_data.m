function [tf,fx,fy,fz,mx,my,mz] = combine_force_plate_data(this_sto)

%I just need to do this for running trials I think?
%run_sto = dir([subject_path,'\Processed TRC and MOT\Run\*.sto']);
%Use run trial 3! Has some nice crossover gait
%this_sto = fullfile(run_sto(3).folder, run_sto(3).name);

[sto_data, sto_header] = read_mot(this_sto);
sto_cols = strip(strsplit(sto_header{end}, '\t'));

% Get all the force components of each plate
tf = sto_data(:,1);

fx1 = sto_data(:, matches(sto_cols, 'ground_force_1_fx'));
fy1 = sto_data(:, matches(sto_cols, 'ground_force_1_fy'));
fz1 = sto_data(:, matches(sto_cols, 'ground_force_1_fz'));
mx1 = sto_data(:, matches(sto_cols, 'ground_force_1_mx'));
my1 = sto_data(:, matches(sto_cols, 'ground_force_1_my'));
mz1 = sto_data(:, matches(sto_cols, 'ground_force_1_mz'));

fx2 = sto_data(:, matches(sto_cols, 'ground_force_2_fx'));
fy2 = sto_data(:, matches(sto_cols, 'ground_force_2_fy'));
fz2 = sto_data(:, matches(sto_cols, 'ground_force_2_fz'));
mx2 = sto_data(:, matches(sto_cols, 'ground_force_2_mx'));
my2 = sto_data(:, matches(sto_cols, 'ground_force_2_my'));
mz2 = sto_data(:, matches(sto_cols, 'ground_force_2_mz'));

%Forces just sum together
fx = fx1 + fx2;
fy = fy1 + fy2;
fz = fz1 + fz2;
%Moments...are trickier.

%r2 is the vector from origin of FP1 (0 0 0) to origin of FP2 (which is +974mm in X direction)
%This works, can also hardcode as 974.7249 mm
plate_params = strsplit(sto_header{1}, ',');
r2 = (str2double(plate_params(5:7)) - str2double(plate_params(2:4)))/1000; %to meters
%To use cross(A,B) what happens is ai x bi but A and B must be n-by-3 matrices
%So use repmat() to manually broadcast

%Following Ton van den Bogert here: 
%https://biomch-l.isbweb.org/forum/biomch-l-forums/general-discussion/44299-summing-free-moments-from-two-force-plates-on-a-cross-strike
R2 = repmat(r2, size(fx,1),1);
F2 = [fx2, fy2, fz2];
M1 = [mx1, my1, mz1];
M2 = [mx2, my2, mz2];
Mtotal = M1 + M2 + cross(R2, F2);
%M total is [mx my mz]
mx = Mtotal(:,1);
my = Mtotal(:,2);
mz = Mtotal(:,3);

%Hmm so if this function "collapses" fp data to one set of fxyz mxyz maybe we can use it for each
%sto file separately, then jsut...hmmm. Do the force/foot assignment and not mess with column names?
%Maybe we take as input this_sto and send back as output fx fy fz mx my mz

