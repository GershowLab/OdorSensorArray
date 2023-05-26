%%% OSA_PID_map

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Temporal mapping calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load file
dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
% osa_fname = [dir_,'20211222165712_osa_004Hz_110mM_01_45mlMEK_400mlair.txt'];
% mfc_fname = [dir_,'20211222170221_MFCPID_004Hz_110mM_01_45mlMEK_400mlair.txt'];

osa_fname = [dir_,'20220127104523_osa_110mM_004Hz_45ml_400mlair.txt'];
mfc_fname = [dir_,'20220127105025_MFCPID_110mM_004Hz_45ml_400mlair.txt'];

%%% low MEK
% osa_fname = [dir_,'20220124131004_osa_11mM_004Hz_50ml_400mlair.txt'];
% mfc_fname = [dir_,'20220124131605_MFCPID_11mM_004Hz_50ml_400mlair.txt'];

% %%% new calibration 04.06.22
osa_fname = [dir_, '20220406142406_osa_110mM_004Hz_21ml_400mlair.txt'];
mfc_fname = [dir_, '20220406143122_MFCPID_110mM_004Hz_21ml_400mlair.txt'];
% 
% %%% test
% dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/';
% osa_fname = [dir_, '20200228194312_osa_002Hzramp.txt'];
% mfc_fname = [dir_, '20200228194211_MFCPID_002Hzramp.txt'];
% 
% %%% for flow map
% dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
% osa_fname = [dir_, '20220519154930_osa_110mM_004Hz_29ml_400mlair.txt'];
% mfc_fname = [dir_, '20220519155620_MFCPID_110mM_004Hz_29ml_400mlair.txt'];

%%% EtOH
% osa_fname = [dir_, '20220603125022_osa_EtOH_004Hz_45ml_400mlair.txt'];
% mfc_fname = [dir_, '20220603125633_MFCPID_EtOH_004Hz_45ml_400mlair.txt'];

%%% 071422
% osa_fname = [dir_, '20220714121740_osa_110mM_002Hz_400mlair.txt'];
% mfc_fname = [dir_, '20220714122255_MFCPID_110mM_002Hz_400mlair.txt'];

%%% 101122
% osa_fname = [dir_, '20221011144928_osa_110mM_002Hz_400mlair_long.txt'];
% mfc_fname = [dir_, '20221011145510_MFCPID_110mM_002Hz_400mlair_long.txt'];

%%% new: 04.03.23
osa_fname = [dir_, '20230403164714_osa_110mM_002Hz_400mlair.txt'];
mfc_fname = [dir_, '20230403170133_MFCPID_110mM_002Hz_400mlair.txt'];

%%% 2000 ppm PID
% osa_fname = [dir_, '20230424181439_osa_2000PID_002Hz_110mM_400air.txt'];
% mfc_fname = [dir_, '20230424182108_MFCPID_2000PID_002Hz_110mM_400air.txt'];

