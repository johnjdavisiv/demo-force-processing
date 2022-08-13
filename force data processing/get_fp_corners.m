function [pxpy, nxpy, nxny, pxny, offset_vec] = get_fp_corners(tsv_file)

%Returns the four corners of the force plate, in global coordinates, but
%relative to an INTERNAL (action) coordinate system at the center of the
%plate. From the perspective of a runner on the Bertec treadmill (going forward),
% , "pxpy" is the upper left hand corner of the plate. nxny is lower right hand. 

%Get force plate info for a QTM .tsv export from one plate

%Force plate exports have a header of 27 lines
n_header = 27;

fid = fopen(tsv_file);
fp_header = cell(n_header,1);
fp_header(:) = {''};

%In header, you have [descripter]\t[value]\c\r
for a=1:n_header
    this_line = fgetl(fid); %fgetl to drop trailing \c\r
    %use fgets if you need them later
    
    fp_header{a} = this_line;
end

fclose(fid);

%dlmread is die
%fp_data = readmatrix(tsv_file, 'FileType', 'text', ...
%    'NumHeaderLines', n_header);
%fp_cols = strsplit(fp_header{n_header}, '\t');

%fp1_header(1)
%Note that left and right plates will share some corners because force
%plates are in a row! NOt all of course

%Global vs local coordinates are LITERALLY identical outside of how COP is
%expressed, and aside from local being ISB reaction convention and global
%being hte force plates internal action convention CS. 

%*Should* be able to just convert the COP using formulas? Maybe? 

%Soooo what info do we have in the header?

%XYZ coordinates of the four corners of the top of the force plate 
%And the z coord of all should be zero

%% Farm out to fuction - get FP corners

%Care, units are mm! 

%input is file path, or header?
%Another fucntion can read headeran dforce cols from file

%PosX PosY
pxpy_x = strsplit(fp_header{10}, '\t');
pxpy_x = str2double(pxpy_x{2});

pxpy_y = strsplit(fp_header{11}, '\t');
pxpy_y = str2double(pxpy_y{2});

pxpy_z = strsplit(fp_header{12}, '\t');
pxpy_z = str2double(pxpy_z{2});
%vec
pxpy = [pxpy_x, pxpy_y, pxpy_z];

%NegX PosY
nxpy_x = strsplit(fp_header{13}, '\t');
nxpy_x = str2double(nxpy_x{2});

nxpy_y = strsplit(fp_header{14}, '\t');
nxpy_y = str2double(nxpy_y{2});

nxpy_z = strsplit(fp_header{15}, '\t');
nxpy_z = str2double(nxpy_z{2});
%vec
nxpy = [nxpy_x, nxpy_y, nxpy_z];

%NegX Negy
nxny_x = strsplit(fp_header{16}, '\t');
nxny_x = str2double(nxny_x{2});

nxny_y = strsplit(fp_header{17}, '\t');
nxny_y = str2double(nxny_y{2});

nxny_z = strsplit(fp_header{18}, '\t');
nxny_z = str2double(nxny_z{2});
%vec
nxny = [nxny_x, nxny_y, nxny_z];

%PosX NegY
pxny_x = strsplit(fp_header{19}, '\t');
pxny_x = str2double(pxny_x{2});

pxny_y = strsplit(fp_header{20}, '\t');
pxny_y = str2double(pxny_y{2});

pxny_z = strsplit(fp_header{21}, '\t');
pxny_z = str2double(pxny_z{2});
%vec
pxny = [pxny_x, pxny_y, pxny_z];

%Offsets
x_offset = strsplit(fp_header{22}, '\t');
x_offset = str2double(x_offset{2});

y_offset = strsplit(fp_header{23}, '\t');
y_offset = str2double(y_offset{2});

z_offset = strsplit(fp_header{24}, '\t');
z_offset = str2double(z_offset{2});

offset_vec = [x_offset, y_offset, z_offset];

