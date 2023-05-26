%%% Veff_dC
clear
clc
%%%
% This code is used to analyze tracks with the known odor landscape,
% calculate the effective chemotaxis velocity versus different measurements
% of the odor gradient
%%%

% USER INSTRUCTION: download and unzip the demo data pack Chen_flow_2022.zip from https://doi.org/10.6084/m9.figshare.21737303 to a local directory of your choice, and modify datadir below accordingly. If you don't modify datadir, this script assumes it's in your system's default Downloads directory.
datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
% datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022')

%% load tracking data
reldir = fullfile('worm_tracks', 'track_fig7def_9.mat');  % for figure 9
load(fullfile(datadir, reldir));
mapdir = fullfile('worm_tracks', 'Landscape_low.mat')
Cmap = load(fullfile(datadir, mapdir));
M = Cmap.vq1;
M = fliplr(flipud(M));  %flipped camera

%% analyze gradient distribution
H = fspecial('average',1000);
[fx,fy] = gradient(imfilter(M, H, 'replicate'));
env_grads = M*0;

for ii = 1:size(M,1)
    for jj = 1:size(M,2)
%         env_grads(ii,jj) = norm([fx(ii,jj),fy(ii,jj)]);  % gradient
%         env_grads(ii,jj) = norm([fx(ii,jj),fy(ii,jj)]) / M(ii,jj);  % normed gradient
        env_grads(ii,jj) = log(norm([fx(ii,jj),fy(ii,jj)])) / M(ii,jj);  % log-gradient
    end
end

figure()
imagesc(env_grads)
figure()
hist(env_grads(:))

%% show landscape and tracks
poly_degree = 3;  % polynomial fitting for moving window
filt = 7;  % window the path (has to be odd because it is +/- points around the center)
fr = 1/14;  % 1/14 seconds between each frame  (~0.0714 second for each frame)
nn = length(Tracks);  % number of worms selected
mint = 60;  % minimum time in seconds
minx = 200;  % minimum displacement (in terms of pixels)
endingt = 60*30;  % only taking the first few minutes
pix2mm = 1/31.5;  % pixel to space
targ_track = 7;
conc_thre = 0.6*max(max(M));

figure();
imagesc(M,'XData',[0 size(M,2)*pix2mm],'YData',[0 size(M,1)*pix2mm]);
hold on
cand = [];  %index of tracks as candidates for analysis
alldists = [];
for i = 1:nn
    if Tracks(i).Time(end)-Tracks(i).Time(1) > mint  %time cutoff
        displace = mean((Tracks(i).Path(:,1)-mean(Tracks(i).Path(:,1))).^2 + (Tracks(i).Path(:,2)-mean(Tracks(i).Path(:,2))).^2); %pixel displacement
        alldists = [alldists displace*pix2mm^2];  %all dispacements in mm
        if displace > minx^2  %space cutoff
            pos = find(Tracks(i).Time<endingt);  %time window cutoff (the later time points are less correct...)
            if isempty(pos)~=1
                x_smooth = smooth(Tracks(i).Path(:,1), filt,'sgolay',poly_degree);
                y_smooth = smooth(Tracks(i).Path(:,2), filt,'sgolay',poly_degree);
                    if M(floor(y_smooth(1)), floor(x_smooth(1))) < conc_thre
                plot(x_smooth*pix2mm, y_smooth*pix2mm,'k','LineWidth',1); hold on;
                plot(x_smooth(1)*pix2mm, y_smooth(1)*pix2mm,'g.', 'MarkerSize',15)
                plot(x_smooth(end)*pix2mm, y_smooth(end)*pix2mm,'r.', 'MarkerSize',15)
                cand = [cand i];
                    end
            end
        end
    end
end

hold on
pos = find(Tracks(targ_track).Time<endingt);
x_smooth = smooth(Tracks(targ_track).Path(pos,1), filt,'sgolay',poly_degree);
y_smooth = smooth(Tracks(targ_track).Path(pos,2), filt,'sgolay',poly_degree);
plot(x_smooth*pix2mm, y_smooth*pix2mm,'W','LineWidth',1); hold on;
plot(x_smooth(1)*pix2mm, y_smooth(1)*pix2mm,'g.', 'MarkerSize',15)
plot(x_smooth(end)*pix2mm, y_smooth(end)*pix2mm,'r.', 'MarkerSize',15)

