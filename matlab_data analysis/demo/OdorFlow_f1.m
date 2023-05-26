% OdorFlow_f1

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022')

%% load data
load(fullfile(datadir,'data_for_plots', 'fig1d_data.mat'))
load(fullfile(datadir,'data_for_plots', 'fig1d_hex_data2.mat'))
load(fullfile(datadir,'data_for_plots', 'fig1e_data.mat'))
load(fullfile(datadir,'data_for_plots', 'fig1e2_data.mat'))
load(fullfile(datadir,'data_for_plots', 'fig1f_data2.mat'))


% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1d_data.mat')
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1d_hex_data2.mat')
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1e_data.mat')
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1e2_data.mat')
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1f_data2.mat')

%% panel d:  sensor space
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1d_data.mat')
inter = 1;
figure()
imagesc((((flipud(fliplr(vq1_os)))))); hold on
scatter(xyv_os(:,2)*inter, xyv_os(:,1)*inter, 'k', 'LineWidth',3);
xlabel('Sensor columns');  ylabel('Sensor rows')
set(gca,'Fontsize',20);  set(gcf,'color','w');

%% Hexagon plots...
coli = ppms;
rows = 14;
columns = 8;
figure()
colour=[1, 0.4, 0.5];  % Any 3 values between 0 and 1, or predefined colors 'r', 'b', 'y', etc.
theta=0:pi/3:2*pi;
x=sin(theta);
y=cos(theta);
v=x(2);
u=y(1)+y(2);
for i=1:columns;
    x=x+v*2;
    a(i,:)=x; b(i,:)=y;
    c=a'; d=b';
%     r1=rem(i,2);
%     if r1==0, col1(i)='r';
%     else col1(i)='c';
%     end
    axis equal
%     patch(c(:,i),d(:,i),col1(i)); 
    for k=1:rows/2
        g=d+3*k;
        patch(c(:,i),g(:,i), coli(i,(k-1)*2+1))%, col1(i))
    end
end
for j=1:columns;
    e=c-v; f=d+u;
    r2=rem(j,2);
%     if r2==0, col2(j)='y';
%     else col2(j)='m';
%     end
%     patch(e(:,j),f(:,j),col2(j))
    for h=1:rows/2
        l=f+3*h;
        patch(e(:,j),l(:,j), coli(j,h*2))%col2(j))
    end
end
ax = gca;
axis(ax,'off')
h = colorbar('north'); caxis([0,200]); ylabel(h, 'ppm');
set(gca,'Fontsize',20);  set(gcf,'color','w');
% xlabel(ax,'sensor rows')
set(get(ax,'XLabel'),'Visible','on')
% ylabel(ax,'sensor columns')
set(get(ax,'YLabel'),'Visible','on')

%% panel e:  os to mm space
x_cm = 13;
y_cm = 12;
figure()
imagesc(linspace(0,x_cm,size(vq1_os2mm,1)),linspace(0,y_cm,size(vq1_os2mm,2)), (flipud(fliplr(vq1_os2mm))))
hold on
scatter(xyv_os(:,2)*1/(14/x_cm)-.5, xyv_os(:,1)*1/(16/y_cm)-.5, 'k', 'LineWidth',3);
xlabel('x (cm)');  ylabel('y (cm)'); h = colorbar(); caxis([0,200]); ylabel(h, 'ppm');
set(gca,'Fontsize',20);  set(gcf,'color','w');

%% panel e2:  pixel space
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1e_data.mat')
cov_wid = floor(33.3*2);
vq1_coved = conv2(vq1_os2mm, ones(cov_wid),'same')/cov_wid^2;%'valid');
figure()
imagesc(linspace(0,x_cm,size(vq1_os2mm,1)),linspace(0,y_cm,size(vq1_os2mm,2)),(((flipud(fliplr(vq1_coved))))));
xlabel('x (cm)');  ylabel('y (cm)'); h = colorbar(); caxis([0,200])
ylabel(h, 'ppm'); set(gca,'Fontsize',20);  set(gcf,'color','w');

%% panel f:  data vs. model
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1f_data.mat')
ccs = ['k','b','g','r'];
yy = linspace(-6,6,16);
% x_locs = [3:4; 5:6; 7:8; 11:12];
% data_x_conc = zeros(length(ccs), 16);
% model_x_conc = zeros(length(ccs), 16);
figure()
for ii = 1:length(ccs)
    yC = data_x_conc(ii,:);
    yc_model = model_x_conc(ii,:);
    plot(yy,yC,'.','color',ccs(ii),'Markersize',30); 
    hold on; plot(yy,yc_model,'color',ccs(ii), 'Linewidth',3); 
    xlabel('y (cm)'); ylabel('ppm'); legend('measurement','model');
end
xlim([-6,6]); set(gca,'Fontsize',20);  set(gcf,'color','w');

%% panel f2:  smoothed data vs. model
v = 0.0333; D = 0.08;
Dy = D/3.2;
x_eva = [3.5,5.5,7.5,11.5];%[2.5,5,7.5,10];
x_coord = linspace(0,y_cm,size(vq1_os2mm,2));
ccs = ['k','b','g','r'];
yy = linspace(-6,6,size(vq1_coved,1));  %in pixel space
vq1_eva = flipud(fliplr(vq1_coved));  %rotate to match evaluation in smoothed space
figure()
for ii = 1:length(x_eva)
    [k,pos] = min(abs(x_eva(ii)-x_coord));  %closest index for evaluation
    yC = vq1_eva(:,pos);
    xi = x_eva(ii);
    yc_model = max(yC)*exp(-yy.^2./(4*Dy*xi/v));
    plot(yy,yC,'--','color',ccs(ii),'Linewidth',3); 
    hold on; plot(yy,yc_model,'color',ccs(ii), 'Linewidth',3); 
    xlabel('y (cm)'); ylabel('ppm'); legend('smoothed measurement','model');
end
xlim([-6,6]); ylim([0,200]); set(gca,'Fontsize',20);  set(gcf,'color','w');

text(0,50,'x=3.5','Color','k','FontSize',15)
text(0,40,'x=5.5','Color','b','FontSize',15)
text(0,30,'x=7.5','Color','g','FontSize',15)
text(0,20,'x=11.5 cm','Color','r','FontSize',15)
