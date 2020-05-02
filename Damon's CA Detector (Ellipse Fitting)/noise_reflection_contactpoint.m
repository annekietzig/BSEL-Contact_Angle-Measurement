function [x_o_l,x_o_r,y_o_l,y_o_r]=noise_reflection_contactpoint(edges1)
%s_y:sorted y points
%s_x:sorted x points
%l_in: left side points' index 
%r_in: right side points' index 
%s_x_l:left side sorted points;
%s_x_r: right side sorted points
x=edges1.x;
y=-1.*(edges1.y-max(edges1.y));
%% sorting and deviding points into left and right groups
[s_y,I] = sort(y,'descend');
s_x=x(I);
[l_in] = find(s_x<mean(s_x(1:100)));%%%%VERY IMPORTANT *****bug source***** we assumed there is a Needle with at least 100 pixel %defining the left point based on top points x posision.(it is assumed that there is a needle in the paicture);
[r_in] = find(s_x>mean(s_x(1:100)));
s_x_l=s_x(l_in);
s_y_l=s_y(l_in);
s_x_r=s_x(r_in);
s_y_r=s_y(r_in);
side='l';
[x_o_l,y_o_l]=edge_refine(s_x_l,s_y_l,side);% canseling noises/reflecttion points;
[x_o_l,y_o_l]=contact_point(x_o_l,y_o_l,side);%finding contact point and canceling all points lower
side='r';
[x_o_r,y_o_r]=edge_refine(s_x_r,s_y_r,side);
[x_o_r,y_o_r]=contact_point(x_o_r,y_o_r,side);%finding contact point and canceling all points lower
end
