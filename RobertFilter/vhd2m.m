IMG_W = 128;
IMG_H = 128;
valid_W = IMG_W - 1;
valid_H = IMG_H - 1;

fid = fopen('C:\Users\ousse\Desktop\TP1CAO\output.dat','r');
I = fscanf(fid,'%d',inf);
fclose(fid);

% Pad missing values with zeros to match expected size
expected_vals = valid_W * valid_H;
if length(I) < expected_vals
    warning('Padding %d missing values with zeros', expected_vals - length(I));
    I(end+1:expected_vals) = 0;
elseif length(I) > expected_vals
    I = I(1:expected_vals);  % truncate extra
end

% reshape
img = reshape(I, valid_W, valid_H)';
img_disp = uint8(min(abs(img),255));
imwrite(img_disp,'robert_channel.jpg');
