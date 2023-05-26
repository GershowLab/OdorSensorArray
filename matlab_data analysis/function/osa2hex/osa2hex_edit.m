%osa2hex
function osa2hex_edit(ppm, normalize)
% osa2hex(ppm, normalize)
%
% dx = 1 --> flow direction
% dy = 1.5 - opposite flow direction
%
% stagger = 0.75 - displacement of second column on osa bar
%
% ppm is ny x nx (standard matrix form)
% 

if (nargin < 2 || normalize)
    ppmd = repmat(mean(ppm,1,'omitnan'),[size(ppm,1) 1])./mean(ppm,'all','omitnan');
    ppm = ppm./ppmd;
end

dx = 1;
dy = 1.5;
stagger = 0.75;

ny = size(ppm,1);
nx = size(ppm,2);


[ii,jj] = meshgrid(1:nx, 1:ny);
ind1d = sub2ind(size(ppm), jj(:), ii(:));
%[xx,yy] = meshgrid( (1:nx)*dx,(1:ny)*dy);
xx = ii*dx;
yy = jj*dy;

yy(:,2:2:end) = yy(:,2:2:end) + stagger;


bbx = (1:nx)*dx;
bby = (1:ny)*dy;

bbxx = [bbx 0*bby-dx bbx 0*bby+(nx+2)*dx];
bbyy = [0*bbx-dy bby 0*bbx+(ny+2)*dy+stagger bby+stagger];

DT = delaunayTriangulation([xx(:);bbxx(:)], [yy(:);bbyy(:)]);
[V,r] = DT.voronoiDiagram;
for j = 1:length(ind1d)
    ind = DT.nearestNeighbor(xx(ind1d(j)),yy(ind1d(j)));
    vx = V(r{ind},1);
    vy = V(r{ind},2);
    
    patch(vx, vy, ppm(ind1d(j)))
end
xlim([dx (nx)*dx]); ylim([dy (ny)*dy+stagger]);
axis("equal");
xlim([dx (nx)*dx]); ylim([dy (ny)*dy+stagger]);

return
