function qtm_data = rotate_qtm_data(qtm_data,marker_names)

%Flip markers from IUBLM coordinate system to OpenSim coordinate system
%Make +X the new +A/P (instead of Y)

disp('Flipping markers...');

%if length(marker_names)*3+3 ~= size(qtm_data,2)
%    error('Marker names do not match number of columns!');
%end  
  
all_columns = qtm_data.Properties.VariableNames;

for a=1:length(marker_names)
    marker_ix = matches(all_columns, [marker_names{a},'X']);
    marker_iy = matches(all_columns, [marker_names{a},'Y']);
    marker_iz = matches(all_columns, [marker_names{a},'Z']);
    
    if sum(marker_ix) ~= 1 || sum(marker_iy) ~= 1 || sum(marker_iz) ~= 1
        error('Problem indexing marker columns!');
    end
    
    %Get cols for this marker
    X_col = qtm_data{:,marker_ix};    
    Y_col = qtm_data{:,marker_iy};
    Z_col = qtm_data{:,marker_iz};
    
    %Now the big flip...
    %QTM x becomes osim z
    %QTM y becomes osim x
    %QTM z becomes osim y
    
    %osim x is QTM y
    %osim y is QTM z
    %osim z is QTM x
    
    qtm_data{:,marker_ix} = Y_col;
    qtm_data{:,marker_iy} = Z_col;
    qtm_data{:,marker_iz} = X_col;
end

end