xlabel('x (mm)'); ylabel('y (mm)'); h = colorbar();  ylabel(h, 'ppm');
set(gca,'Fontsize',20); set(gcf,'color','w');
set ( gca, 'xdir', 'reverse' )

%% analysis loop --- for debug with angular velocity
t_wind = 2;
bin = 14*t_wind;  %compute every this many elements (0.5s for 14 hz sampling)
H = fspecial('average',700);  %ones(200,200)/200
[fx,fy] = gradient(imfilter(M, H, 'replicate'));
all_grad = [];  %bearing angle
all_angs = [];  %curving angle
all_delc = [];  %concentration gradient
all_effv = [];  %effective velocity

figure()
for nn = 1:length(Tracks)
    if isempty(find(cand==nn))==0

vec_i = [];    %2d vectors with adaptive sampling rate
grad_i = [];   %at this location, what was the gradient direction

speeds = Tracks(nn).SmoothSpeed;
paths = Tracks(nn).Path;
angspeed_i = Tracks(nn).AngSpeed;
runs = Tracks(nn).Runs;

%%% just runs
% for rr = 1:size(runs,1)
%     path_i = paths(runs(rr,1):runs(rr,2),:); 
%     speed_i = speeds(runs(rr,1):runs(rr,2)); 
%     x_smooth = smooth(path_i(:,1), filt,'sgolay',poly_degree);
%     y_smooth = smooth(path_i(:,2), filt,'sgolay',poly_degree);
%     path_i = [x_smooth   y_smooth];  
%     angs = angspeed_i(runs(rr,1):runs(rr,2));  %%%directly from the pipeline
% end

%%% full trajectory
path_i = paths;  %not extracting the runs

vec_i = diff(path_i,1);   %rewrite vector calculation!!!
grad_i = zeros(1,length(vec_i)-1);
angs = zeros(1, length(vec_i)-1);
delc = zeros(1, length(vec_i)-1);
effv = zeros(1, length(vec_i)-1);
for ii = bin+1:bin:length(angs)-1-bin
    %%% calculate the next vector change
    vec_j = path_i(ii+bin,:) - path_i(ii,:);
    
    %%% track angle change
    angs(ii) = angles(vec_i(ii,:)/norm(vec_i(ii,:)),vec_j/norm(vec_j));
    
    %%% compute local gradient
    grad_dir = [fx(floor(path_i(ii,2)),floor(path_i(ii,1))), fy(floor(path_i(ii,2)),floor(path_i(ii,1)))];
    
    %%% choice of dC measurement!!
    delc(ii) = (((M(floor(path_i(ii,2)),floor(path_i(ii,1)))+norm(grad_dir)) - M(floor(path_i(ii,2)),floor(path_i(ii,1)))) ) / pix2mm;
%     delc(ii) = (log((M(floor(path_i(ii,2)),floor(path_i(ii,1)))+norm(grad_dir)) / M(floor(path_i(ii,2)),floor(path_i(ii,1))))  / (M(floor(path_i(ii,2)),floor(path_i(ii,1)))))*30;
%     delc(ii) = log( (M(floor(path_i(ii+bin,2)),floor(path_i(ii+bin,1))) ) / M(floor(path_i(ii,2)),floor(path_i(ii,1))) )*pix2mm;% / norm(vec_i(ii,:));
%     delc(ii) = ( abs((M(floor(path_i(ii+0,2)),floor(path_i(ii+0,1)))) - M(floor(path_i(ii-bin,2)),floor(path_i(ii-bin,1))))  ) / t_wind;

    %%% compute bearing
    grad_i(ii) = angles(vec_i(ii,:)/norm(vec_i(ii,:)), grad_dir/norm(grad_dir));
    
    %%% effective velocity
    effv(ii) = sum(vec_j .* (grad_dir/norm(grad_dir))) * (pix2mm * 1/(bin/14));  % in mm per seconds
%     effv(ii) = sum(vec_j .* (grad_dir/norm(grad_dir))) / (norm(vec_j));  % chemotaxis index
end

