%osa2hex
function [xx,yy,im] = osa2Interp(ppm, sigma, normalize)
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

dx = 1;
dy = 1.5;
stagger = 0.75;

ny = size(ppm,1);
nx = size(ppm,2);

npx = nx*10;



[ii,jj] = meshgrid(1:nx, 1:ny);
ind1d = sub2ind(size(ppm), jj(:), ii(:));
%[xx,yy] = meshgrid( (1:nx)*dx,(1:ny)*dy);
xx = ii*dx;
yy = jj*dy;

yy(:,2:2:end) = yy(:,2:2:end) + stagger;

F = scatteredInterpolant(xx(ind1d), yy(ind1d), ppm(ind1d), 'natural');


[xx,yy] = meshgrid(min(xx(:)):0.25:max(xx(:)), min(yy(:)):0.25:max(yy(:)));
im = F(xx,yy);
if (nargout < 1)
    pcolor(xx,yy,blurim(im,4*sigma)); shading flat; axis equal; axis tight;
end
return
