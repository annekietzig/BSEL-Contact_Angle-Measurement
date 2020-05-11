clear
clc
format short
close all
vidObj = VideoReader('P100_2.mov');
threshold= 30;
numFrames = ceil(vidObj.FrameRate*vidObj.Duration);
count=0;
bline=17;
for ii=1:3:numFrames
    count=count+1
    frame1 = read(vidObj,ii);
    frame1= rgb2gray(frame1);
    edges1 = subpixelEdges(frame1, threshold); 
    [x_o_l,x_o_r,y_o_l,y_o_r]=noise_reflection_contactpoint(edges1);
    [v(count)]=contactangle(x_o_l,y_o_l,'l');
    [D_r(count)]=contactangle(x_o_r,y_o_r,'r');
end

