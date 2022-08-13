function trc_cols = get_trc_columns(trc_data,trc_header)
%Quick n dirty function to get a cell array with the names of each column
%in the TRC file 
%Frame# Time then [marker]X [marker]Y [marker]Z ....

trc_headcell = strsplit(trc_header{4}, '\t');
trc_markers = trc_headcell(3:end-1); %End is the \r character

trc_cols = cell(1,size(trc_data,2));
trc_cols(:) = {''};

trc_cols{1} = trc_headcell{1}; %Frame#
trc_cols{2} = trc_headcell{2}; %Time
col_i = 3; %First 2 done

for a=1:length(trc_markers)
    %For each marker...
    %Columns x:x+2 are its columns
    this_marker = trc_markers{a};
    
    trc_cols{col_i} = [this_marker,'X'];
    trc_cols{col_i+1} = [this_marker,'Y'];
    trc_cols{col_i+2} = [this_marker,'Z'];
    
    col_i = col_i + 3; %++
end

end

