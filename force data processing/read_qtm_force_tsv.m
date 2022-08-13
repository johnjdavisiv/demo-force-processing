function [fp_data, fp_cols, fp_header] = read_qtm_force_tsv(tsv_file)
%Read QTM tsv line by line
n_header = 27; %hardcoded...

fid = fopen(tsv_file);
fp_header = cell(n_header,1);
fp_header(:) = {''};
%In header, you have [descripter]\t[value]\c\r
for a=1:n_header
    this_line = fgetl(fid); %fgetl to drop trailing \c\r 
    fp_header{a} = this_line;
end
fclose(fid);

fp_data = readmatrix(tsv_file, 'FileType', 'text', ...
    'NumHeaderLines', n_header);
fp_cols = strsplit(fp_header{n_header}, '\t');

