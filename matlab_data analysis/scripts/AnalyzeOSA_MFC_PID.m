%Amalyze OSA-MFC-PID
clear
clc
%% load data
dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID';
% dir_ = 'C:\Users\Lamp\Downloads\Github\LabVIEW_LJUD\Examples\U3\';
% dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';

%%%quick analysis
osa_fname = [dir_,'20211221132537_osa_cone_110mM_20_10_400mlair.txt'];
mfc_fname = [dir_,'20211221121520_MFCPID_005Hz_110mM_01_50mlMEK_400mlair.txt'];

%%%ramping
% osa_fname = '20200211181102_osa_Ramp002Hz.txt';
% mfc_fname = '20200211180942_MFCPID_Ramp002Hz.txt';
% osa_fname = '20200211183949_osa_Ramp004Hz.txt';
% mfc_fname = '20200211183901_MFCPID_Ramp004Hz.txt';
% osa_fname = '20200211185703_osa_Ramp008Hz.txt';
% mfc_fname = '20200211185622_MFCPID_Ramp008Hz.txt';

% osa_fname = '20200228190116_osa_008Hzramp.txt';
% mfc_fname = '20200228190012_MFCPID_008Hzramp.txt';
% osa_fname = '20200228192400_osa_004Hzramp.txt';
% mfc_fname = '20200228192305_MFCPID_004Hzramp.txt';
% osa_fname = '20200228194312_osa_002Hzramp.txt';
% mfc_fname = '20200228194211_MFCPID_002Hzramp.txt';

%%%stepping
% osa_fname = '20200212162428_osa_4steps.txt';
% mfc_fname = '20200212161703_MFCPID_4steps.txt';
% osa_fname = '20200212164237_osa_4steps2.txt';
% mfc_fname = '20200212164149_MFCPID_4steps2.txt';

% osa_fname = '20200228201022_osa_steps.txt';
% mfc_fname = '20200228200830_MFCPID_steps.txt';

%%%spatial
% osa_fname = '20200214143534_osa_spatialtest.txt';
% mfc_fname = '20200214143355_MFCPID_spatialtest.txt';
% osa_fname = '20200304171614_osa_20MEK11mM300air_woP.txt';
% mfc_fname = '20200304171545_MFCPID_20MEK11mM300air_woP.txt';
% mfc_fname = '20200310154342_MFCPID_10MEK110mM20air_300air.txt';
% osa_fname = '20200310154445_osa_10MEK110mM20air_300air.txt';
% mfc_fname = '20200310161847_MFCPID_10MEK110mM20air_300air_BC.txt';
% osa_fname = '20200310162009_osa_10MEK110mM20air_300air_BC.txt';
% mfc_fname = '20200311132958_MFCPID_30MEK110mM300air.txt';
% osa_fname = '20200311133139_osa_30MEK110mM300air.txt';
% mfc_fname = '20200311141435_MFCPID_10MEK110mM20air300air.txt';
% osa_fname = '20200311141504_osa_10MEK110mM20air300air.txt';

%%%swapping OSBs
% osa_fname = '20200214152351_osa_preswap_004Hz.txt';
% mfc_fname = '20200214152314_MFCPID_preswap_004Hz.txt';
% osa_fname = '20200214160417_osa_swaped_004Hz.txt';
% mfc_fname = '20200214160257_MFCPID_swaped_004Hz.txt';

%%%long-term recordings
% osa_fname = '20200222_osa_4';

%% read OSA
% osa_fname = '20200227151032_osa_OSoff.txt';
% osa_table = readtable(osa_fname);
% read_pos = find(osa_table.code==2);  %code: 0 for setting, 1 for odor, 2 for temperature
% time_osa = osa_table.ms_timer(read_pos);   %ms clock
% valid = osa_table.valid(read_pos);  %validity of the reading
% invalid = find(valid==0);
% osbs = osa_table.osb_index(read_pos);  %OSB index
% allread = [osa_table.data_1  osa_table.data_2];  %raw readings
% Read = allread(read_pos,:);
% Read(invalid,:) = NaN;

%%
[Read, osbs, time_osa] = Read_OSA(osa_fname);

%% adjust for single OSB
% osb_num = 4;
% pruned_size = find(osbs==osb_num);
% pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
% data_h2 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
% data_Et = reshape(Read(pruned_osb_num,2),16,[]);
% sample_time = reshape(time_osa(pruned_osb_num),16,[]);
% sample_time = sample_time(1,:)-sample_time(1,1);
osb_num = 7;
[data_h2, data_Et, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);


%% read MFC-PID
% mfc_fname = '20200303122130_PID_newplate_saturation.txt';
% mfc_fname = '20200303120117_PID_newplate.txt';
% mfc_fname = '20200303113634_PID_woP.txt';
% mfc_fname = '20200303153030_MFCPID_backwoplate.txt';
% mfc_fname = '20200303155335_PID_backwplate.txt';