%%% other odor
% osa_fname = [dir_, '20230417155431_osa_EB_1to150_002Hz_600air.txt'];
% mfc_fname = [dir_, '20230417160110_MFCPID_EB_1to150_002Hz_600air.txt'];
% osa_fname = [dir_, '20230417183810_osa_Ben_1to250_002Hz_400air.txt'];
% mfc_fname = [dir_, '20230417184501_MFCPID_1to250_002Hz_400air.txt'];

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
osb_num = 5;
[data_h2, data_Et, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
sample_time = sample_time(sample_time<time_mfc(end));
[closest_time,closest_pos] = timealign(sample_time, time_mfc-time_mfc(1));
downsamp_mfc = MFC_read(closest_pos);
downsamp_pid = PID(closest_pos);
figure;plot(downsamp_mfc); hold on; plot(downsamp_pid)

%% test script
OS_num = 5;
init_offset = 500;  %remove first cycle for stability
end_offset = 1;
sens = data_h2(OS_num,init_offset:end-end_offset);
sens(isnan(sens))= nanmean(sens);
sens_ = -(sens-min(sens)); %flipping
[rr,lags] = xcorr(zscore(sens_), zscore(downsamp_pid(init_offset:end-end_offset)));
%( (sens-nanmean(sens))/nanstd(sens) , zscore(downsamp_pid) );  %cross-corr to find time delay
[~,loc] = max(rr);
delay = abs(lags(loc))+0;
% delay = 0;%235-20;  %for 1,1
figure(); plot(sens(1:end-delay), downsamp_pid(init_offset-1+delay+1:end-end_offset),'o')
figure(); plot(zscore(sens(1:end-delay))); hold on; plot(zscore(downsamp_pid(init_offset-1+delay+1:end-end_offset)))

%% plots SI
xx = sens(1:end-delay)';
yy = (downsamp_pid(init_offset-1+delay+1:end-end_offset)*200/2.9 - 1*0.2*200/2.9) *0.79;
f = fit(xx, yy, 'exp1');
p11 = predint(f,xx,0.95,'observation','off');

figure();
plot(f,xx,yy); hold on; plot(xx,p11,'m--')
legend({'Data','Fitted curve', 'Prediction intervals'},...
       'FontSize',8,'Location','northeast')
xlabel('DOS raw')
ylabel('ppm (PID)')
set(gcf,'color','w');
set(gca,'Fontsize',20); %ylim([0,200]);

%% figure SI
wind = 1:5400;%2000:3000;
figure()
subplot(312); plot(sens(wind)); ylabel('value (SGP30)'); xlim([9,length(wind)]); set(gca,'xtick',[],'Fontsize',20)
subplot(313); plot(downsamp_pid(wind) *200/2.9*0.86); ylabel('ppm (PID)'); xlim([9,length(wind)]); set(gca,'Fontsize',20);xlabel('time (s)')
subplot(311); plot(downsamp_mfc(wind) *10); ylabel('ml/min (MFC)'); xlim([9,length(wind)]); set(gca,'Fontsize',20); set(gcf,'color','w');set(gca,'xtick',[],'Fontsize',20)
%%
wind = 150:1200;
yy = downsamp_pid(wind)*200/2.9*10 %0.9;
xx = sens(wind-33)';
f = fit(xx, yy, 'exp1');
p11 = predint(f,xx,0.95,'observation','off');

figure();
plot(f,xx,yy); hold on; %plot(xx,p11,'m--')
legend({'Data','Fitted curve', 'Prediction intervals'},...
       'FontSize',20,'Location','northeast')
xlabel('value (SGP30)');
ylabel('ppm (PID)'); set(gca,'Fontsize',20); set(gcf,'color','w');

%% iterate through sensors

% OP_map = cell(7,16);  %cell that contains a vector of OSA-PID mapping for each sensor on each OSB
OP_map = struct('os_pid','f');
init_offset = 500;  %remove first cycle for stability
end_offset = 0;

osb_add = 7:-1:1;  %OSB address
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
%         if osb_num==1 && jj==4
%             delay = 0;  %hack for this OS
%         end
%         if osb_num==1 && jj==13
%             delay = 0;  %hack for this OS
%         end
        %%% store mapping data
        OP_map(ii,jj).os_pid = [sens(1:end-delay) ; downsamp_pid_j(init_offset-1+delay+1:end-end_offset)'];%%%%%%%%%%%%%%%%%%%%%%%
        
        %%% fitting the map
        xx = sens(1:end-delay)';
        yy = downsamp_pid_j(init_offset-1+delay+1:end-end_offset);
        f = fit(xx, yy, 'exp1');
        OP_map(ii,jj).f = f;
        
        
        %%% checking
%         plot(f,xx,yy)
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
title('a')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial mapping calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% mapping a cone with ppm
dir_ = '/projects/LEIFER/Kevin/Data_odor_flow_equ/20211013_biased_110mM/';
dir_='/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';

% f_name = '20211013110856_osa_119mM_20ml_400ml_bia'sed.txt';
f_name = '20220113122720_osa_110mM_20ml_10air_200ml_biased.txt';
% f_name = '20220126142434_osa_11mM_15_20dil_air400ml_biased';
osa_fname_cone = [dir_, f_name];
% osa_fname_cone = [dir_,'20211221132537_osa_cone_110mM_20_10_400mlair.txt'];
% osa_fname_cone = [dir_,'20211221144654_osa_cone_110mM_20_400mlair.txt'];
% osa_fname_cone = [dir_, '20220124114649_osa_11mM_15_20_dil_air400ml.txt'];

%%% cone
% osa_fname_cone = [dir_, '20220226153737_osa_cone_13dil_25MEK_9_13_400air.txt'];

% osa_fname_cone = [dir_, '20220324103954_osa_110mM_25_5ml_400air.txt'];

osa_fname_cone = [dir_, '20220406165408_osa_110_11mM_30MEK_400air.txt'];

% osa_fname_cone = [dir_, '20230403181244_osa_110_11mM_33MEK_400air.txt'];  % cone w/o gel
osa_fname_cone = [dir_, '20230403194241_osa_cone_gel_11mM_33MEK_400air.txt'];  % cone w/ gel
% osa_fname_cone = [dir_, '20230404102033_osa_cone_11mM_33MEK_400air.txt'];  % re-test w/o gel
% osa_fname_cone = [dir_, '20230412145310_osa_cone_noPE_11mM_33MEK_400air.txt'];  %wo PE
% osa_fname_cone = ['/projects/LEIFER/Kevin/Data_cone/20230410_GWN_naive_N2_cone_gel_11mM_35_400/20230410115555_osa_naive_N2_cone_gel_11mM_35MEK_400air.txt'];

% osa_fname_cone = [dir_, '20220519174711_osa_cone_110mM_16_9_ml_600mlair.txt'];
% osa_fname_cone = [dir_, '20220519183653_osa_inv_cone_110mM_18_ml_500mlair.txt'];
% osa_fname_cone = [dir_, '20220520161412_osa_drop_1100mM_BC.txt'];
% osa_fname_cone = [dir_, '20220524112248_osa_drop_1100mM_BCtests.txt'];
% 
% osa_fname_cone = [dir_, '20220601160153_osa_EtOH.txt'];
% osa_fname_cone = [dir_, '20220714140201_osa_biased_cone_11mM_33_ml_400air.txt'];
% osa_fname_cone = [dir_, '20221012165622_osa_drop_1100mM_45agar_inDI.txt'];

%%% other odor
% osa_fname_cone = [dir_, '20230417170954_osa_EB_cone_1to150_600air.txt'];
% osa_fname_cone = [dir_, '20230417194828_osa_Ben_cone_1to250_400air.txt'];
% osa_fname_cone = [dir_, '20230501170142_osa_EB_cone_1to150_400air.txt'];

[Read, osbs, time_osa] = Read_OSA(osa_fname_cone);
[data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, 7);
%%
tt = 1700;  %1700; 2800
TT = size(data_h22,2);  %length in time
sampt = zeros(3,361);  % for measurement through time
ti = 1;
figure();
for tt = 1100:5:2900 %1400:5:3200%:TT% 1500%300:10:2000;%

    c_ul = 1;  %use for confidance interval... 1 for lower and 2 for upper bound
    
osb_add = [7:-1:1];%[7,6,3,2,1];%
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
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt-0));  %ppm reading
        end
        %%% test with confidence interval of exp fit
