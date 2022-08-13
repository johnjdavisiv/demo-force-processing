function qtm_data = parse_qtm_tsv(motion_tsv_path)


fid = fopen(motion_tsv_path);

head_def = 0;
f_line_limit = 1;
%This is the header line
while ~head_def
    this_line = fgetl(fid);
    f_line_limit = f_line_limit+1;
    
    if contains(this_line, ['Frame', char(9), 'Time'])
        head_def = 1;
    end
    
    if f_line_limit > 20
        error('Cannot parse QTM header!');
    end
end
fclose(fid);

disp('Reading QTM exported TSV...');

%get this file
fid = fopen(motion_tsv_path);
Q_header = cell(f_line_limit-1,1);  
f_line = 1;

while f_line < f_line_limit
    Q_header{f_line} = fgetl(fid);
    f_line = f_line+1;
end

fclose(fid);

%Read the data
qtm_data = readtable(motion_tsv_path, 'Delimiter', '\t', 'NumHeaderLines', f_line_limit-2,...
    'FileType', 'text', 'TreatAsMissing', 'NaN');



end

