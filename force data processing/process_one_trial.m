function process_one_trial(subject_path, motion_tsv_path, f1_tsv_path)
%For debugging:
%subject_path
%motion_tsv_path = this_motion_tsv;
%f1_tsv_path = this_f1_tsv;

disp('Processing...');

%We programmatically find f2 path.

%What subject?
subject = strsplit(subject_path, '/');
subject = strrep(subject{end}, 'v2', '');

tsv_name = strsplit(motion_tsv_path, '/');
trc_filename = strrep(tsv_name{end}, '.tsv', '.trc');
trial_name = strrep(trc_filename, '.trc', '');
output_path = [subject_path, '/Unprocessed TRC and MOT/'];

%% Force data - do not rotate, write directly to .sto

%Hmm must edit to transform coordinates
sto_savename = get_grf_from_tsv(subject_path, motion_tsv_path, f1_tsv_path);
sto_filename = strsplit(sto_savename, '/');
sto_filename = sto_filename{end};

disp('Wrote force data as a STO file!');

%% Read motion data directly from TSV

disp('Reading motion data...');

%Read tsv header - IT IS OKAY THAT THIS IS NOT ADAPTIVE. 
fid = fopen(motion_tsv_path);
Q_header = cell(12,1);  
f_line = 1;

while f_line < 13
    Q_header{f_line} = fgetl(fid);
    f_line = f_line+1;
end

fclose(fid);

%General header info
n_frames = textscan(Q_header{1}, '%s %d');
n_frames = n_frames{2};

n_markers = textscan(Q_header{3}, '%s %d');
n_markers = n_markers{2};

fs = textscan(Q_header{4}, '%s %d');
fs = fs{2};

%Get timestamp
%Timestamp is datetime, followed by *computeR* time which is not the same as camera time!
time_cell = textscan(Q_header{8}, '%s %s %s %s');
date_stamp = strip(time_cell{2}{1}, ',');
clock_stamp = time_cell{3}{1};
time_stamp = datetime([date_stamp, ' ', clock_stamp], 'InputFormat', 'yyyy-MM-dd HH:mm:s.SSS');
time_stamp.Format = 'yyyy-MM-dd HH:mm:s.SSS';
time_stamp.TimeZone = 'America/New_York'; %Will be true at ECU and here. 
%Setting the time zone is important for getting posix right!


%Get markers and columns
marker_names = textscan(Q_header{10}, '%s');
marker_names = marker_names{1}(2:end);

%Read the data
qtm_motion = parse_qtm_tsv(motion_tsv_path);
disp('*** That warning is expected, nothing is wrong...***');

%Separate the CameraTime field?
if ~any(contains(qtm_motion.Properties.VariableNames, 'CameraTime'))
    error('Camera time field not found!');
end

%Extract
camera_frame = qtm_motion.Frame;
camera_time = qtm_motion.CameraTime;
trial_time = qtm_motion.Time;

%% Save camera time and metadata

disp('Saving camera time and metadata...');

camera_T = table(camera_frame, camera_time, trial_time);
camera_filename = [output_path, trial_name, '_cameratime.csv'];
writetable(camera_T, camera_filename);
time_stamp_posix = posixtime(time_stamp); %Life is easier with posixtime

%Update log file with timestamps
metadata_filename = ['JDX_', subject, '_inlab_metadata.csv'];
metadata_filepath = [output_path, metadata_filename];
fid = fopen(metadata_filepath, 'a'); %a for append, not overwrite
%Fields are subject	 trc_file	 mot_file	 trial_start_timestamp
fprintf(fid, '%s, %s, %s, %.6f\n',...
    subject, trc_filename, sto_filename, time_stamp_posix); 
fclose(fid);

%% Flip coordinate system

if length(marker_names)*3+3 ~= size(qtm_motion,2)
    error('Marker names do not match number of columns!');
end  
  
%Same function as in FJC trial
qtm_motion = rotate_qtm_data(qtm_motion,marker_names);

  
%% Save the manually generated trc file

save_trc(trc_filename, output_path, qtm_motion, n_frames, n_markers, fs, marker_names);


