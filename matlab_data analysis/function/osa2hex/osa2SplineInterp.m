%osa2hex
function [xx,yy,im] = osa2SplineInterp(ppm, s, normalize)
% makeOsaPatch(ppm)
%
% dx = 1 --> flow direction
% dy = 1.5 - opposite flow direction
%
% stagger = 0.75 - displacement of second column on osa bar
%
% ppm is ny x nx (standard matrix form)
% 

if (nargin < 3 || normalize)
    ppmd = repmat(mean(ppm,1,'omitnan'),[size(ppm,1) 1])./mean(ppm,'all','omitnan');
    ppm = ppm./ppmd;
end

%spacing is 1 x .75 --> LCM is 4x.25 3x.25. each y has 1/2 sensors, so 6*ny,
%4*nx
ppm2 = NaN(size(ppm).*[6 4]);
for j = 1:size(ppm,2)
    ppm2((1+3*mod(j,2)):6:end,4*j) = ppm(:,j);
end

ppm2i = l1spline(ppm2, s, 1, 100, 1, 1e-5);


[xx,yy] = meshgrid((1:size(ppm2,2))*.75, (1:size(ppm2,1))*.75);
im = ppm2i;
if (nargout < 1)
    pcolor(xx,yy,im); shading flat; axis equal; axis tight;
    
end

