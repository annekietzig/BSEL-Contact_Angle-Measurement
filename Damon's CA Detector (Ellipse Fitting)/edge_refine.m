function [x_o,y_o]=edge_refine(x,y,side)
% in this function noises and reflections are camceled 
% x_o and y_o are outputs and starts from top of the image
%at eached point, distances to other points "d" are calculated.

N_S=150;%number of searching points
%% finding highest point ans setting it at starting point
[sta_y,in]=max(y);
sta_x=x(in);
ii=1;%index of output arrayes
y_o(ii)=sta_y;
x_o(ii)=sta_x;
%% main loop
ind=1;% index of x abd y arrayes not output arrayes
while ind<size(y,1) && (y_o(ii)-min(y)>10)%%%%%%VERY IMPORTANT *****bug source*******(y_o(ii)-min(y)>10) constrain is applied only for pillar surfaces 
    if N_S> size(y,1) -ind %cheching whether our seted searching points are mor than remian points or not
        N_S=size(y,1) -ind;
    end
    for jj=1:N_S
        d(jj)=sqrt((x_o(ii)-x(ind+jj))^2+(y_o(ii)-y(ind+jj))^2);%clculating distances to the reference point
    end
    [dis(ii),bin]=min(d);%finding closing point
    clearvars d% d array is cleared beacuse its size is constant at N_S at first but at ending points its size might be less than N_S so it is cleared each loop 
    ii=ii+1;
    y_o(ii)=y(ind+bin);%adding new point to the out put matrix
    x_o(ii)=x(ind+bin);
    if side=='r'%finding equivalent index in x and y arrayes
       ind=max(find(y==y_o(end)));
    elseif side=='l'
       ind=max(find(y==y_o(end)));
    end
end
end
