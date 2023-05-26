%%% simple_odor_flow

% simplest code to demonstrate sensor calibration and odor-landscape construction

% Please check the data sharing link for the raw .txt data, and include in
% a proper folder directory

% This script requires function to read from the OSA and function fitting
% toolbox that should be included in Matlab

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Temporal mapping calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load raw data
% for long-term calibration
osa_relpath = fullfile('odor_calibrate', '20221011144928_osa_110mM_002Hz_400mlair_long.txt');
mfc_relpath = fullfile('odor_calibrate', '20221011145510_MFCPID_110mM_002Hz_400mlair_long.txt');
osa_fname = fullfile(datadir,osa_relpath);
mfc_fname = fullfile(datadir,mfc_relpath);

%% processing in time
[Read, osbs, time_osa] = Read_OSA(osa_fname);
mfc_table = readtable(mfc_fname);  %ms timer | PID | MFC-command | MFC-read
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
osb_num = 4;
[data_h2, data_Et, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
sample_time = sample_time(sample_time<time_mfc(end));
[closest_time,closest_pos] = timealign(sample_time, time_mfc-time_mfc(1));
downsamp_mfc = MFC_read(closest_pos);
downsamp_pid = PID(closest_pos);
figure;plot(downsamp_mfc); hold on; plot(downsamp_pid)
xlabel('time (s)'); ylabel('volts'); legend({'MFC','PID'})

%% test script for on OSB
OS_num = 12;
init_offset = 1;  % remove first cycle if it is unstables
end_offset = 1;  % remove the last bit if recording went wrong
sens = data_h2(OS_num,init_offset:end-end_offset);
sens(isnan(sens))= nanmean(sens);
sens_ = -(sens-min(sens)); %flipping to better align
[rr,lags] = xcorr(zscore(sens_), zscore(downsamp_pid(init_offset:end-end_offset))); %cross-corr to find time delay
[~,loc] = max(rr);
delay = abs(lags(loc));
% delay = 0;  % manually put in a delay if there is a better one
figure(); plot(sens(1:end-delay), downsamp_pid(init_offset-1+delay+1:end-end_offset),'o')
xlabel('OS (raw)'); ylabel('PID (V)');
figure(); plot(zscore(sens(1:end-delay))); hold on; plot(zscore(downsamp_pid(init_offset-1+delay+1:end-end_offset)))
xlabel('time (s)'); ylabel('normalized values'); legend({'OS','PID'})

%% plots nonlinear calibration
xx = sens(1:end-delay)';
yy = (downsamp_pid(init_offset-1+delay+1:end-end_offset)*200/2.9 - 0.1*200/2.9)*0.86;  %rescale to ppm, subtract the offset factor for PID baseline, and multiply coefficient (0.86 for MEK)
f = fit(xx, yy, 'exp1');
p11 = predint(f,xx,0.95,'observation','off');

figure();
plot(f,xx,yy); hold on; plot(xx,p11,'m--')
legend({'Data','Fitted curve', 'Prediction intervals'},...
       'FontSize',8,'Location','northeast')
xlabel('DOS raw')
ylabel('ppm (PID)')
set(gcf,'color','w');
set(gca,'Fontsize',20); ylim([0,200]);

%% figure for time series
wind = 1:length(sens);
figure()
subplot(312); plot(sens(wind)); ylabel('value (SGP30)'); xlim([9,length(wind)]); set(gca,'xtick',[],'Fontsize',20)
subplot(313); plot(downsamp_pid(wind) *200/2.9*0.86); ylabel('ppm (PID)'); xlim([9,length(wind)]); set(gca,'Fontsize',20);xlabel('time (s)')
subplot(311); plot(downsamp_mfc(wind) *10); ylabel('ml/min (MFC)'); xlim([9,length(wind)]); set(gca,'Fontsize',20); set(gcf,'color','w');set(gca,'xtick',[],'Fontsize',20)

%% iterate through sensors
 
OP_map = struct('os_pid','f'); %cell that contains a vector of OSA-PID recording and fitted mapping for each sensor on each OSB
init_offset = 1;  %remove first cycle for stability
end_offset = 0;

osb_add = 7:-1:1;  %OSB address inverted
for ii = 1:7
    %%% load each OSB
    osb_num = osb_add(ii);
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
    
    %%% align to PID
    sample_time = sample_time(sample_time<time_mfc(end));
    [closest_time,closest_pos] = timealign(sample_time, time_mfc-time_mfc(1));
    downsamp_pid_j = PID(closest_pos);
    
    %%% individual sensor!
    for jj = 1:16
        %%% get raw readings
        sens = data_h22(jj,init_offset:end-end_offset);
        sens(isnan(sens))= nanmean(sens);
        sens_ = -(sens-min(sens)); %flipping
        
        %%% find peak in cross-correlation
        [rr,lags] = xcorr(zscore(sens_), zscore(downsamp_pid_j));
        [~,loc] = max(rr);
        delay = abs(lags(loc));
        
        %%% store mapping data
        OP_map(ii,jj).os_pid = [sens(1:end-delay) ; downsamp_pid_j(init_offset-1+delay+1:end-end_offset)'];
        
        %%% fitting the map
        xx = sens(1:end-delay)';
        yy = downsamp_pid_j(init_offset-1+delay+1:end-end_offset);
        f = fit(xx, yy, 'exp1');
        OP_map(ii,jj).f = f;    
        
        %%% checking by eye if needed
%         plot(f,xx,yy)
%         pause()
        
    end
    
end

%% checking parameters of ppm map
pars_map = zeros(8,7*2);
for ii = 1:7
    %%% load each OSB
    osb_num = osb_add(ii);
    
    %%% individual sensor
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
title('a')

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial mapping calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data for mapping a cone shape in ppm
%%% for figure 1 example cone profile
osa_cone_relpath = fullfile('odor_measure', '20220406165408_osa_110_11mM_30MEK_400air.txt');
osa_fname_cone = fullfile(datadir,osa_cone_relpath);

%%% test reading to get matrix size
[Read, osbs, time_osa] = Read_OSA(osa_fname_cone);
[data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, 7);

%% plot concentration reading at a stable point
tt = 1500;  % view time-series to check stationary point in time

osb_add = [7:-1:1];
minvals = zeros(8,7*2);
ppms = zeros(8,7*2);
for ii =1:length(osb_add)
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_add(ii));
    
    %%% raw data
    minv = data_h22(:,tt);  %some point in time
    minvals(:,ii*2-1:ii*2) = reshape(minv,8,2);
    
    %%% map to ppm
    temp = zeros(8,2);
    for jj = 1:16
        %%% exponential mapping function
        temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt-0));  %ppm reading
        
    end
    ppms(:,(ii)*2-1:(ii)*2) = fliplr(temp) *200/2.9*0.86 - 0.1*200/2.9*0.86;  %reshape and rescale with MEK coefficient
    
end


figure
imagesc(minvals)
ylabel('sensor rows')
xlabel('OSBs')
set(gca,'FontSize',20);
colorbar();
title('raw values')

figure
imagesc(ppms)
ylabel('sensor rows')
xlabel('OSBs')
set(gca,'FontSize',20);
colorbar();
title('ppm map')
set(gca,'FontSize',20); set(gcf,'color','w');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Visualization and smoothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% sensor grid plot
figure;
osa2hex(flipud(ppms));

%% smoothed plot
figure
osa2SplineInterp(flipud(ppms),1);
