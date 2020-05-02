function [x,y]=contact_point(x,y,side)
%% deletting lower parts of pillars: the average disstance of all selected poins is calculated then those points which has distance than mean are canceld  this section will be uncomment for non pillar surfaces
% average_dis=mean(abs(diff(x)));
% qq=find(abs(diff(x))>2*average_dis);%% VERY IMPORTANT *****bug source******* all points with distances mor that twice of average are deleted
% x(min(qq):end)=[];
% y(min(qq):end)=[];
%% deleting lowere part of contact point: The point where the sign of differences is cahange is the contact point
if side=='l'
    [~,in_s]=min(x);%%%%VERY IMPORTANT *****bug source******* we assumed the surface is hydrophobic
    in_s=round(in_s+(size(x,2)-in_s)/3);
    dx=diff(x(in_s:end));
    [~,b]=find(dx<0);
elseif side=='r'
    [~,in_s]=max(x);%%%%VERY IMPORTANT *****bug source******* we assumed the surface is hydrophobic
    in_s=round(in_s+(size(x,2)-in_s)/3);
    dx=diff(x(in_s:end));
    [~,b]=find(dx>0);
end
if ~isempty(b)
    b=b+in_s;
    x(min(b):end)=[];  
    y(min(b):end)=[];  
end
end
