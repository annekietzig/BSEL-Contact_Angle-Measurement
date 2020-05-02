function [D]=contactangle(x,y,side)
if side=='r'
    [~,in]=max(x);%%%%VERY IMPORTANT *****bug source******* we assumed the surface is hydrophobic
elseif side=='l'
    [~,in]=min(x);%%%%VERY IMPORTANT *****bug source******* we assumed the surface is hydrophobic
end
fiit = fit(x(in:end)',y(in:end)','smoothingspline','SmoothingParam',0.05);
[fx_R, fxx] = differentiate(fiit, x(in:end)');
% D_R=180-atand(fx_R);
if side=='r'
    D=180-abs(atand(min(fx_R)));
elseif side=='l'
    D=180-abs(atand(max(fx_R)));
end
end