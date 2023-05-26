%Droplet_mov
% to create supplmentary movie for agar evolution

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022')
%% mapping a cone with ppm
% dir_='/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
reldir = fullfile(datadir,'odor_calibrate');
osa_fname_cone = [reldir, '/20220524175045_osa_drop_1100mM_45asagar.txt'];
osa_fname_cone = [reldir, '/20221012165622_osa_drop_1100mM_45agar_inDI.txt'];
osa_fname_cone = [reldir, '/20221012104514_osa_drop_1100mM_inDI2.txt'];

[Read, osbs, time_osa] = Read_OSA(osa_fname_cone);
[data_h22, data_Et2, sample_time] = Read_single_OSB(Read, osbs, time_osa, 1);
%%
TT = size(data_h22,2);  %length in tim
startt = 330; %360

figure;
% vidfile = VideoWriter('droplet_agar45_movie.avi');
% vidfile.Quality = 95;
% vidfile.FrameRate = 0.5;
% open(vidfile);

time_wind = startt:1:TT;
avg_but = zeros(1,length(time_wind));
rec_but = zeros(3,length(time_wind));
for i = 70+0%1:length(time_wind)

    tt = time_wind(i); 
    osb_add = [7:-1:1];%  for full OSA
%     osb_add = [7,6,3,2,1];%  for 4,5 OSB swapped as agar condition
    minvals = zeros(8,7*2);
    ppms = ones(8,7*2)*NaN;
    
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
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt-33));  %ppm reading  -33
        else
            temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
        end
        
    end
    ppms(:,osb_add(ii)*2-1:osb_add(ii)*2) = (temp) *200/2.9*0.86 - 0.15*200/2.9*0.86;  %reshape and rescale with MEK coefficient
    
    
end

ppms = flipud(fliplr(ppms)); 
avg_but(i) = mean(mean(ppms(:,1:7)));
rec_but(:,i) = [ppms(4,7), ppms(4,10), ppms(4,14)];

% imagesc(ppms);title(num2str(tt)); colorbar();
osa2hex(ppms); title([num2str(tt),'s']); 
c=colormap; %get colormap
colormap([.2 .2 .2; c]) %specify NaN color
% colorbar(); caxis([1 200])
% pause();

%     drawnow
%     F = getframe(gcf); 
%     writeVideo(vidfile,F);
    
end
% close(vidfile)

% % % save('droplet_conditions.mat','drop_ppm_wa_init','drop_ppm_wa_3min','drop_ppm_wo_init','drop_ppm_wo_3min');
%% example plot for conditions (w/ or w/o agar at t0 and t180)
% load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/droplet_conditions.mat')
load([fullfile(datadir,'data_for_plots','droplet_conditions.mat')])
figure()
% subplot(2,2,1); 
% osa2hex(drop_ppm_wa_init);colorbar(); caxis([1 250])
% subplot(2,2,2); 
% osa2hex(drop_ppm_wa_3min);colorbar(); caxis([1 150])
% subplot(2,2,3); 
% osa2hex(drop_ppm_wo_init);colorbar(); caxis([1 250])
% subplot(2,2,4); 
osa2hex(drop_ppm_wo_3min);colorbar(); caxis([1 150])

