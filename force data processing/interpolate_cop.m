function mot_data = interpolate_cop(mot_data, step_start_ind, step_end_ind, n_steps)

%Use many tricks to interpolate center of pressure data. Inspired by Ajay
%Seth's Github comments. This helps avoid problems at IC and TO during
%running, especially with noisy force plate data. Opensim splines force data
%so you can get crazy joint moments (because GRF COP is really far away) if you don't use these
%tricks

%Osim columns are
%vx vy vz px py pz mx my mz
px_ix = 4;
pz_ix = 6;
%We don't need to iterpolate vertical (py), because it is always zero 

%% First step: interpolate from midpoint of that step
%BUT ONLY IF first frame is not a step
if step_start_ind(1) > 1
    %Use midpoint of first step as place to start interpolation from at
    %beginning (since we don't have a previous step)
    first_step_start_ix = step_start_ind(1);
    first_step_end_ix = step_end_ind(1);
    mid_step_ix = round(mean([first_step_start_ix, first_step_end_ix]));
    
    px_pre_first = mot_data(mid_step_ix, px_ix);
    pz_pre_first = mot_data(mid_step_ix, pz_ix);
    
    px_first = mot_data(first_step_start_ix, px_ix);
    pz_first = mot_data(first_step_start_ix, pz_ix);
    
    %Query points - note start at one here because we DO need first one
    %unlikein the later loop
    i_query = 1:(first_step_start_ix-1);
    px_interp = interp1([1, first_step_start_ix], ...
        [px_pre_first, px_first], i_query, 'linear');
    pz_interp = interp1([1, first_step_start_ix], ...
        [pz_pre_first, pz_first], i_query, 'linear');
    
    %Drop in interpolated
    mot_data(i_query, px_ix) = px_interp;
    mot_data(i_query, pz_ix) = pz_interp;
end
   
%% Middle steps
%-1 because can't interpolate after last step
for a=1:n_steps-1
    last_step_ix = step_end_ind(a);
    next_step_ix = step_start_ind(a+1);
    
    %Interpolation query points should be last_ix+1:1:next_ix-1    
    px_last = mot_data(last_step_ix,px_ix);
    pz_last = mot_data(last_step_ix,pz_ix);
    
    px_next = mot_data(next_step_ix,px_ix);
    pz_next = mot_data(next_step_ix,pz_ix);
    
    %use vq = interp1(x,v,xq,method)
    %x is like t,v is like y, where y(t). method should be 'linear'
    %cred to Ajay Seth for this smart idea
    i_query = (last_step_ix+1):(next_step_ix-1);
    px_interp = interp1([last_step_ix, next_step_ix], ...
        [px_last, px_next], i_query, 'linear');
    pz_interp = interp1([last_step_ix, next_step_ix], ...
        [pz_last, pz_next], i_query, 'linear');
    
    %Drop in interpolated points for COP
    mot_data(i_query,px_ix) = px_interp;
    mot_data(i_query,pz_ix) = pz_interp;
end

%% Interpolate after last step IF it does not end on last frame
%Do same thing where we go back to midpoint

if step_end_ind(end) ~= size(mot_data,1)
    
    last_step_start_ix = step_start_ind(end);
    last_step_end_ix = step_end_ind(end);
    mid_step_ix = round(mean([last_step_start_ix, last_step_end_ix]));
    
    px_after_last = mot_data(mid_step_ix, px_ix);
    pz_after_last = mot_data(mid_step_ix, pz_ix);
    
    px_last = mot_data(last_step_end_ix, px_ix);
    pz_last = mot_data(last_step_end_ix, pz_ix);
    
    %Query points - again different on last one
    i_query = (last_step_end_ix+1):size(mot_data,1);
    
    px_interp = interp1([last_step_end_ix, size(mot_data,1)], ...
        [px_last, px_after_last], i_query, 'linear');
    pz_interp = interp1([last_step_end_ix, size(mot_data,1)], ...
        [pz_last, pz_after_last], i_query, 'linear');
    
    %Drop in interpolated
    mot_data(i_query, px_ix) = px_interp;
    mot_data(i_query, pz_ix) = pz_interp;
end
    
    