%         f_temp = OP_map(ii,jj).f;
%         ci = confint(f_temp);
%         temp(jj) = ci(c_ul,1)*exp(ci(c_ul,2)*data_h22(jj,tt));
        
    end
    ppms(:,(ii)*2-1:(ii)*2) = fliplr(temp) *200/2.9*0.86 - 0.18*200/2.9*0.86;  %reshape and rescale with MEK coefficient
%     ppms(:,(ii)*2-1:(ii)*2) = fliplr(temp) *200/2.9*0.7;  % for Ethyl butyrate
    
end

sampt(:,ti) = ppms([1,3,5],5);
ti = ti+1;
end

% plot(sum(ppms,1),'-o');title(num2str(tt));  %check conservation of molecules
% hold on

ppms = ((ppms));
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
% imagesc(OSA_spatial_map(minvals))
% title(['MEK=20,air=300 ml/min, at time=',num2str(tt),'s'])

%% Convection diffusion
xC = ppms(3:4,:);
xC = reshape(xC,1,28);
yC = ppms(:,11:12); %ppms(:,5:6);%ppms(:,11:12);%
yC = reshape(yC',1,16);
figure;subplot(121); plot(xC,'-o'); xlabel('x-axis'); subplot(122); plot(yC,'-o'); xlabel('y-axis')

%%
xx = linspace(0,15,length(xC));
yy = linspace(-7,7,length(yC));
v = 0.0333; D = 0.08;
v = 0.5;

%%% x-axis
C_x = 25*D/v*exp(-v/D.*xx) + 140;
% C_x = 25*D/v*exp(-v/D.*xx) + 75;
figure; plot(xx,xC,'-o'); hold on; plot(xx,C_x); xlabel('x (cm)'); ylabel('ppm'); legend('data','model');
set(gca,'FontSize',20); set(gcf,'color','w');

%%% y-axis
xi = 11.5;  %the position of slice
Dy = D*(1 + 6.25^2/7.5);%/3.2; %%cuz five times the clean air around...(?)
C_y = max(yC)*exp(-yy.^2./(4*Dy*xi/v));
% C_y = 200/sqrt(4*pi*Dy*xi/v)*exp(-yy.^2./(4*Dy*xi/v));
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

%% try saving as new landscape function and image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% smooth through space -- pre-process for grid
Mout = ppms;
osa_im = imread('/projects/LEIFER/Kevin/Data_odor_flow_equ/20211013_biased_110mM/OAS_view.png');  %BETTER image processing to get SGP30 positions
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
% check(check==0) = -1; check(check==1)=0; check=check*-1;
check_fill = check*0;
xyv = [];
% for ii = 1:sum(sum(check))
%     if check(ii)==1
%         xyv = [xyv; X(ii), Y(ii), osa_foi(ii)];
%         check_fill(ii) = osa_foi(ii);
%     end    
% end
ii=0;
tempv = osa_foi;%reshape(osa_foi,45,1);  %to fill in checkerboard pattern
tempx = X';
tempy = Y;
for yi = 1:1:size(check,2)
    for xi = 1:1:size(check,1)
        if check(xi,yi)==1
%             if sum([1,11,21,31,41]==ii+1)  %%%need this!!
            if sum([5,15,25,35,45]==ii+1)  %%%need this!!
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
% xyv(:,1) = flip(xyv(:,1)); %%dealing with image axis
figure()
imagesc(check_fill)

%% 2D-interpolation (without model here)
[Xq,Yq] = meshgrid(1:size(osa_im,1), 1:size(osa_im,2));
F = scatteredInterpolant(xyv(:,1), xyv(:,2), xyv(:,3));
F.Method = 'natural';
vq1 = F(Xq,Yq)';
% vq1(vq1<=0) = 0.1;

%%
figure()
% plot3(xyv(:,1), xyv(:,2), xyv(:,3),'mo')
% imagesc((((flipud(fliplr(vq1))))))
imagesc(vq1)
hold on
% scatter(xx,yy);
scatter(xyv(:,1), xyv(:,2), 'k', 'LineWidth',3); 
% test = mesh(Xq,Yq,vq1);

%%
cov_wid = 2;
vq1_coved = conv2(vq1, ones(cov_wid),'same')/cov_wid^2/2;%'valid');
figure()
imagesc(vq1_coved)
hold on
scatter(xyv(:,1), xyv(:,2), 'k', 'LineWidth',3); 

