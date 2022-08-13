function write_mot(mot_header, mot_data, save_path)
%Write an opensim-compatible .mot file

fid = fopen(save_path, 'w'); %w for (over)write

for a=1:length(mot_header)
    fprintf(fid, mot_header{a}); 
end

%Write the data, line by line. Lil slow but reliable and not buggy
for a=1:size(mot_data, 1)
    line_string = strip(sprintf('%.18f\t', mot_data(a,:)));
    fprintf(fid, line_string);
    fprintf(fid, '\n');
end

fclose(fid);

end

