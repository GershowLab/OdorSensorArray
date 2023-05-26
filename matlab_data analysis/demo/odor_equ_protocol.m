%%% odor_equ_protocol

% code to preprocess data for:
%                             figure 4: calibration and plotting

% this is used to analyze raw concentration recordings for condition with
% OSBs replaced by agar to test out the odor-agar effects and equilibrium
% protocol. This will generate .mat files to be further used for figures

% Saved files can then be used in OdorFlow_f2.m for figure plots.

% This script requires function to read from the OSA and function fitting
% toolbox that should be included in Matlab

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022','odor_calibrate');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022','odor_calibrate')

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BC comparison and time series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load flow with different chamber configurations
% % % %%% for equ. protocol (old stuff)
% % % folder = '/projects/LEIFER/Kevin/Data_odor_flow_equ/20211210_GWN_app+_MEK110mM_gasphase_20ml';
% % % osa_fname = '/20211210165334_osa_plate.txt';
% % % mfc_fname = '/20211210170049_MFCPID_plate.txt';

%%% target (w/o agar)
osa_fname = '/20220406165408_osa_110_11mM_30MEK_400air.txt';
mfc_fname = '/20220406170248_MFCPID_110_11mM_30MEK_400air.txt';

% %%% protocol (for NE demo: w/ agar, w/o PE)
folder = datadir;%'/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
osa_fname = '/20220407103036_osa_equ_110mM_20_10_10_20ml_400air.txt';
mfc_fname = '/20220407104226_MFCPID_equ_110mM_20_10_10_20ml_400air.txt';
% 
% %%% protocol-2 (for equ demo: w/ agar, w/ PE)
osa_fname = '/20220407123222_osa_equ_2.txt';
mfc_fname = '/20220407123800_MFCPID_equ_2.txt';

%% read OSA
osb_num = 1;  %downstream boundary

[Read, osbs, time_osa] = Read_OSA([folder,osa_fname]);
[data_h2, data_Et, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);

%% read MFC-PID
mfc_table = readtable( [folder, mfc_fname] );  %ms timer | PID | MFC-command | MFC-read
time_mfc = mfc_table.Var1;
time_mfc = time_mfc-time_mfc(1);
PID = mfc_table.Var2;
MFC_com = mfc_table.Var3;
MFC_read = mfc_table.Var4;
sample_time = sample_time(sample_time<time_mfc(end));

%% processing in time
[Read, osbs, time_osa] = Read_OSA([folder,osa_fname]);
mfc_table = readtable([folder, mfc_fname]);  %ms timer | PID | MFC-command | MFC-read
time_mfc = mfc_table.Var1;
PID = mfc_table.Var2;
MFC_com = mfc_table.Var3;
MFC_read = mfc_table.Var4;

%%% truncating valid window
start_both = max(time_osa(1), time_mfc(1));
end_both = min(time_osa(end), time_mfc(end));
start_mfc = find(time_mfc>=start_both); start_mfc = start_mfc(1);
start_osa = find(time_osa>=start_both); start_mfc = start_mfc(1);
end_mfc = find(time_mfc<=end_both); end_mfc = end_mfc(end);
end_osa = find(time_osa<=end_both); end_osa = end_osa(end);

Read = Read(start_osa:end_osa,:);
osbs = osbs(start_osa:end_osa);
MFC_read = MFC_read(start_mfc:end_mfc);
PID = PID(start_mfc:end_mfc);
time_mfc = time_mfc(start_mfc:end_mfc);

