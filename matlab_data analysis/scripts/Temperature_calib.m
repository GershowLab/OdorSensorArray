% Calibrate temperature
%%% read from TH sensors to verify that temperature does not fluctuate
%%% through recordings.

%%
osa_fname = '20220519174711_osa_cone_110mM_16_9_ml_600mlair.txt';  % for time seires
% osa_fname = '20230510162135_osa_22V_17osb.txt';
% osa_fname = '20230424191433_osa_odor_os_test_2000PID.txt';
% osa_fname = '20230526115103_osa_temp_test46off';
osb_nums = [7,1];
colors = ['k','r']; %['r','b'];
temp_time = [];
figure()
for oo = 1:2
    [Read, osbs, time_osa] = Read_OSA_TH(osa_fname);
    [data_h22, data_Et2, sample_time] = Read_single_OSB_TH(Read, osbs, time_osa, osb_nums(oo));
    plot(sample_time/1000/60, (data_h22-data_h22(:,1)*0+0)'*0.1,colors(oo))
    hold on
end
xlabel('time (minutes)')
ylabel('\Delta T (C)')
set(gca,'FontSize',20); set(gcf,'color','w');
% ylim([0,1.8])

%%
osa_fname = '20220406142406_osa_110mM_004Hz_21ml_400mlair.txt';  % for spatial pattern
[Read, osbs, time_osa] = Read_OSA_TH(osa_fname);

tt = 60*20;
% for tt = 1:10:size(data_h22,2)
    
osb_add = [7:-1:1];%[7,1];%
minvals = zeros(8,7);
for ii = 1:length(osb_add)
    [data_h22, data_Et2, sample_time] = Read_single_OSB_TH(Read, osbs, time_osa, osb_add(ii));
    
%     minv = min(data_h22');  %min readout
%     minv = data_h22(:,1);  %initial readout
    minv = data_h22(:,tt);  %some point in time
    minvals(:,ii) = (minv - data_h22(:,1)*1 +230*1)*0.1;  % reasonable to remove instantaneous offset
end
figure
imagesc([0:7].*1.5, [1:8].*1.5, minvals)
% imagesc(OSA_spatial_map(minvals))
ylabel('y (cm)')
xlabel('x (cm)')
set(gca,'FontSize',20); set(gcf,'color','w');
colorbar();
