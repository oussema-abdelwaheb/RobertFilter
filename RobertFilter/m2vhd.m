%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filename: m2vhd.m                                                       %
% Author: Lotfi BOUSSAID                                                  %
% Date: 1/20/2006                                                         %
% Detail: output a specified image to a stream of integers                %
% for VHDL file input in binary format                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%infile=input('Fichier image : ','s');
%outfile=input('Fichier binaire : ','s');

image=imread('C:\Users\ousse\Desktop\TP1\lena.jpg');
z=size(size(image)); 
                    % z(1,2)=1 : grayscale image
                    % z(1,2)=3 : truecolor image 
if z(2)==3   
                    % transforms RGB to grayscale
   I=rgb2gray(image);
else        
   I=image;
end
                    % converts to 128 x 128 matrix with bilinear
                    % interpolation
                    
A=imresize(I,[128 128],'bilinear');                   
G=A;
I = int16(A);       
J = double(I);      % double precision
J = J';             % transpose
M = reshape(J,128*128,1);
fid = fopen('C:\Users\ousse\Desktop\TP1\lena.dat','wb');
fprintf(fid,'%d\n',M);
fclose(fid);
