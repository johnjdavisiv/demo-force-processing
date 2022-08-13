function [n_bouts, bout_start_ind, bout_end_ind, bout_length] = get_bouts(v_logical, varargin)
%get_bouts
%John J Davis IV
%IU Biomechanics lab
%6 October 2019

%varargin = min_length

%Gets the number, start index, and end index of continuous streaks of
%activity, based on a logical vector input. 
%For example, the vector:

%1 1 1 1 0 0 0 0 1 1 1 0 0 0 0 
%has two "bouts" of 1s. 

%This function returns the number of streaks of TRUE values (1), 
%plus vectors containing the start and end index of each streak.


%varargin accepts one additional (optional) argument: min_length

%if this is provided, bouts below min_length are ignored.


if min(size(v_logical)) ~= 1
    error('getBouts only accepts vector inputs.');
end

%Transpose vector to avoid problems
if size(v_logical,2) ~= 1
    v_logical = v_logical'; %make sure it is a column vector
end


if nnz(v_logical) == 0 %If NO activity at all...just return empty
    
    n_bouts = 0;
    bout_start_ind = [];
    bout_end_ind = [];
    bout_length = [];

elseif nnz(v_logical) == length(v_logical) %If the input data is ONE streak of all 1s
    n_bouts = 1;
    bout_start_ind = 1;
    bout_end_ind = length(v_logical);
    bout_length = length(v_logical);

else 
    %Find streaks of continuous 1s
    mydiff = (diff(v_logical)==0);
    ix=find(mydiff == 0);  % find the indices where these streaks end
    ix(end+1) = length(v_logical); %Without this you will always miss the LAST streak
    if size(ix,2) ~= 1 %only occurs when there is only one streak
        ix = ix'; %transpose for consistency
    end      

    sl=diff([0; ix]);     % sl = streak length, i.e. how long was this streak?

    for a=1:length(ix) %This is not vectorized but not a big deal
        ix(a,2) = v_logical(ix(a,1));
    end

    streak_index_length = [ix(:,1)-sl+1, ix, sl]; 

    %streak_index_length (and one_streaks) have four columns:
    %The first and second tell you the index of the START and END of a streak. 
    %The third column tells you whether that was a streak of EC content (1) or non-EC (0)
    %The fourth column tells you how long (in samples) that streak was.

    one_streaks = streak_index_length(streak_index_length(:,3) == 1,:);

    n_bouts = size(one_streaks,1);
    bout_start_ind = one_streaks(:,1);
    bout_end_ind = one_streaks(:,2);
    bout_length = one_streaks(:,4);
    
end

%Check if user supplied min_bout_length and if so, exclude those that are too short
if nargin > 1 
    use_ind = (bout_length >= varargin{1});
    n_bouts = nnz(use_ind);
    
    if n_bouts >0
        bout_start_ind = bout_start_ind(use_ind);
        bout_end_ind = bout_end_ind(use_ind);
        bout_length = bout_length(use_ind);
    else
        n_bouts = 0;
        bout_start_ind = [];
        bout_end_ind = [];
        bout_length = [];
    end
end
end

