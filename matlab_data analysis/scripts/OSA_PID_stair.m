%%% OSA_PID_stair

%% load file
dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
% osa_fname = [dir_,'20220209163638_osa_2_10_ml_110mM_400air.txt'];
% mfc_fname = [dir_,'20220209164142_MFCPID_2_10_ml_110mM_400air.txt'];

% osa_fname = [dir_,'20220224142730_osa_swap34_2_10_ml_110mM_400air.txt'];
% mfc_fname = [dir_,'20220224143513_MFCPID_swap34_2_10_ml_110mM_400air.txt'];
% osa_fname = [dir_, '20220211141304_osa_swap34_2_10_ml_110mM_400air.txt'];
% mfc_fname = [dir_, '20220211141843_MFCPID_swap34_2_10_ml_110mM_400air.txt'];

osa_fname = [dir_, '20220322150407_osa_110mM_steps'];
mfc_fname = [dir_, '20220322151412_MFCPID_110mM_steps'];

%% processing in time
[Read, osbs, time_osa] = Read_OSA(osa_fname);
mfc_table = readtable(mfc_fname);  %ms timer | PID | MFC-command | MFC-read
time_mfc = mfc_table.Var1;
PID_ = mfc_table.Var2;
MFC_com = mfc_table.Var3;
MFC_read_ = mfc_table.Var4;

%%% truncating valid window
start_both = max(time_osa(1), time_mfc(1));
end_both = min(time_osa(end), time_mfc(end));
start_mfc = find(time_mfc>=start_both); start_mfc = start_mfc(1);
start_osa = find(time_osa>=start_both); start_mfc = start_mfc(1);
end_mfc = find(time_mfc<=end_both); end_mfc = end_mfc(end);
end_osa = find(time_osa<=end_both); end_osa = end_osa(end);

Read = Read(start_osa:end_osa,:);
osbs = osbs(start_osa:end_osa);
MFC_read_ = MFC_read_(start_mfc:end_mfc);
pos = find(abs(diff(MFC_read_))>0.1);   %%% thresholding to remove blinks!
MFC_read_(pos) = MFC_read_(pos-2);  %%% replace with local neighbor?
MFC_read = MFC_read_;
PID_ = PID_(start_mfc:end_mfc);
pos = find(abs(diff(PID_))>0.1);   %%% thresholding to remove blinks!
PID_(pos) = PID_(pos-2);  %%% replace with local neighbor?
PID = PID_;
% [pks,pk_locs] = findpeaks(PID);  %%% remove sharp noisy measurements
% PID = pks;
time_mfc = time_mfc(start_mfc:end_mfc);

