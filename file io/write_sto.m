function write_sto(data_array,column_names, save_path, first_line_string)
%Write an array to OpenSim copmatible .sto format

%Debug
%data_array = marker_error_avg;
%column_names = error_marker_names;
%save_path = 'test_sto_output.sto';
%first_line_string = 'Test marker error output';

if length(column_names) ~= size(data_array,2)
    error('Columns do not match size of array!');
end

n_rows = size(data_array,1);
n_columns = size(data_array,2);

%Write header per specs
fid = fopen(save_path, 'w'); %w for (over)write
fprintf(fid, [first_line_string, '\n']);
fprintf(fid, 'version=1\n');
fprintf(fid, 'nRows=%i\n', n_rows);
fprintf(fid, 'nColumns=%i\n', n_columns);
fprintf(fid, 'inDegrees=no\n');
fprintf(fid, 'endheader\n');
col_line = [strip(sprintf('%s\t', column_names{:})), '\n'];
fprintf(fid, col_line);

%Write the data, line by line. Lil slow but reliable and not buggy
for a=1:size(data_array, 1)
    line_string = strip(sprintf('%.12f\t', data_array(a,:)));
    fprintf(fid, line_string);
    fprintf(fid, '\n');
end

fclose(fid);
