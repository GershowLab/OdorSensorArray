%%% odor_flow_map

% code to preprocess data for:
%                             figure 1: calibration, odor profile, model
%                             SI-1: time traces and mapping
%                             figure 2: calibration and odor profile
%                             figure 3: calibration 
%                             figure 4: calibration 

% this is used to analyze raw concentration recordings, calibrate for
% sensors, then construct the odor landscapes for further fitting and
% plotting. Main files analyze are included in the data folder.

% Saved files can then be used in OdorFlow_f1.m for figure plots, as well
% as the OdorLandscape_fit.m for flow model comparisons.

% This script requires function to read from the OSA and function fitting
% toolbox that should be included in Matlab

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022'
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Temporal mapping calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load calibration data
dir = fullfile(datadir,'odor_calibrate');
%'/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/Code4fig/data/';

%%% for stable calibration to produce full array cone profile from 04.06.22
osa_fname = [dir, '/20220406142406_osa_110mM_004Hz_21ml_400mlair.txt'];
mfc_fname = [dir, '/20220406143122_MFCPID_110mM_004Hz_21ml_400mlair.txt'];

% %%% for long-term stability (SI plot) from 10.11.22
osa_fname = [dir, '/20221011144928_osa_110mM_002Hz_400mlair_long.txt'];
mfc_fname = [dir, '/20221011145510_MFCPID_110mM_002Hz_400mlair_long.txt'];

% % %%% for EtOH calibration from 06.03.22
% osa_fname = [dir, '/20220603125022_osa_EtOH_004Hz_45ml_400mlair.txt'];
% mfc_fname = [dir, '/20220603125633_MFCPID_EtOH_004Hz_45ml_400mlair.txt'];

% %%% for shallow and inverse cone profiles from 05.19.22
% osa_fname = [dir, '/20220519154930_osa_110mM_004Hz_29ml_400mlair.txt'];
% mfc_fname = [dir, '/20220519155620_MFCPID_110mM_004Hz_29ml_400mlair.txt'];

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
% delay = 0;%235-20;  % manually put in a delay if there is a better one
figure(); plot(sens(1:end-delay), downsamp_pid(init_offset-1+delay+1:end-end_offset),'o')
xlabel('OS (raw)'); ylabel('PID (V)');
figure(); plot(zscore(sens(1:end-delay))); hold on; plot(zscore(downsamp_pid(init_offset-1+delay+1:end-end_offset)))
xlabel('time (s)'); ylabel('normalized values'); legend({'OS','PID'})

%% plots SI
xx = sens(1:end-delay)';
yy = (downsamp_pid(init_offset-1+delay+1:end-end_offset)*200/2.9 - 0.1*200/2.9)*0.86;  %rescale to ppm, subtract the offset factor for PID baseline, and multiply coefficient
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

%% figure SI
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
dir_ = fullfile(datadir, 'odor_measure');
osa_fname_cone = [dir_, '/20220406165408_osa_110_11mM_30MEK_400air.txt'];

%%% for figure 2 EtOH profile
% osa_fname_cone = [dir_, '/20220601160153_osa_EtOH.txt'];

%%% for figure 2 shallow and inverse profiles
% osa_fname_cone = [dir_, '/20220519174711_osa_cone_110mM_16_9_ml_600mlair.txt'];  % shallow cone
% osa_fname_cone = [dir_, '/20220519183653_osa_inv_cone_110mM_18_ml_500mlair.txt'];  % inverse cone

%%% test reading to get matrix size
[Read, osbs, time_osa] = Read_OSA(osa_fname_cone);
[data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, 7);

%% plot concentration reading at a stable point
tt = 1500; %2000; % floor(size(data_h22,2)/2);  % view time-series to check stationary point in time
TT = size(data_h22,2);  % length in recording
figure();

% for tt = 200:10:TT% % used to visualize through time

% c_ul = 1;  %use for confidance interval... 1 for lower and 2 for upper bound
    
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
        if osb_add(ii)>4
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt-0));  %ppm reading
        else
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
        end
        
        %%% test with confidence interval of exp fit if it is very noisy
%         f_temp = OP_map(ii,jj).f;
%         ci = confint(f_temp);
%         temp(jj) = ci(c_ul,1)*exp(ci(c_ul,2)*data_h22(jj,tt));
        
    end
    ppms(:,(ii)*2-1:(ii)*2) = fliplr(temp) *200/2.9*0.86 - 0.15*200/2.9*0.86;  %reshape and rescale with MEK coefficient
    
end

imagesc(ppms);title(num2str(tt)); colorbar();
% pause();

% end

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

