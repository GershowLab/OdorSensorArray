% OdorFlow_f2

%% load data
% OS traces for BC or downstream readout
% comparison for wo, w/ agar, and after protocol
%%% panel b: ppm_wo, ppm_ne, ppm_eq, each as OS x Time values
%%% panel d: target, nonequ, equili, each as array size (8x(2*bars))

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
% datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022','data_for_plots')

% Get a list of all files in the directory
files = dir(fullfile(datadir, 'fig2*'));

% Loop through each file and load it
for i = 1:length(files)
    filename = fullfile(datadir, files(i).name);
    load(filename)
end

%% panel b
% folder = '/projects/LEIFER/Kevin/Data_cone/20220226_GWN_naive_cone_11mM_6_17ml_400air/';
% osa_fname = '20220226185601_osa_naive_cone_9dil_16MEK11mM_400air.txt';

% compare three conditions of BC downstream from agar plate
figure
xx = linspace(-7,7,size(ppm_wo,1));
subplot(131)
yy = ppm_wo(:,end)-ppm_wo(:,1);
plot(xx,yy,'ro','LineWidth',2); hold on
f = fit(xx.', yy,'gauss1'); Yhat_wo = feval(f, xx);
plot(xx, Yhat_wo,'r','LineWidth',2)
xlabel('y (cm)'); ylabel('ppm'); legend({'measurement', 'model'})
set(gca,'Fontsize',20); xlim([-7,7]); ylim([0,210])
subplot(132)
yy = ppm_ne(:,end)-ppm_ne(:,1);
plot(xx,yy,'bo','LineWidth',2); hold on
f = fit(xx.', yy,'gauss1'); Yhat_ne = feval(f, xx);
plot(xx, Yhat_ne,'b','LineWidth',2)
set(gca,'Fontsize',20); xlim([-7,7]); ylim([0,210])
xlabel('y (cm)');
subplot(133)
yy = ppm_eq(:,end);
plot(xx,yy,'ko','LineWidth',2); hold on
f = fit(xx.', yy,'gauss1'); Yhat_eq = feval(f, xx);
plot(xx, Yhat_eq,'k','LineWidth',2)
set(gca,'Fontsize',20); xlim([-7,7]); ylim([0,210])
xlabel('y (cm)');

% subplot(144)
% plot(xx, abs(Yhat_wo-Yhat_ne)'./Yhat_wo'*100, 'b','LineWidth',2,  'DisplayName', '1'); hold on %'Color',uint8([170 170 170])
% plot(xx, abs(Yhat_wo-Yhat_eq)'./Yhat_wo'*100, 'k', 'LineWidth',2,  'DisplayName','2');
% xlabel('y (cm)'); ylabel('relative difference (%)'); 
% legend('w/o agar vs. w/ agar w/o CC', 'w/o agar vs. w/ agar w/ CC'); xlim([-7,7]); ylim([0,100])
% set(gca,'Fontsize',20);  set(gcf,'color','w');

%% panel d
% osa_fname = '20220325122506_osa_45thagar_110mM_400ml.txt';
% mfc_fname = '20220325123821_MFCPID_45thagar_110mM_400ml.txt';

% compare three conditions of downstream from agar slot
figure
ax(1) = subplot(2,4,[1,5]);
imagesc([1:size(wo_vq1,2)]*(0.1),[1:size(wo_vq1,1)]*(0.075),wo_vq1)
caxis([min(min(eq_vq1)), max(max(eq_vq1))]);
xlabel('x (cm)');  ylabel('y (cm)');  set(gca,'Fontsize',20);
ax(2) = subplot(2,4,[2,6]);
imagesc([1:size(wo_vq1,2)]*(0.1),[1:size(wo_vq1,1)]*(0.075),ne_vq1)
caxis([min(min(eq_vq1)), max(max(eq_vq1))]); set(gca,'Fontsize',20);
ax(3) = subplot(2,4,[3,7]);
imagesc([1:size(wo_vq1,2)]*(0.1),[1:size(wo_vq1,1)]*(0.075),eq_vq1)
caxis([min(min(eq_vq1)), max(max(eq_vq1))]); set(gca,'Fontsize',20);
h = colorbar();ylabel(h, 'ppm'); set(gca,'Fontsize',20);

ax(4) = subplot(2,4,4);
imagesc([1:size(wo_vq1,2)]*(0.1),[1:size(wo_vq1,1)]*(0.075),abs(wo_vq1-ne_vq1)./wo_vq1*100);
h = colorbar(); caxis([0,60]);ylabel(h, 'relative difference (%)'); set(gca,'Fontsize',20);
ax(5) = subplot(2,4,8);
imagesc([1:size(wo_vq1,2)]*(0.1),[1:size(wo_vq1,1)]*(0.075),abs(wo_vq1-eq_vq1)./wo_vq1*100);
h = colorbar(); caxis([0,60])
ylabel(h, 'relative difference (%)'); set(gca,'Fontsize',20);  set(gcf,'color','w');
colormap(ax(4), autumn); colormap(ax(5), autumn)

%% panel d_new, with upstream
load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig2d_data.mat')
load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig2d_up.mat')
wo_all = [targ_up  targ_up*NaN  wo_vq1];
ne_all = [ne_up  targ_up*NaN  ne_vq1];
eq_all = [equ_up  targ_up*NaN  eq_vq1];
maxppm = 300;
rescale = 14/51;
figure
ax(1) = subplot(131);
imagesc([1:size(wo_vq1,2)]*(rescale),[1:size(wo_vq1,1)]*(0.075),wo_all)
% caxis([min(min(eq_vq1)), max(max(eq_vq1))]);
caxis([0,maxppm]);
xlabel('x (cm)');  ylabel('y (cm)');  set(gca,'Fontsize',20);
ax(2) = subplot(132);
imagesc([1:size(wo_vq1,2)]*(rescale),[1:size(wo_vq1,1)]*(0.075),ne_all)
caxis([0,maxppm]); set(gca,'Fontsize',20);
ax(3) = subplot(133);
imagesc([1:size(wo_vq1,2)]*(rescale),[1:size(wo_vq1,1)]*(0.075),eq_all)
set(gca,'Fontsize',20); h = colorbar(); caxis([0,maxppm]); ylabel(h, 'ppm'); set(gca,'Fontsize',20);set(gcf,'color','w');


%% panel e
oss = [3, 6, 7];
figure()
subplot(131)
plot((ppm_wo(oss,:))' - ppm_wo(oss,1)', 'k','Linewidth',3)
xlabel('time (s)'); ylabel('ppm'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0,900]); ylim([0,250])
subplot(132)
plot(ppm_ne(oss,:)' - ppm_ne(oss,1)', 'k','Linewidth',3)
xlabel('time (s)'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0,900]); ylim([0,250])
subplot(133)
plot(ppm_eq(oss,:)', 'k','Linewidth',3); hold on;
% plot(ppm_pe(oss,:)', 'k-.','Linewidth',3); h
xlabel('time (s)'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0,900]); ylim([0,250])

%%
% numerical result here~
oss = [3, 6, 7];
ccs = ['b','g','r'];
figure()
for ii = 1:3
    temp_eq = (ppm_wo(oss(ii),:))' - ppm_wo(oss(ii),1)';
    target = temp_eq(end);
    subplot(131)
    plot(temp_eq, 'Color', ccs(ii),'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',3)
    xlabel('time (s)'); ylabel('ppm'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0,250]); ylim([0,250]);
    legend('target','time trace');
    subplot(132)
    plot(ppm_ne(oss(ii),:)' - ppm_ne(oss(ii),1)', 'Color', ccs(ii),'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',3)
    xlabel('time (s)'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0,250]); ylim([0,250])
    subplot(133)
    plot(ppm_eq(oss(ii),:)', 'Color', ccs(ii),'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',3)
    xlabel('time (s)'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0,250]); ylim([0,250])
end

%% panel f
time = 0:0.1:250;
% numerical result here~
ccs = ['r','g','b'];
figure()
for ii = 1:3
    subplot(131)
    target = max(c2_wo(ii,:));
    plot(time, c2_wo(ii,:), 'Color', ccs(ii), 'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',3)
    xlabel('time'); ylabel('ppm');  legend('target','time trace');
    xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20);  
    subplot(132)
    plot(time, c2_ne(ii,:), 'Color', ccs(ii), 'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',3)
    xlabel('time'); xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20); 
    subplot(133)
    plot(time, c2_eq(ii,:), 'Color', ccs(ii), 'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',3)
    xlabel('time'); xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20); 
    set(gcf,'color','w');
end