% mfc_fname = '20200304142659_MFCPID_20MEK110mM300air_woP.txt';
% mfc_fname = '20200304150244_MFCPID_20MEK110mM300air_wP.txt';

% mfc_fname = '20200304184624_MFCPID_20MEK11mM300air_backwoP.txt';
% mfc_fname = '20200304174126_MFCPID_20MEK110mM11mM300air_wP.txt';

% mfc_fname = '20200306160040_MFCPID_equilibrate.txt';
% mfc_fname = '20200306170705_MFCPID_equilibrate2.txt';
% mfc_fname = '20200306183926_MFCPID_back_woP.txt';

% mfc_fname = '20200310150056_MFCPID_10MEK110mM40air_400air.txt';

mfc_table = readtable(mfc_fname);  %ms timer | PID | MFC-command | MFC-read
time_mfc = mfc_table.Var1;
time_mfc = time_mfc-time_mfc(1);
PID = mfc_table.Var2;
MFC_com = mfc_table.Var3;
MFC_read = mfc_table.Var4;
sample_time = sample_time(sample_time<time_mfc(end));


%% %%%%%
%% visualization
%% %%%%%
%% plotting for single OSB
figure;
subplot(1,2,1);
plot(sample_time,(data_h2(1:8,:))','b'); hold on;
plot(sample_time,(data_h2(9:16,:))','r'); hold off;
title('raw h2');
set(gca,'FontSize',20); xlabel('time (s)');
subplot(1,2,2);
plot(sample_time,data_Et(1:8,:)','b'); hold on;
plot(sample_time,data_Et(9:16,:)','r'); hold off;
title('raw EtOH');
set(gca,'FontSize',20); xlabel('time (s)');

%plotting for MFC-PID readout
figure
plot(time_mfc,MFC_com)
hold on
plot(time_mfc,MFC_read)

%%% down-sample MFC for comparison
[closest_time,closest_pos] = timealign(sample_time, time_mfc);
downsamp_mfc = MFC_read(closest_pos);
downsamp_pid = PID(closest_pos);
%% scatter plot: scanning
% figure
% for ii = 1:150
%     shifted = ii;
%     sgpnum = 1:16;
%     for ss = 1:length(sgpnum)
% %         scatter(data_h2(sgpnum(ss),shifted+1:end), downsamp_mfc(1:end-shifted)')  %need a loop heree
%         scatter(downsamp_pid(shifted+1:end), downsamp_mfc(1:end-shifted)')
%         hold on
%     end
%     hold off
%     title(num2str(ii))
%     pause()
% end

%% just MFC2PID map
% figure()
% shifted = 45;
% plot(downsamp_mfc(1:end-shifted)', downsamp_pid(shifted+1:end),'o')
% ylabel('PID voltage')
% xlabel('MFC voltage')
% set(gca,'FontSize',20);
% title('MFC vs. PID')

%% scatter plots: sensor or cycles
% figure
% shifted = 15;
% sensors = [8,10,12];
% for d = 1:length(sensors)
%     dd = sensors(d);
%     scatter(downsamp_mfc(1:end-shifted)', data_h2(dd,shifted+1:end)) 
%     hold on
% end

figure
shifted = 15;
sensors = [1 6 11];
Legend=cell(length(sensors*2),1);
count = 1;
mfc_read = downsamp_mfc(1:end);
for d = 1:length(sensors)
    dd = sensors(d);
%     fst_mfc = mfc_read(1:end/2);
%     snd_mfc = mfc_read(end/2:end);
%     fst_osa = data_h2(:,1:end/2);
%     snd_osa = data_h2(:,end/2:end);
    fst_mfc = mfc_read(284:284+250);
    snd_mfc = mfc_read(533:533+250);
    fst_osa = data_h2(:,284:284+250);
    snd_osa = data_h2(:,533:533+250);
    %%%first cycle
%     plot(fst_mfc(1:end-shifted)',fst_osa(dd,shifted+1:end),'Linewidth',2) %raw
    plot(fst_mfc(1:end-shifted)', raw2ppm(data_h2(dd,10),fst_osa(dd,shifted+1:end)),'Linewidth',2) %ppm
    %%%scatter plot
    Legend{count}=strcat('S', num2str(dd),' C1'); count = count + 1;
    hold on
    %%%second cycle
%     plot(snd_mfc(1:end-shifted)', snd_osa(dd,shifted+1:end),'Linewidth',2)  %raw
    plot(snd_mfc(1:end-shifted)', raw2ppm(data_h2(dd,1),snd_osa(dd,shifted+1:end)),'Linewidth',2)  %ppm
    Legend{count}=strcat('S', num2str(dd),' C2'); count = count + 1;
end
hold off
set(gca,'FontSize',20);
title('SGP30 vs. MFC')
ylabel('ppm')
xlabel('MFC voltage')
legend(Legend)

%% double-y plot
figure
dd = [1 6 11];
yyaxis left
% plot(sample_time,(data_h2(1:8,:))','b'); hold on;
% plot(sample_time,(data_h2(9:16,:))','r'); hold off;
plot(sample_time/1000,raw2ppm(data_h2(dd,100),data_h2(dd,:)),'b-','Linewidth',2)
ylabel('raw readings')
yyaxis right
plot(time_mfc/1000,MFC_com); hold on;
plot(time_mfc/1000,MFC_read); hold on;
plot(time_mfc/1000,PID); hold off;
ylabel('voltage read (MFC_{command},MFC_{read},PID)')
title('raw h2 (T_{ramp}=125s)');
set(gca,'FontSize',20); xlabel('time (s)');

%% step vs. ramp
% timing_st = [4 3 2 1]*120;
% step_res = steps(:,timing_st);  %sensors x 4 steps (from step exp with steps = data_h2)
% timing_ra = [250 280 308 336]+shifted;
% timing_ra = [461 519 577 631]+20;
% timing_ra = [270 284 299 313] + 20;
% ramp_res = data_h2(:,timing_ra);
% plot(step_res','bo')
% hold on
% plot(ramp_res','ro')
% set(gca,'Fontsize',20); xlabel('concentration'); ylabel('raw H2');

%% SGP identity
figure
cmap = colormap(jet(16));
Legend=cell(16,1);
for ii = 1:16
    plot(sample_time/1000,raw2ppm(data_h2(ii,100)',data_h2(ii,:)'), 'Color',cmap(ii,:),'LineWidth',2); hold on
%     plot(sample_time/1000,(data_h2(ii,:)'), 'Color',cmap(ii,:),'LineWidth',2); hold on
    Legend{ii} = strcat('SGP# ',num2str(ii));
end
hold off
set(gca,'FontSize',20); 
xlabel('time (s)'); ylabel('ppm')
% xlabel('time (s)'); ylabel('raw H2')
legend(Legend)

%% plot across OSB
figure
osbnums = [7 6 5 4 2 3 1];%[6 7 5 4 2 3];%7:-1:2;%
for ii = 1:7%7:-1:2
    pruned_size = find(osbs==osbnums(ii));
    pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
    data_h22 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
    data_Et2 = reshape(Read(pruned_osb_num,2),16,[]);
    sample_time2 = reshape(time_osa(pruned_osb_num),16,[]);
    sample_time2 = sample_time2(1,:)-sample_time2(1,1);
    
    %subplot(6,1,ii-1)
    subplot(7,1,length(osbnums)+1-ii)
%     plot(sample_time2,data_h22(1:8,:)','b'); hold on;
%     plot(sample_time2,data_h22(9:16,:)','r'); hold off;
    plot(sample_time2(1:end/2),data_h22(:,1:end/2)','b'); hold off;
    set(gca,'xtick',[])
    set(gca,'ytick',[])
    set(gca,'FontSize',20); %xlabel('time (s)');
    set(gca,'LooseInset',get(gca,'TightInset'))
end

%% normalize to peak for flow rate estimation
sgpnum = 2;
figure
cmap = colormap(jet(6));
osbnums = 7:-1:1;%[7 6 5 4 2 3 1];%[6 7 5 4 2 3];%7:-1:2;
for ii = 1:7
    pruned_size = find(osbs==osbnums(ii));
    pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
    data_h22 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
    data_Et2 = reshape(Read(pruned_osb_num,2),16,[]);
    sample_time2 = reshape(time_osa(pruned_osb_num),16,[]);
    sample_time2 = sample_time2(1,:)-sample_time2(1,1);
    
    plot(sample_time2/1000,data_h22(sgpnum,:)'./min(data_h22(sgpnum,:)), 'Color',cmap(ii,:),'LineWidth',2); hold on;

end
hold off
set(gca,'FontSize',20); 
xlabel('time (s)');

%% calculate speed distribution
osbnums = [6 7 5 4 2 3];
speeds = zeros(1,16);  %OSB by sensors
for ss = 1:length(speeds)
    pruned_size = find(osbs==6);
    pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
    data_h22 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
    [~,fst_peak_pos] = min(data_h22(ss,end/2:end));
    pruned_size = find(osbs==3);
    pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
    data_h22 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
    [~,snd_peak_pos] = min(data_h22(ss,end/2:end));
    sample_time2 = reshape(time_osa(pruned_osb_num),16,[]);
    sample_time2 = sample_time2(1,:)-sample_time2(1,1);
    
    speeds(ss) = 100./(sample_time2(snd_peak_pos)-sample_time2(fst_peak_pos))*1000;
end

figure;
imagesc(fliplr(reshape(speeds,8,2)))

%% min/inital/ending/timing values through time, for whole OSA
tt = 100;
timeaverage = {};
kk = 1;
for tt = 1:1:500
    minvals = [];
osb_add = [7:-1:1]; %[7 1]; %[6 4 3 7 2 5];%[6 7 5 4 2 3];%[7 4 2 6 3 5];
for ii = 1:7 %7:-1:2  %
    pruned_size = find(osbs== osb_add(ii));
%     pruned_size = find(osbs== ii);
    pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
    data_h22 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
    data_Et2 = reshape(Read(pruned_osb_num,2),16,[]);
    
%     minv = min(data_h22');  %min readout
%     minv = data_h22(:,1);  %initial readout
    minv = data_h22(:,tt);  %some point in time
    %%% attempt with ppm unit
%     minv = (raw2ppm(data_h22(:,150),data_h22(:,tt)));  %attempt with concentration mapping
%     minv = max(raw2ppm(repmat(data_h22(:,1),1,size(data_h22,2))',data_h22'));
%     minv = (raw2ppm(repmat(data_h22(:,1),1,size(data_h22,2))',data_h22(:,tt)'));
%     minv = minv(30,:);

    minvals = [minvals  reshape(minv,8,2)];
    
end

timeaverage{kk} = minvals;
kk = kk+1;
end
figure
imagesc(minvals)
ylabel('sensor rows')
xlabel('6 OSBs')
set(gca,'FontSize',20);
title('min raw H2 (T_{ramp}=250s)')

figure
time_map = cell2mat(timeaverage);
time_map = reshape(time_map,8,14,kk-1);
time_map = permute(time_map, [3 1 2]); %time by row by column
% imagesc(mean(time_map,3))
imagesc(squeeze(std(time_map))./squeeze(mean(time_map,1)))
ylabel('sensor rows')
xlabel('6 OSBs')
set(gca,'FontSize',20);
title('min raw H2 (T_{ramp}=250s)')
% pause();
% end
%% for w/o plate formate
figure
minvals_wop = [minvals(:,1:2) zeros(8,5*2)*NaN  minvals(:,3:4)];
imagesc(minvals_wop)
ylabel('sensor rows')
xlabel('6 OSBs')
set(gca,'FontSize',20);
title('min raw H2 (T_{ramp}=250s)')

%% interpolated map
MAP = OSA_spatial_map(minvals);
figure;imagesc(MAP)
title('interpolated signal map')
set(gca,'FontSize',20);
xlabel('6 OSBs')
ylabel('sensor rows')

%%
%% long-term stability
% figure
% for ii = 1:4
%     osa_fname = ['20200222_osa_', num2str(ii), '.txt'];
%     osa_table = readtable(osa_fname);
%     read_pos = find(osa_table.code==1);  %code: 0 for setting, 1 for odor, 2 for temperature
%     time_osa = osa_table.ms_timer(read_pos);   %ms clock
%     valid = osa_table.valid(read_pos);  %validity of the reading
%     invalid = find(valid==0);
%     osbs = osa_table.osb_index(read_pos);  %OSB index
%     allread = [osa_table.data_1  osa_table.data_2];  %raw readings
%     Read = allread(read_pos,:);
%     Read(invalid,:) = NaN;
%     osb_num = 5;
%     pruned_size = find(osbs==osb_num);
%     pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),16));  %remove the last few less than 16 that might be due to termination of recording
%     data_h2 = reshape(Read(pruned_osb_num,1),16,[]);  %channel by time (16 X seconds)
%     data_Et = reshape(Read(pruned_osb_num,2),16,[]);
%     sample_time = reshape(time_osa(pruned_osb_num),16,[]);
%     sample_time = sample_time(1,:)-sample_time(1,1);
%     
%     subplot(1,4,ii)
%     plot(sample_time/1000,data_h2','b')
%     set(gca,'FontSize',20); xlabel('time (s)'); ylabel('raw H2');
%     axis([ 0, 600, [1.36,1.43]*10000])
% end

%% just for MFC-PID calibration
% fname = '/projects/LEIFER/Kevin/OdorSensorArray/20200228151838_PID_004Hz_55mM_new.txt';
% mfc_table = readtable(fname);  %ms timer | PID | MFC-command | MFC-read
% time_mfc = mfc_table.Var1;
% time_mfc = [time_mfc-time_mfc(1)]/1000;
% PID = mfc_table.Var2;
% MFC_com = mfc_table.Var3;
% MFC_read = mfc_table.Var4;
% 
% figure
% plot(time_mfc,MFC_com)
% hold on
% plot(time_mfc,MFC_read)
% plot(time_mfc,PID)
% hold off
% xlabel('time (s)'); ylabel('Voltage'); 