%%
% imwrite((vq1/max(vq1(:))*255), 'Landscape.jpeg','JPEG');
% save('Landscape_cone_low.mat','vq1');
% save('OdorFx_cone_low.mat','F');

%% test with extrapolation of full OSA, then crop out the field of view (or model-based)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
osa_check = checkerboard(1,8, 7*2);
osa_check = osa_check(:,1:end/2);
xx = [1:16];
yy = [1:14];
[X,Y] = meshgrid(xx,yy);
check_fill = check*0;
xyv = [];

ii = 1;
tempv = rot90(ppms, 2);%reshape(osa_foi,45,1);  %to fill in checkerboard pattern
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

%%
pix2mm = 33.3;
dy_pix = 1/(pix2mm*(1.5/2));  %1/(pix2mm*mm_interval)
dx_pix = 1/(pix2mm*(1.));
[Xq,Yq] = meshgrid(1:dx_pix:size(check_fill,2), 1:dy_pix:size(check_fill,1));
F = scatteredInterpolant(xyv(:,2), xyv(:,1), xyv(:,3));
F.Method = 'natural';
vq1 = F(Xq,Yq);

%%
x_cm = 13;
y_cm = 12;
figure()
% plot3(xyv(:,1), xyv(:,2), xyv(:,3),'mo')
imagesc(linspace(0,x_cm,size(vq1,1)),linspace(0,y_cm,size(vq1,2)), (flipud(fliplr(vq1))))
hold on
% scatter(xx,yy);
% scatter(xyv(:,2)*1/dy_pix, xyv(:,1)*1/dx_pix, 'k', 'LineWidth',3);
% scatter(xyv(:,2)*1/(size(check_fill,2)/x_cm), xyv(:,1)*1/(size(check_fill,1)/y_cm), 'k', 'LineWidth',3);

%%
osa_model = vq1*0;
x = 1:size(osa_model,1);  %y-axis
for xx = 1:size(osa_model,2)
    y = vq1(:,xx);
%     f = fit(x.',y,'gauss1');
%     Yhat = feval(f, x);
    [mu_y,loc] = max(y);
    std_y = std(y);
    Yhat = 1/(2*pi*std_y^2)^0.5 * exp(-1/std_y^2 * (x - loc).^2);
    Yhat = Yhat/max(Yhat)*mu_y;
    osa_model(:,xx) = Yhat;
end
%%
figure
imagesc(osa_model)
set(gca,'XDir','reverse')

%% 2D convolution...
cov_wid = 33;%33*3;
vq1_coved = conv2(vq1, ones(cov_wid),'same')/sum(sum(ones(cov_wid)));%'valid');
figure()
imagesc((((flipud(fliplr(vq1_coved))))))
