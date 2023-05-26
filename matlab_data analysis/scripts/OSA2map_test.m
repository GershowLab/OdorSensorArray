%Construct odor landscape from OSA readout
clear
clc

run('/projects/LEIFER/Kevin/OdorSensorArray/pathdef.m')
%% load OSA data
dir_ = '/projects/LEIFER/Kevin/20211013_biased_110mM/';
dir_='/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
f_name = '20211013110856_osa_119mM_20ml_400ml_biased.txt';
f_name = '20220113122720_osa_110mM_20ml_10air_200ml_biased.txt';
f_name = '20220126142434_osa_11mM_15_20dil_air400ml_biased';
osa_fname = [dir_, f_name];
osa_table = readtable(osa_fname);

%% read OSA
[Read, osbs, time_osa] = Read_OSA(osa_fname);

%% adjust for single OSB
snaps = floor(length(time_osa)/16/7);  %snaps*16 index uses, the mod is ignored
OSA_read = {};
for tt = 1:snaps
    
minvals = [];
osb_add = [7:-1:1];%[6 7 5 4 2 3 1]; %
for ii = 1:7
    osb_num = osb_add(ii);
    [data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, osb_num);
    
%     minv = min(data_h22');  %min readout
%     minv = data_h22(:,1);  %initial readout
    minv = data_h22(:,tt);  %some point in time
    %%% attempt with ppm unit
%     minv = min(raw2ppm(data_h22(:,1),data_h22(:,tt)'));  %attempt with concentration mapping
%     minv = max(raw2ppm(repmat(data_h22(:,10),1,size(data_h22,2))',data_h22'));
%     minv = (raw2ppm(repmat(data_h22(:,1),1,size(data_h22,2))',data_h22'));

    minvals = [minvals  reshape(minv,8,2)];
    
end

OSA_read{tt} = minvals;  %cells with 16x7 OSA readout at time tt
end

%% read tensor
OSA_mat = cell2mat(OSA_read);
OSA_mat = reshape(OSA_mat, 8, 7*2, length(OSA_read));

%% smooth through time
flow_init = 2000;
OSA_2D = nanmean(OSA_mat(:, :, flow_init:2500), 3);  %selecting time for measure
OSA_init = nanmean(OSA_mat(:, :, 100:200), 3);  %selecting time for initiation
figure()
Mout = exp((OSA_init - OSA_2D)/512);
% Mout = OSA_2D;
imagesc(Mout)

%% smooth through space -- pre-process for grid
osa_im = imread('/projects/LEIFER/Kevin/Data_odor_flow_equ/20211013_biased_110mM/OAS_view.png');  %BETTER image processing to get SGP30 positions
xx = [25, 390, 760, 1130, 1505, 1880, 2255, 2620, 2985];
yy = [140, 430, 710, 985, 1260, 1550, 1825, 2100, 2375];
[X,Y] = meshgrid(xx,yy);
figure
imagesc(osa_im); hold on;
scatter(X(:), Y(:), 'k', 'LineWidth',3); hold off

osa_foi = Mout([3:7],3:11);  %sensor ID in the field of view   
check = checkerboard(1,9,size(osa_foi,2));
check = check(1:end/2,1:end/2);
check_fill = check;
xyv = [];
% for ii = 1:sum(sum(check))
%     if check(ii)==1
%         xyv = [xyv; X(ii), Y(ii), osa_foi(ii)];
%         check_fill(ii) = osa_foi(ii);
%     end    
% end
ii=1;
tempv = osa_foi;  %to fill in checkerboard pattern
tempx = X';
tempy = Y;
for yi = 1:size(check,2)
    for xi = 1:size(check,1)
        if check(xi,yi)==1
            if sum([1,11,21,31,41]==ii+1)  %%%need this!!
                ii = ii+2;
            else
                ii=ii+1;
            end
            xyv = [xyv; tempx(xi), tempy(yi), tempv(ii)];
            check_fill(xi,yi) = tempv(ii);
%             ii = ii+1;
        else
            check_fill(xi,yi) = 1;
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
vq1 = F(Xq,Yq);
%%
figure()
% plot3(xyv(:,1), xyv(:,2), xyv(:,3),'mo')
imagesc(flipud(fliplr(vq1'))); hold on
scatter(xyv(:,1), xyv(:,2), 'k', 'LineWidth',3); 
% hold on
% test = mesh(Xq,Yq,vq1);

%%
imwrite((vq1/max(vq1(:))*255), 'Landscape.jpeg','JPEG');
save('Landscape.mat','vq1');
save('OdorFx.mat','F');

%% full-OSA map interpolation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
osa_full = ppms;  %sensor ID in the field of view   
check = checkerboard(1, 8*2, 7*2);  %ful OSA sensors
check = check(1:end/2,1:end/2);
check_fill = (check);
xx = 1:size(osa_full,1);
yy = 1:size(osa_full,2);
[X,Y] = meshgrid(xx,yy);
xyv = [];
ii=1;
tempv = osa_full;  %to fill in checkerboard pattern
tempx = X';
tempy = Y;
for yi = 1:size(check,2)
    for xi = 1:size(check,1)
        if check(xi,yi)==1
%             if sum([1,11,21,31,41]==ii+1)  %%%need this!!
%                 ii = ii+2;
%             else
%                 ii=ii+1;
%             end
            xyv = [xyv; tempx(xi), tempy(yi), tempv(ii)];
            check_fill(xi,yi) = tempv(ii);
            ii = ii+1;
        else
            check_fill(xi,yi) = 1;
        end
            
    end
end
xyv(:,1) = flip(xyv(:,1)); %%dealing with image axis
figure()
imagesc(check_fill)

%%
[Xq,Yq] = meshgrid(1:0.3:size(osa_full,2), 1:0.1:size(osa_full,1));
[kk,id] = sort(xyv(:,1:2));
% Vq = interp2(xyv(kk(:,1),1), xyv(kk(:,2),2), xyv(kk(:,1),3) , Xq,Yq, 'cubic');
Vq = interp2(osa_full , Xq,Yq, 'cubic');
figure;
imagesc(Vq)
C = conv2(Vq,ones(15,15));
figure
imagesc(C)
%%
[Xq,Yq] = meshgrid(1:0.1:size(osa_full,1), 1:0.1:size(osa_full,2));
F = scatteredInterpolant(xyv(:,1), xyv(:,2), xyv(:,3));
F.Method = 'natural';
vq1 = F(Xq,Yq);
figure()
imagesc(vq1);
