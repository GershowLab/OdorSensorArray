% Agar effects
% showing agar affecting concentration in supplment

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022')
reldir = fullfile('odor_calibrate', '20221216115116_MFCPID_agar_effects.txt');

%% load file
filename = fullfile(datadir, reldir);

%% read MFC-PID
mfc_table = readtable( [filename] );  %ms timer | PID | MFC-command | MFC-read
time_mfc = mfc_table.Var1;
time_mfc = time_mfc-time_mfc(1);
PID = mfc_table.Var2;
MFC_com = mfc_table.Var3;
MFC_read = mfc_table.Var4;

%% raw plots
figure;
plot(MFC_read); hold on
plot(PID)

%%
wind = 64000:123100; cond='w/ agar'; % w/ agar
% wind = 122500:267000; cond='PE protocal'; % equ
% wind = 270900:285200; cond='w/o agar'; % w/o agar

%% real plot
% ppm = (PID(wind)-PID(wind(1))) * 200/2.9*0.86;  % ppm
ppm = (PID(wind)-0.15) * 200/2.9*0.86;  % ppm
mfc = MFC_com(wind) * 50/5;  %ml/min
time = [1:length(time_mfc(wind))]*20/1000;  % seconds

figure;
subplot(4,1,1:3)
plot(time,ppm,'LineWidth',3)
set(gca,'xtick',[]); ylabel('PID (ppm)'); set(gca,'Fontsize',20); ylim([-1, 50]); xlim([0, max(time)]);
title(cond)
subplot(414)
plot(time,mfc,'k','LineWidth',3)
xlabel('time (s)'); ylabel('MFC (ml/min)'); set(gca,'Fontsize',20); ylim([-1, 35]); xlim([0, max(time)])
set(gcf,'color','w');