%% side-by side comparison
% dir_='/projects/LEIFER/Kevin/OdorSensorArray/OSB_MFC_PID/OSA_calibration/';
% osa_fname_cone = [datadir, '/20220524175045_osa_drop_1100mM_45asagar.txt'];
% [Read_wi, osbs_wi, time_osa_wi] = Read_OSA(osa_fname_cone);
% osa_fname_cone = [datadir, '/20221012104514_osa_drop_1100mM_inDI2.txt'];
% [Read_wo, osbs_wo, time_osa_wo] = Read_OSA(osa_fname_cone);
% 
% onset_wo = 350;
% onset_wi = 384;
% time_wind_wo = [onset_wo-20:2:onset_wo+180];
% time_wind_wi = [onset_wi-20:2:onset_wi+180];
% 
% figure;
% vidfile = VideoWriter('droplet_comparison.avi');
% vidfile.Quality = 95;
% vidfile.FrameRate = 0.5;
% open(vidfile);
% 
% for i = 1:length(time_wind_wo)
% 
%     %%% for without agar
% %     subplot(121)
%     tl = tiledlayout(1,2);
%     tl.TileSpacing = 'compact';
%     tl.Padding = 'compact';
%     nexttile
%     
%     tt = time_wind_wo(i); 
%     osb_add = [7:-1:1];%
%     ppms = ones(8,7*2)*NaN;
%     
%     for ii =1:length(osb_add)
%         [data_h22, data_Et2, sample_time] = Read_single_OSB(Read_wo, osbs_wo, time_osa_wo, osb_add(ii));
% 
%         %%% map to ppm
%         temp = zeros(8,2);
%         for jj = 1:16
%             %%% exponential mapping function
%             if osb_add(ii)>4
%                 temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt-33));  %ppm reading  -33
%             else
%                 temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
%             end
% 
%         end
%         ppms(:,(ii)*2-1:(ii)*2) = fliplr(temp) *200/2.9*0.86 - 0.2*200/2.9*0.86;  %reshape and rescale with MEK coefficient
% 
% 
%     end
%     
%     ppms = flipud(ppms); 
%     osa2hex(ppms); title(['w/o agar ',num2str(tt-onset_wo),'s']); colorbar(); caxis([1 200])
% 
%     %%% for with agar
% %     subplot(122)
%     nexttile
%     
%     tt = time_wind_wi(i); 
%     osb_add = [7,6,3,2,1];%
%     ppms = ones(8,7*2)*NaN;
%     
%     for ii =1:length(osb_add)
%         [data_h22, data_Et2, sample_time] = Read_single_OSB(Read_wi, osbs_wi, time_osa_wi, osb_add(ii));
% 
%         %%% map to ppm
%         temp = zeros(8,2);
%         for jj = 1:16
%             %%% exponential mapping function
%             if osb_add(ii)>4
%                 temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt-33));  %ppm reading  -33
%             else
%                 temp(jj) = OP_map(ii,jj).f(data_h22(jj,tt));  %ppm reading
%             end
% 
%         end
%         ppms(:,osb_add(ii)*2-1:osb_add(ii)*2) = (temp) *200/2.9*0.86 - 0.2*200/2.9*0.86;  %reshape and rescale with MEK coefficient
% 
% 
%     end
% 
%     ppms = flipud(fliplr(ppms)); 
%     osa2hex(ppms); title(['w/ agar ',num2str(tt-onset_wi),'s']); colorbar(); caxis([1 200])
%     set(gca, 'LooseInset', get(gca,'TightInset'))
%     
% %     pause();
% 
%     drawnow
%     F = getframe(gcf); 
%     writeVideo(vidfile,F);
%     
% end
% close(vidfile)

%% hex plotting function
%osa2hex
% addpath(genpath('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/osa2hex'));
%  % this is available in the analysis function
function osa2hex(ppm, normalize)
% osa2hex(ppm, normalize)
%
% dx = 1 --> flow direction
% dy = 1.5 - opposite flow direction
%
% stagger = 0.75 - displacement of second column on osa bar
%
% ppm is ny x nx (standard matrix form)
% 

% if (nargin < 2 || normalize)
%     ppmd = repmat(mean(ppm,1,'omitnan'),[size(ppm,1) 1])./mean(ppm,'all','omitnan');
%     ppm = ppm./ppmd;
% end

dx = 1;
dy = 1.5;
stagger = 0.75;

ny = size(ppm,1);
nx = size(ppm,2);


[ii,jj] = meshgrid(1:nx, 1:ny);
ind1d = sub2ind(size(ppm), jj(:), ii(:));
%[xx,yy] = meshgrid( (1:nx)*dx,(1:ny)*dy);
xx = ii*dx;
yy = jj*dy;

yy(:,2:2:end) = yy(:,2:2:end) + stagger;


bbx = (1:nx)*dx;
bby = (1:ny)*dy;

bbxx = [bbx 0*bby-dx bbx 0*bby+(nx+2)*dx];
bbyy = [0*bbx-dy bby 0*bbx+(ny+2)*dy+stagger bby+stagger];

DT = delaunayTriangulation([xx(:);bbxx(:)], [yy(:);bbyy(:)]);
[V,r] = DT.voronoiDiagram;
for j = 1:length(ind1d)
    ind = DT.nearestNeighbor(xx(ind1d(j)),yy(ind1d(j)));
    vx = V(r{ind},1);
    vy = V(r{ind},2);
    
    patch(max(0,vx), max(0,vy), ppm(ind1d(j)))
end
xlim([dx (nx)*dx]); ylim([dy (ny)*dy+stagger]);
axis("equal");
xlim([dx (nx)*dx]); ylim([dy (ny)*dy+stagger]);
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gcf,'color','w');

end
