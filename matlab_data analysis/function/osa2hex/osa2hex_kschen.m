%osa2hex
coli = ppms;
rows = 14;
columns = 8;
figure()
theta = 0:pi/3:2*pi;
x = sin(theta);
y = cos(theta);
v = x(2);
u = y(1)+y(2);
for i = 1:columns
    x = x+v*2;
    a(i,:) = x; 
    b(i,:) = y;
    c = a'; 
    d = b';
    axis equal
    for k = 1:rows/2
        g = d+3*k;
        patch(c(:,i),g(:,i), coli(i,(k-1)*2+1))
    end
end
for j = 1:columns
    e = c-v; 
    f = d+u;
    r2 = rem(j,2);
    for h = 1:rows/2
        l = f+3*h;
        patch(e(:,j),l(:,j), coli(j,h*2))
    end
end
ax = gca;
axis(ax,'off')
h = colorbar(); caxis([0,200]); ylabel(h, 'ppm');
set(gca,'Fontsize',20);  set(gcf,'color','w');
set(get(ax,'XLabel'),'Visible','on')
set(get(ax,'YLabel'),'Visible','on')
