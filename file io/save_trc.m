function save_trc(save_name, save_path, qtm_data, n_frames, n_markers, fs, marker_names)
%Quick saving for QTM data as OpenSim compatible trc file

%This is NOT the same function as write_trc()!

%Debug/testing
%save_name = 'test.trc';
%save_path = './';
%qtm_data = static_data;
%n_frames = static_n_frames;
%n_markers = static_n_markers;
%fs = static_fs;
%marker_names = static_marker_names;
%qtm_data = static_data;
%trc_fname = [strrep(save_name, '.tsv', ''), '_processed.trc'];

%Ensure we have backslash correct (add in strcat)
if strcmp(save_path(end), '/')
    save_path = save_path(1:end-1);
end
trc_fname = [save_path, '/', save_name];

%Drop the camera time (if exists) and convert to array
if any(matches(qtm_data.Properties.VariableNames, 'CameraTime'))
    qtm_data.CameraTime = [];
else
    warning('Did not detect camera time! This does not affect static cal but will affect motion trials');
end
   

data_matrix = table2array(qtm_data);

%Usually will be 1, but not if we cropped the QTM file
first_frame = qtm_data.Frame(1);

%validate
if n_markers ~= length(marker_names)
    error('Problem reading file! Wrong number of marker names or markers found!');
end

%validate
if n_frames ~= size(qtm_data,1)
    error('Frame size and number of rows do not match up!');
end

disp('Exporting to .trc...');

%Row one contains:
%path file type label (string)      path file type number(int)      path file type descriptor
%(string)           original directory path adn file name (string)

%OpenSim requires the following metadata in the header:
% see: https://github.com/opensim-org/opensim-core/blob/a837a156e348c82491e23de6d94f0ab9c8ab0085/OpenSim/Common/TRCFileAdapter.cpp#L21
% DataRate
% CameraRate
% NumFrames
% NumMarkers
% Units
% OrigDataRate
% OrigDataStartFrame (different name than above)
% OrigNumFrames (missing above)

%Ermm save to file? 

%Prepare haeder
line_one = 'PathFileType  4\t(X/Y/Z) C:\\PlaceHolderFilePath\\\n';
line_two = 'DataRate\tCameraRate\tNumFrames\tNumMarkers\tUnits\tOrigDataRate\tOrigDataStartFrame\tOrigNumFrames\n';
%Fields are DataRate	CameraRate	NumFrames	NumMarkers	Units	OrigDataRate	OrigDataStartFrame	OrigNumFrames

line_three = sprintf('%7.1f\t\t%7.1f\t\t%7i\t\t%7i\t%7s\t%7.1f\t%7i\t%7i\n', ...
    fs, fs, n_frames, n_markers, 'mm', fs, first_frame, n_frames);
line_four = ['Frame#\tTime\t', strip(sprintf('%s\t\t\t', marker_names{:})), '\t\t\t\n'];

%If this was python we could do a list comprehension but no...
line_five = '\t\t';

for a=1:length(marker_names)
    line_five = [line_five, sprintf('X%i\tY%i\tZ%i\t',a,a,a)];
end
line_five = [line_five, '\n'];
line_six = '\n';

%Create the trc file
fid = fopen(trc_fname, 'w'); %w for (over)write

%Write the header
fprintf(fid, line_one);
fprintf(fid, line_two);
fprintf(fid, line_three);
fprintf(fid, line_four);
fprintf(fid, line_five);
fprintf(fid, line_six);

%Write the data, line by line
for a=1:size(data_matrix, 1)
    %It is very important that the frame number be an INTEGER, not a float!
    %(this was the bug that was preventing animation display)
    frame_string = sprintf('%i\t', data_matrix(a,1));
    line_string = strip(sprintf('%.6f\t', data_matrix(a,2:end)));
    fprintf(fid, frame_string);
    fprintf(fid, line_string);
    fprintf(fid, '\n');
end

fclose(fid);

%Delete the temp file

disp('Done!');


end