%%% down sampling to align
osb_num = 7;
[data_h2, data_Et, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
sample_time = sample_time(sample_time<time_mfc(end));
[closest_time,closest_pos] = timealign(sample_time, time_mfc-time_mfc(1));
downsamp_mfc = MFC_read(closest_pos);
downsamp_pid = PID(closest_pos);
figure;plot(downsamp_mfc); hold on; plot(downsamp_pid)

%% align three part with different input configurations
os_num = 7:12;
wind = [1:900];%[2000:2400];%[1200:1600];%[500:900];%[1330:1550];%[40:540];
% wind = [510:910];%[1:350];%[3100:4300];%[4200:7000]; %[3050:4250];%[2020:2500];%[510:910];%[35:350];
figure()
subplot(3,1,1)
plot(downsamp_mfc(wind)*10,'k','linewidth',5)
ylabel('Flow (ml/min)', 'FontSize',15)
set(gca,'XTick',[])
ylim([0,4*10])
title('target C', 'FontSize',15)
subplot(3,1,2)
plot([downsamp_pid(wind)-downsamp_pid(wind(1))*0-0.2 ]*200/3,'linewidth',5)
ylabel('Odor (ppm)', 'FontSize',15)
set(gca,'XTick',[])
ylim([0, 150])
subplot(3,1,3)
plot(data_h2(os_num,wind+0)','linewidth',5)
ylabel('OSA (raw)', 'FontSize',15)
xlabel('time (s)', 'FontSize',15)
ylim([10000,20000])
set(gcf,'color','w');

%% compare OSBs
wo_plt = [1:900]; % w/o agar target
ne_plt = [1:900]; % w/ agar non-equilibrium
eq_plt = [2100:3000];  % w/ agar equ after PE

c = jet(length(wo_plt));
figure();
for ii = 1:length(wo_plt)
    plot(data_h2(:,wo_plt(ii)),  data_h2(:,eq_plt(ii)),  'o','color',c(ii,:)); hold on;
end
plot([10500,15000],[10500,15000],'k--')
xlabel('w/o plate','FontSize',15)
ylabel('equilibrium w/ plate','FontSize',15)
title('sensor readout (from boundary OSB (16 OSs), 100 s)')
set(gcf,'color','w');

%% gather ppm value in time
t_wind = wo_plt;
osbn = 1;
nos = 16;  %8 or 16
[data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osbn);
ppm_eq = zeros(nos,length(t_wind)); ppm_ne = ppm_eq*1; ppm_wo = ppm_ne*1;
% temp1 = zeros(1,nos); temp2 = temp1; temp3 = temp2;  %one row
temp1 = zeros(8,2); temp2 = temp1; temp3 = temp2;  %one bar
for tt = 1:length(t_wind)
    for jj = 1:nos
        temp1(jj) = OP_map(osbn,jj).f(data_h22(jj,wo_plt(tt)));  %ppm reading
        temp2(jj) = OP_map(osbn,jj).f(data_h22(jj,ne_plt(tt)));
        temp3(jj) = OP_map(osbn,jj).f(data_h22(jj,eq_plt(tt)));
    end
    
    %%% for only one column
%     ppm_wo(:,tt) = temp1 *200/2.9*0.86;
%     ppm_ne(:,tt) = temp2 *200/2.9*0.86;
%     ppm_eq(:,tt) = temp3 *200/2.9*0.86;
    
    %%% for the whole bar
      ppm_wo(:,tt) = reshape((temp1)',1,16) *200/2.9*0.86;
      ppm_ne(:,tt) = reshape((temp2)',1,16) *200/2.9*0.86;
      ppm_eq(:,tt) = reshape((temp3)',1,16) *200/2.9*0.86;

end

% figure
% plot(ppm_wo,ppm_ne,'o')

%% plot OS example traces
figure;
plot(ppm_eq([5,13,12],:)')
xlabel('time (s)')
ylabel('ppm')
set(gca,'Fontsize',20); set(gcf,'color','w');

%% plot in space
xx = linspace(-7,7,nos);
figure
plot(xx,ppm_wo(:,1),'r','LineWidth',2)
hold on
plot(xx,ppm_ne(:,1),'b','LineWidth',2)
plot(xx,ppm_eq(:,1),'g','LineWidth',2)

plot(xx,ppm_wo(:,end),'r--','LineWidth',2)
plot(xx,ppm_ne(:,end),'b--','LineWidth',2)
plot(xx,ppm_eq(:,end),'g--','LineWidth',2)
xlabel('y (cm)')
ylabel('ppm')
set(gca,'Fontsize',20); set(gcf,'color','w');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% agar slit test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
% folder = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';

%%% for NE+PE demo with agar in 4,5 position
osa_fname = '/20220325122506_osa_45thagar_110mM_400ml.txt';
mfc_fname = '/20220325123821_MFCPID_45thagar_110mM_400ml.txt';

%% test plot for visual checks
[Read, osbs, time_osa] = Read_OSA([folder,osa_fname]);
[data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, 1);

figure()
plot(data_h22')

%%  extract three conditions, across OSBs

%%% load a reasonable time window for each condition
targ_t = 2000:2100;
ne_t = 3600:3700;
equ_t = 7000:7100; 

osb_add = [7,6];%[3:-1:1];%
temp = zeros(8,2);
nb = length(osb_add);
target = zeros(100, 8,nb *2);
nonequ = zeros(100, 8,nb *2);
equili = zeros(100, 8,nb *2);

for ii = 1:length(osb_add)
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_add(ii));
    
    %%% raw to ppm, for three conditions
    ti=1;
    for tt=targ_t
        for jj = 1:16
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
        end
        target(ti,:,ii*2-1:ii*2) = fliplr(temp) *200/2.9*0.86;
        ti=ti+1;
    end

    ti=1;
    for tt=ne_t
        for jj = 1:16
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
        end
        nonequ(ti,:,ii*2-1:ii*2) = fliplr(temp) *200/2.9*0.86;
        ti=ti+1;
    end
    
    ti=1;
    for tt=equ_t
        for jj = 1:16
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
        end
        equili(ti,:,ii*2-1:ii*2) = fliplr(temp) *200/2.9*0.86;
        ti=ti+1;
    end
    

end

%% plot each condition in ppm in space

cond_ppm = target; %
cond_ppm = nonequ; %
cond_ppm = equili; %

ppms = squeeze(cond_ppm(1,:,:));
osa_check = checkerboard(1,8, nb*2);
osa_check = osa_check(:,1:end/2);
xx = [1:16];
yy = [1:6];
[X,Y] = meshgrid(xx,yy);
check_fill = osa_check*0;
xyv = [];

ii = 1;
tempv = ppms;%reshape(osa_foi,45,1);  %to fill in checkerboard pattern
tempx = X';
tempy = Y;
for yi = 1:1:size(osa_check,2)
    for xi = 1:1:size(osa_check,1)
        if osa_check(xi,yi)==1
            xyv = [xyv; tempx(xi), tempy(yi), tempv(ii)];
            check_fill(xi,yi) = tempv(ii);
            ii=ii+1;
        else
            check_fill(xi,yi) = 0;
        end
            
    end
end
figure()
imagesc(check_fill)

%% interpolation
inter = 66;  % to mm spacing
dxy = 1/inter;
[Xq,Yq] = meshgrid(1:dxy:size(check_fill,1), 1:dxy:size(check_fill,2));
F = scatteredInterpolant(xyv(:,1), xyv(:,2), xyv(:,3));
F.Method = 'natural';
vq1 = F(Xq,Yq)';

figure
imagesc(vq1)

%% if we want to use spline fit
% cov_wid = 10;
% vq1_coved = conv2(vq1, ones(cov_wid),'same')/cov_wid^2;%'valid');
% ppm2i = l1spline(vq1, 100, 1, 1, 10, 1e-5);
% % figure()
% % imagesc(vq1_coved)
% figure()
% imagesc(ppm2i)

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal comparison
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% check time series
figure()
c = jet(length(targ_t));
for tt = 1:length(targ_t)
plot(squeeze(target(tt,:,:)),squeeze(nonequ(tt,:,:)),'o','color',c(tt,:))
hold on
end
x = linspace(min(min(squeeze(target(tt,:,:)))),max(max(squeeze(target(tt,:,:)))));
y = linspace(min(min(squeeze(nonequ(tt,:,:)))),max(max(squeeze(nonequ(tt,:,:)))));
plot(x,y,'k--','linewidth',3); hold off

ylabel('non-equilibrium (w/ agar)')
% ylabel('equilibrium (w/ agar)')
xlabel('target (w/o agar)')


