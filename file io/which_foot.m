function foot = which_foot(trc_data, trc_cols, marker_mid_ix, R_heel_markers, L_heel_markers)
%Determine which foot is closer to the ground at marker_mid_ix, based on
%the vertical (y) position of the R_heel_markers and L_heel_markers.

%Markers on foot should be in order of preference (will start with first
%one and only use next ones only if previous is NaN). This means that this
%function is robust to occsaionlly-missing foot markers, just supply a
%longer list of markers on the feet. 

%Returns 'R' or 'L'

if length(trc_cols) ~= size(trc_data,2)
    error('Column labels and data do not match!');
end

%Store the Y value (vertical position) of each of our candidate markers
R_y_vals = nan(length(R_heel_markers),1);
L_y_vals = nan(length(L_heel_markers),1);

for b=1:length(R_y_vals)
    R_col = matches(trc_cols, [R_heel_markers{b},'Y']);
    if sum(R_col) ~= 1
        error('Marker not found!');
    end
    R_y_vals(b) = trc_data(marker_mid_ix, R_col);
end

%Allow for different L foot marker list length
for b=1:length(L_y_vals)
    L_col = matches(trc_cols, [L_heel_markers{b},'Y']);
    if sum(L_col) ~= 1
        error('Marker not found!');
    end
    L_y_vals(b) = trc_data(marker_mid_ix, L_col);
end
% 
% hold on;
% plot(trc_data(:,R_col), 'r');
% plot(trc_data(:,L_col), 'b');
% xline(marker_mid_ix, '--');
% plot(mot_foo, 'k')
% 
% mot_foo = fp1_v_f(1:4:end,:);

%Drop nan markers
R_y_vals(isnan(R_y_vals)) = [];
L_y_vals(isnan(L_y_vals)) = [];

if isempty(R_y_vals) || isempty(L_y_vals)
    error('No non-NaN markers for foot!');
end

%Use first index now

%If the vertical position of the right foot is smaller than the left foot,
%at midstance, this is a right foot contact!
if R_y_vals(1) < L_y_vals(1)
    foot = 'R';
elseif R_y_vals(1) > L_y_vals(1)
    foot = 'L';
else
    error('Something went wrong identifying steps!');
end

end