%%% down sampling to align
osb_num = 6; %5
[data_h2, data_Et, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
sample_time = sample_time(sample_time<time_mfc(end));
[closest_time,closest_pos] = timealign(sample_time, time_mfc-time_mfc(1));
downsamp_mfc = MFC_read(closest_pos);
downsamp_pid = PID(closest_pos);
figure;plot(downsamp_mfc); hold on; plot(downsamp_pid)

%% test script
[pks, pos] = findpeaks(abs(diff(downsamp_mfc)),'MinPeakDistance',100,'MinPeakHeight',0.05);
stair_points = [pos; length(downsamp_mfc)];%(2:12); %(2:5);%;
% stair_points = [1290  1570  1889  2270  2650  3025  3423  3794  4183  4752  5190];

window = 300;
OS_num = 4; %4
OS_raw = [];
PID_ppm = [];

for ii = 1:length(stair_points)
    OS_raw = [OS_raw  data_h2(OS_num, stair_points(ii)-window:stair_points(ii))];
    PID_ppm = [PID_ppm  downsamp_pid(stair_points(ii)-window:stair_points(ii))'];
end

figure;
plot(OS_raw, PID_ppm, 'o')

%% plotting example traces
figure
subplot(311)
plot(downsamp_mfc *50/5); set(gca,'xtick',[]);ylabel('MFC (ml/min)'); set(gca,'Fontsize',20); xlim([0, 5300]); ylim([0,20])
subplot(312)
plot(data_h2(OS_num,:)); set(gca,'xtick',[]);ylabel('OS (raw)'); set(gca,'Fontsize',20); xlim([0, 5300]);
subplot(313)
plot((downsamp_pid -0.05)*200/3.); xlabel('time (s)');ylabel('PID (ppm)'); set(gca,'Fontsize',20);  set(gcf,'color','w'); xlim([0, 5300]); ylim([0,110])

%% temporal profile check
[pks, pos] = findpeaks(max(0,(diff(downsamp_mfc))),'MinPeakDistance',100,'MinPeakHeight',0.05);
OS_step = [];
PID_step = [];
window = 300;
for ii = 1:length(pos)
    os_temp = data_h2(OS_num, pos(ii):pos(ii)+window);
    pid_temp = downsamp_pid(pos(ii):pos(ii)+window)';
    OS_step = [OS_step;  (os_temp-os_temp(1))/min(os_temp-os_temp(1))];
    PID_step = [PID_step;  (pid_temp-pid_temp(1))/max(pid_temp-pid_temp(1))];
end
figure;
plot(PID_step')
hold on
plot(OS_step')

%%
xx = OS_raw';
yy = (PID_ppm -0.05)'*200/2.9;
xnan = find(isnan(xx) == 1)';
ynan = find(isnan(yy) == 1)';
pos = [xnan, ynan];
xx(pos) = [];  yy(pos) = [];
f = fit(xx, yy, 'exp1');
p11 = predint(f,xx,0.95,'observation','off');

figure();
plot(f,xx,yy); hold on; %plot(xx,p11,'m--')
% legend({'Data','Fitted curve', 'Prediction intervals'},...
%        'FontSize',8,'Location','northeast')
xlabel('OS raw')
ylabel('PID (ppm)')
set(gcf,'color','w'); set(gca,'Fontsize',20)

%% iterate through sensors
figure;
OP_map = struct('os_pid','f');

osb_add = 7:-1:1;  %OSB address
for ii = 1:7
    %%% load each OSB
    osb_num = osb_add(ii);
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
    
    %%% align to PID
    sample_time = sample_time(sample_time<time_mfc(end));
    [closest_time,closest_pos] = timealign(sample_time, time_mfc-time_mfc(1));
    downsamp_pid_j = PID(closest_pos);
    downsamp_mfc_j = MFC_read(closest_pos);
    %%% test code for now
    [pks, pos] = findpeaks(abs(diff(downsamp_mfc_j)),'MinPeakDistance',100,'MinPeakHeight',0.05);
    stair_points = pos;%(3:12);
    
    %%% individual sensor!
    for jj = 1:16
        OS_num = jj;
        %%% get raw readings
        OS_raw = [];
        PID_ppm = [];
        for kk = 1:length(stair_points)
            OS_raw = [OS_raw  data_h22(OS_num, stair_points(kk)-window:stair_points(kk))];
            PID_ppm = [PID_ppm  downsamp_pid_j(stair_points(kk)-window:stair_points(kk))'];
        end
        
        %%% store mapping data
        OP_map(osb_add(ii),jj).os_pid = [OS_raw ; PID_ppm];
        
        %%% fitting the map
        xx = OS_raw';
        yy = PID_ppm';
        xnan = find(isnan(xx) == 1)';
        ynan = find(isnan(yy) == 1)';
        pos = [xnan, ynan];
        xx(pos) = [];  yy(pos) = [];
        f = fit(xx, yy, 'exp1');
        OP_map(osb_add(ii),jj).f = f;
        
        %%% checking
%         plot(f,xx,yy); hold on; plot(OS_raw, PID_ppm); hold off;
%         title(['OSB',num2str(osb_num),'OS',num2str(jj)])
%         pause()
        
    end
    
end

%% checking parameters of ppm map
pars_map = zeros(8,7*2);
for ii = 1:7
    %%% load each OSB
    osb_num = osb_add(ii);
    
    %%% individual sensor!
    temp = zeros(8,2);
    for jj = 1:16
        %%% exponential mapping function
        temp(jj) = OP_map(ii,jj).f.a;  %ppm reading
    end
    pars_map(:,ii*2-1:ii*2) = temp;
end
figure()
imagesc(pars_map)
ylabel('sensor rows')
xlabel('OSBs')
set(gca,'FontSize',20);
colorbar();
title('b')
