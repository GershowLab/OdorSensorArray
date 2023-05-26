%Analysis for cone shape with differnet flow parameters

clear
clc
%% load data
% cones parameters and files

dir_ = '/projects/LEIFER/Kevin/OdorSensorArray/Cone_test';

f_names = {'20200227161248_osa_20MEK200air.txt','20200227155406_osa_20MEK400air.txt',...
           '20200227172520_osa_40MEK200air.txt','20200227170118_osa_40MEK400air.txt'};

flow_pars = {[1.33  13.3],[1.33  26.6],[2.66 13.3],[2.66  26.6]};
%{[20,200], [20,400],[40,200],[40,400]};


%% looping through flow parameters
%%%
figure
for ff = 1:4
%% read OSA
[Read, osbs, time_osa] = Read_OSA(f_names{ff});

%% adjust for single OSB
tt = 600;
minvals = [];
osb_add = [7:-1:1]; %[6 4 3 7 2 5];
for ii = 1:6 %7:-1:2  %
    osb_num = osb_add(ii);
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
    
%     minv = min(data_h22');  %min readout
%     minv = data_h22(:,1);  %initial readout
%     minv = data_h22(:,tt);  %some point in time
    %%% attempt with ppm unit
    minv = min(raw2ppm(data_h22(:,1),data_h22(:,tt)'));  %attempt with concentration mapping
%     minv = max(raw2ppm(repmat(data_h22(:,10),1,size(data_h22,2))',data_h22'));
%     minv = (raw2ppm(repmat(data_h22(:,1),1,size(data_h22,2))',data_h22'));

    minvals = [minvals  reshape(minv,8,2)];
    
end

subplot(2,2,ff)
% imagesc(OSA_spatial_map(minvals))
imagesc((minvals))
ylabel('sensor rows')
xlabel('sensor columns')
set(gca,'FontSize',20);
title(['odor=',num2str(flow_pars{ff}(1)),', air=',num2str(flow_pars{ff}(2)),'cm/min'])
colorbar()
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% sptail stability and BC
%% load and read
fnames = {'20200229211152_osa_30MEK300air.txt','20200229214655_osa__20MEK300airBC.txt'};%'20200229224132_osa__20MEK300airBC.txt'};
osb_nums = [7,1];
%% iterations
figure()
it = 1;
for oo = 1:2
    for ff = 1:2
        [Read, osbs, time_osa] = Read_OSA(fnames{ff});
        [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_nums(oo));
        subplot(2,2,it)
        plot(data_h22')
        it = it+1;
    end
end

%% for single dataset
osa_fname = '20200229211152_osa_30MEK300air.txt';
osb_nums = [6,1];
colors = ['r','b'];
figure()
for oo = 1:2
    [Read, osbs, time_osa] = Read_OSA(osa_fname);
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_nums(oo));
    plot(data_h22',colors(oo))
    hold on
end
%%
figure
tt = 1500;
% for tt = 1:10:size(data_h22,2)
    
osb_add = [7:-1:1];  %[7 5 6 4 2 3 1];%[7 1];  %
minvals = zeros(8,7*2);
for ii = 1:length(osb_add)
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_add(ii));
    
%     minv = min(data_h22');  %min readout
%     minv = data_h22(:,1);  %initial readout
    minv = data_h22(:,tt);  %some point in time
    %%% attempt with ppm unit
%     if ii == 2
%         minv = min(raw2ppm(data_h22(:,50)+1*10^3,data_h22(:,tt)'));  %attempt with concentration mapping
%     else
% % %         minv = min(raw2ppm(data_h22(:,50),data_h22(:,tt)'));  %attempt with concentration mapping
%     end
%     minv = max(raw2ppm(repmat(data_h22(:,1),1,size(data_h22,2))',data_h22'));
%     minv = (raw2ppm(repmat(data_h22(:,1),1,size(data_h22,2))',data_h22'));
%     minv = minv(30,:);

%     minvals = [minvals  reshape(minv,8,2)];
    minvals(:,ii*2-1:ii*2) = reshape(minv,8,2);
end
% figure
% imagesc(minvals)
imagesc(OSA_spatial_map(minvals))
ylabel('sensor rows')
xlabel('6 OSBs')
set(gca,'FontSize',20);
title(['MEK=20,air=300 ml/min, at time=',num2str(tt),'s'])
colorbar();
% pause();
% end