all_grad = [all_grad  grad_i];
all_angs = [all_angs  angs];
all_delc = [all_delc  delc];
all_effv = [all_effv  effv];
nn

% end

% subplot(131); plot(grad); hold on; plot(angs); hold off;
% % subplot(121); plot(angspeed_i./speed_i)
% subplot(132); plot(path_i(:,1),path_i(:,2))
% subplot(133); plot(speed_i)
% pause();

    end
end
pos = find(all_grad==0 | all_grad==0 | all_effv==0 | all_delc==0);
all_grad(pos) = [];
all_angs(pos) = [];
all_effv(pos) = [];
all_delc(pos) = [];

%% test null distribution
th_rand = rand(1,10000)*360-180;
dots_rand = 10*cos(th_rand*pi/180)*(pix2mm * 1/(bin/14));
figure;
hist(dots_rand,100)

%% simple slope calculation
figure;
bins = 7;
H = histogram(all_delc,bins);
bb = H.BinEdges;
muv = zeros(1,bins);
epsv = zeros(2,bins);

for bi = 2:bins+1%+2
    pos = find(all_delc>bb(bi-1) & all_delc<bb(bi));
    muv(bi-1) = median(all_effv(pos)); %mean(all_effv(pos));
    epsv(:,bi-1) = quantile(all_effv(pos),[.25 .75],2);  %std(all_effv(pos));%
end
bb = bb+H.BinWidth/2*1;
figure()
plot(all_delc,all_effv,'.','color', [.7 .7 .7])
hold on; errorbar(bb(1:end-1), muv, 0+epsv(1,:) ,0+epsv(2,:),  'k', 'Linewidth',1) %+mean(diff(bb(1:end-1)))/1
hold on; plot(bb(1:end-1), muv, 'k-o', 'Linewidth',1); plot([min(all_delc),max(all_delc)],[0,0],'--','color', [.5 .5 .5])
xlabel('\nabla C (ppm/mm)'); ylabel('V cos(\theta) (mm/s)'); set(gcf,'color','w'); set(gca,'FontSize',20)

% null model with random angles
eps_null = quantile(dots_rand,[.25 .75],2); %[std(dots_rand),std(dots_rand)]; %
mu_null = median(dots_rand);
hold on
errorbar(0 , mu_null, 0+eps_null(1), 0 + eps_null(2),'b','Linewidth',1)

%% adaptive binning
bins = 7;
num_points = floor(length(all_delc)/bins);  %number of points in one bin, now that we fix this value
[val,poss] = sort(all_delc);
bb = zeros(1,bins);
muv = zeros(1,bins);
epsv = zeros(2,bins);

for bi = 1:bins
%     pos = find(all_delc>bb(bi-1) & all_delc<bb(bi));
    pos = poss((bi-1)*num_points+1:(bi)*num_points);
    bb(bi) = mean(all_delc(pos));
    muv(bi) = median(all_effv(pos));
    epsv(:,bi) = quantile(all_effv(pos),[.3 .7],2); %std(all_effv(pos));%
end
% bb = bb+H.BinWidth/2;
figure()
plot(all_delc,all_effv,'.','color', [.7 .7 .7])
hold on; errorbar(bb(1:end), muv, 0+epsv(1,:) ,0 + epsv(2,:),  'k', 'Linewidth',5) %+mean(diff(bb(1:end-1)))/1
hold on; plot(bb(1:end), muv, 'k-o', 'Linewidth',5); plot([min(all_delc),max(all_delc)],[0,0],'--','color', [.5 .5 .5])
xlabel('\Delta C (ppm/mm)'); ylabel('v_{eff} / V'); set(gcf,'color','w'); set(gca,'FontSize',20)

% null model with random angles
eps_null = quantile(dots_rand,[.3 .7],2); %[std(dots_rand) std(dots_rand)];%
mu_null = mean(dots_rand);
hold on
errorbar(0 , mu_null, 0+eps_null(1), 0 +eps_null(2),'b','Linewidth',5)

%% stats tests
bi=5;
pos = find(all_delc>bb(bi-1) & all_delc<bb(bi));  temp= all_effv(pos); [h,p,ci,stats] = ttest(temp)
