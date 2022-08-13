function write_trc(trc_header, trc_data, save_path)
%Write an OpenSim-compatible .trc file

fid = fopen(save_path, 'w'); %w for (over)write

for a=1:size(trc_header,1)
    %Fix some matlab messiness
    this_line = strrep(trc_header{a}, '\', '\\');
    fprintf(fid, this_line);
end

%Write the data, line by line. Lil slow but reliable and not buggy
for a=1:size(trc_data, 1)
    %It is very important that the frame number be an INTEGER, not a float!
    %(this was the bug that was preventing animation display)
    frame_string = sprintf('%i\t', trc_data(a,1));
    line_string = strip(sprintf('%.6f\t', trc_data(a,2:end)));
    fprintf(fid, frame_string);
    fprintf(fid, line_string);
    fprintf(fid, '\n');
end

fclose(fid);
end