%% Visualize cross sections of the convection diffusion process
xC = ppms(3:4,:);
xC = reshape(xC,1,28);
yC = ppms(:,11:12); %ppms(:,5:6);%ppms(:,11:12);%
yC = reshape(yC',1,16);
figure;subplot(121); plot(xC,'-o'); xlabel('x-axis'); subplot(122); plot(yC,'-o'); xlabel('y-axis')

%% compare to a convection diffusion model with physical parameters
xx = linspace(0,15,length(xC));
yy = linspace(-7,7,length(yC));
D = 0.08;  % diffusion coefficient of butanone (cm^2/s)
v = 0.5;  % flow velocity along x-axis (cm/s)

%%% x-axis
C_x = max(xC)*D/v*exp(-v/D.*xx) + min(xC);
figure; plot(xx,xC,'-o'); hold on; plot(xx,C_x); xlabel('x (cm)'); ylabel('ppm'); legend('data','model');
set(gca,'FontSize',20); set(gcf,'color','w');

%%% y-axis
xi = 11.5;  %the position of slice
Dy = D*(1 + 6.25^2/7.5);  %% correcting for dispersion along the flow direction...
C_y = max(yC)*exp(-yy.^2./(4*Dy*xi/v));
figure; 
plot(yy,yC,'-o'); hold on; plot(yy,C_y); xlabel('y (cm)'); ylabel('ppm'); legend('data','model');
set(gca,'FontSize',20); set(gcf,'color','w');

%% formal loop
ccs = ['k','b','g','r'];
x_locs = [3:4; 5:6; 7:8; 11:12];
data_x_conc = zeros(length(ccs), 16);
model_x_conc = zeros(length(ccs), 16);
figure()
for ii = 1:length(ccs)
    yC = ppms(:,x_locs(ii,:));
    yC = reshape(yC',1,16);
    data_x_conc(ii,:) = yC;
    xi = 1*mean(x_locs(ii,:));
    yc_model = max(yC)*exp(-yy.^2./(4*Dy*xi/v));
    model_x_conc(ii,:) = yc_model;
    plot(yy,yC,'o','color',ccs(ii)); 
    hold on; plot(yy,yc_model,'color',ccs(ii)); 
    xlabel('y (cm)'); ylabel('ppm'); legend('data','model');
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make odor landscape in the field of view for chemotaxis plates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% smooth through space -- pre-process for grid
Mout = ppms;
imagedir = fullfile(dir, 'OAS_view.png');
osa_im = imread(imagedir);
%('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/Code4fig/data/OAS_view.png');  %BETTER image processing to get SGP30 positions
xx = [25, 390, 760, 1130, 1505, 1880, 2255, 2620, 2985];
yy = [140, 430, 710, 985, 1260, 1550, 1825, 2100, 2375];
[X,Y] = meshgrid(xx,yy);
figure
imagesc(osa_im); hold on;
scatter(X(:), Y(:), 'k', 'LineWidth',3); hold off

temp = rot90(Mout, 2);
osa_foi = temp(3:7,3:11);  %sensor ID in the field of view   
check = checkerboard(1,9,size(osa_foi,2));
check = check(1:end/2,1:end/2);
check_fill = check*0;
xyv = [];

ii=0;
tempv = osa_foi;%reshape(osa_foi,45,1);  %to fill in checkerboard pattern
tempx = X';
tempy = Y;
for yi = 1:1:size(check,2)
    for xi = 1:1:size(check,1)
        if check(xi,yi)==1
            if sum([5,15,25,35,45]==ii+1)  %%%need this for interleaved pattern!
                ii = ii+2;
            else
                ii=ii+1;
            end
            xyv = [xyv; tempx(xi), tempy(yi), tempv(ii)];
            check_fill(xi,yi) = tempv(ii);
        else
            check_fill(xi,yi) = 0;
        end
            
    end
end
figure()
imagesc(check_fill)

%% 2D-interpolation (without model here)
[Xq,Yq] = meshgrid(1:size(osa_im,1), 1:size(osa_im,2));
F = scatteredInterpolant(xyv(:,1), xyv(:,2), xyv(:,3));
F.Method = 'natural';
vq1 = F(Xq,Yq)';

%% vidualize with sensor location on top
figure()
imagesc(vq1)
hold on
scatter(xyv(:,1), xyv(:,2), 'k', 'LineWidth',3); 

%% a 2D smoothed version
cov_wid = 100;
vq1_coved = conv2(vq1, ones(cov_wid),'same')/cov_wid^2;%'valid');
figure()
imagesc(vq1_coved)
hold on
scatter(xyv(:,1), xyv(:,2), 'k', 'LineWidth',3); 

%% saving for chemotaxis analysis!
% imwrite((vq1/max(vq1(:))*255), 'Landscape.jpeg','JPEG');
% save('Landscape_cone_low.mat','vq1');
% save('OdorFx_cone_low.mat','F');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% test with extrapolation of full OSA (for latter use of model-based fitting)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% extract and interleave the full OSA
osa_check = checkerboard(1,8, 7*2);
osa_check = osa_check(:,1:end/2);
xx = [1:16];
yy = [1:14];
[X,Y] = meshgrid(xx,yy);
check_fill = osa_check*0;
xyv = [];

ii = 1;
tempv = ppms;  %to fill in checkerboard pattern
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

%% interpolate into physical space
pix2mm = 33.3;
dy_pix = 1/(pix2mm*(1.5/2));  %1/(pix2mm*mm_interval)
dx_pix = 1/(pix2mm*(1.));
[Xq,Yq] = meshgrid(1:dx_pix:size(check_fill,2), 1:dy_pix:size(check_fill,1));
F = scatteredInterpolant(xyv(:,2), xyv(:,1), xyv(:,3));
F.Method = 'natural';
vq1 = F(Xq,Yq);

%% visualize
x_cm = 13;
y_cm = 12;
figure()
imagesc(linspace(0,x_cm,size(vq1,1)),linspace(0,y_cm,size(vq1,2)), (flipud(fliplr(vq1))))
