%%% odor_flow_worm
clear
clc
% code to preprocess data for:
%                             figure 7: calibration and plotting
%                             SI: for control worm behavior without odor  

% this is used to analyze chemotaxis behavior in worms. The file reads in
% tracking data and the odor landscape, plots these trajectories based on
% criteria, gives example tracks, and analysis for concentration response.

% This script requires function to read from the 'leifer-Behavior-Triggered-Averaging-Tracker'
% pipeline for data loading and the chemotaxis_function repo for behavioral analysis
% other toolboxes should be included in Matlab
% datadir = fullfile(getenv('USERPROFILE'),'Downloads','Chen_flow_2022');
datadir = fullfile('/projects/LEIFER/Kevin/Publications/','Chen_flow_2022')

%% load tracking data
reldir = fullfile('worm_tracks', 'track_fig7def_9.mat');  % for figure 7def
% reldir = fullfile('worm_tracks', 'track_fig7b.mat');  % for figure 7b
% reldir = fullfile('worm_tracks', 'track_fig7a.mat');  % for figure 7a
load(fullfile(datadir, reldir));
mapdir = fullfile('worm_tracks', 'Landscape_low.mat')  % for fig7a,def
% mapdir = fullfile('worm_tracks', 'Landscape_cone_110mM.mat')  % for fig7b
Cmap = load(fullfile(datadir, mapdir));

%% load data (if image file exsists)
% addpath('C:\Users\Kevin\Documents\GitHub\leifer-Behavior-Triggered-Averaging-Tracker_new\Experimental Analysis')
% addpath('C:\Users\Kevin\Desktop\Chemotaxis_function')
% 
% %%% source:
% % for biased-cone
% % {'/projects/LEIFER/Kevin/Data_odor_flow_equ/20220203_GWN_app+_sparse_11mM_9_30ml_400air'}
% % for cone
% % {'/projects/LEIFER/Kevin/Data_cone/20220307_GWN_naive_cone_110mM_10_10ml_400air/Data20220307_144504'}
% % for BRW
% % use tag BRW
% % for WV
% % use tag WV... in the folder '/projects/LEIFER/Kevin/Data_odor_flow_equ'
% 
% % batch analysis
% fields_to_load = {'Path','Time','Runs','Pirouettes','SmoothSpeed','AngSpeed','SmoothX','SmoothY'};%,'Behaviors'};
% folder_names = getfoldersGUI();
% Tracks = loadtracks(folder_names,fields_to_load);

%% pre-processed odor landscape

% biased cone
% Cmap = load('/projects/LEIFER/Kevin/Data_odor_flow_equ/Landscape_low.mat');
% Fcon = load('/projects/LEIFER/Kevin/Data_odor_flow_equ/OdorFx_low.mat');

% centered cone
% Fcon = load('/projects/LEIFER/Kevin/Data_odor_flow_equ/OdorFx_cone_110mM.mat');
% Cmap = load('/projects/LEIFER/Kevin/Data_odor_flow_equ/Landscape_cone_110mM.mat');

M = Cmap.vq1;
M = (flipud(M));  %flipped camera

%% chemotaxis example trajectories (panel a,b) 
poly_degree = 3;  % polynomial fitting for moving window
filt = 7;  % window the path (has to be odd because it is +/- points around the center)
fr = 1/14;  % 1/14 seconds between each frame  (~0.0714 second for each frame)
nn = length(Tracks);  % number of worms selected
mint = 60*2.;  % minimum time in seconds
minx = 100;  % minimum displacement (in terms of pixels)
endingt = 60*30;  % only taking the first few minutes
pix2mm = 1/31.5;
targ_track = 7;
conc_thre = 0.8*max(max(M));

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
%             pos = find(Tracks(i).Path(1,2)<1000 | Tracks(i).Path(1,2)>1500);
            pos = find(Tracks(i).Time<endingt);  %time window cutoff (if later time points are less correct...)
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

%%  scan trough tracks (for visualization)
% figure();
% for j = 1:length(cand)
%     i = cand(j);
%     pos = find(Tracks(i).Time<endingt);  %time window cutoff (the later time points are less correct...)
%     x_smooth = smooth(Tracks(i).Path(pos,1), filt,'sgolay',poly_degree);
%     y_smooth = smooth(Tracks(i).Path(pos,2), filt,'sgolay',poly_degree);
%     subplot(121)
%     imagesc(M,'XData',[0 size(M,2)*pix2mm],'YData',[0 size(M,1)*pix2mm]); hold on;
%     plot(x_smooth*pix2mm, y_smooth*pix2mm,'k');
%     plot(x_smooth(1)*pix2mm, y_smooth(1)*pix2mm,'r*')
%     title(num2str(i))
%     subplot(122)
% %     [v_orthogonal, v_parallel, speed, curve] = track2speed(x_smooth, y_smooth);
% %     plot(curve);  hold on
% %     smooth_test = smoothts(speed, 'g', 7, 7);
% %     plot(smooth_test); hold on
% %     plot(v_orthogonal); hold on; plot(v_parallel); hold off
%     yyaxis right;  plot(Tracks(i).AngSpeed); yyaxis left
%     plot(Tracks(i).SmoothSpeed); 
%     pause();
% end

%% panel c
i = 7; %picking an example
wind = [1600:3200]+0;
% wind = 850:2600; % time widow to show

speeds = Tracks(i).SmoothSpeed;
paths = Tracks(i).Path;
angspeed_i = Tracks(i).AngSpeed;
runs = Tracks(i).Runs;
x_smooth = smooth(paths(:,1), filt,'sgolay',poly_degree);
y_smooth = smooth(paths(:,2), filt,'sgolay',poly_degree);
path_i = [x_smooth   y_smooth];  
% angs = angspeed_i(runs(rr,1):runs(rr,2));  %%%directly from the pipeline

vec_i = diff(path_i,1);
grad_i = zeros(1,length(vec_i)-1);
angs = zeros(1, length(vec_i)-1);
for ii = 1:length(angs)-1
    angs(ii) = angles(vec_i(ii,:)/norm(vec_i(ii,:)),vec_i(ii+1,:)/norm(vec_i(ii+1,:)));
%     grad_dir = [fx(floor(path_i(ii,2)),floor(path_i(ii,1))), fy(floor(path_i(ii,2)),floor(path_i(ii,1)))];
%     grad_i(ii) = dot(vec_i(ii,:), grad_dir);%
%     grad_i(ii) = angles(vec_i(ii,:)/norm(vec_i(ii,:)), grad_dir/norm(grad_dir));
    grad_i(ii) = M(floor(y_smooth((ii))),floor(x_smooth((ii))));
end

xx = [1:length(wind)]*1/14;  %seconds
cts = zeros(1,length(wind));
for tt = 1:length(wind);  cts(tt) = M(floor(y_smooth(wind(tt))),floor(x_smooth(wind(tt)))); end
figure;
subplot(211);
scatter(x_smooth(wind),y_smooth(wind),[],cts, 'filled'); hold on;
for pp = 3:6
scatter( x_smooth(Tracks(i).Pirouettes(pp,1):Tracks(i).Pirouettes(pp,2)+15), y_smooth(Tracks(i).Pirouettes(pp,1):Tracks(i).Pirouettes(pp,2)+15) ,'k');  
end
plot(x_smooth(wind(1)), y_smooth(wind(1)),'g.', 'MarkerSize',15)
plot(x_smooth(wind(end)), y_smooth(wind(end)),'r.', 'MarkerSize',15)
axis off; colorbar();
subplot(212)
% yyaxis right; plot(xx, grad_i(wind));  
% yyaxis left
plot(xx, Tracks(i).AngSpeed(wind));  hold on
for pp = 3:6
x_points = [[Tracks(i).Pirouettes(pp,1), Tracks(i).Pirouettes(pp,1), Tracks(i).Pirouettes(pp,2)+15, Tracks(i).Pirouettes(pp,2)+15]-wind(1)]/14;  
y_points = [-400, 400, 400, -400]; %[-.1, .1, .1, -.1];
color = [0, 0, 1];
hold on;
a = fill(x_points, y_points, color);
a.FaceAlpha = 0.1;
end
% plot(xx, Tracks(i).SmoothSpeed(wind));
% plot(cts)
% plot(xx, Tracks(i).SmoothSpeed(wind));
set(gca,'Fontsize',20); set(gcf,'color','w');
xlabel('time (s)')
ylabel('angular veolocity')

%% show individual d_C and d_theta data
track = Tracks(7).Path(1:end,:);
bin = 7;
x_smooth = smooth(track(:,1), filt,'sgolay',poly_degree);
y_smooth = smooth(track(:,2), filt,'sgolay',poly_degree);
temp = [x_smooth'; y_smooth']';
subs = temp(1:bin:end,:);
vecs = diff(subs);
Ct = zeros(1,length(vecs));
dtht = Ct*1;
for pp = 2:length(vecs)
%     Ct(pp) = Fcon(subs(pp,1), subs(pp,2));
    Ct(pp) = M(floor(subs(pp,2)), floor(subs(pp,1)));
    dtht(pp) = angles(vecs(pp-1,:)/norm(vecs(pp-1,:)),vecs(pp,:)/norm(vecs(pp,:)));
end
time_ = [1:length(vecs)]/14*bin;
figure;
subplot(211); plot(time_(2:end-1), Ct(2:end-1),'b', 'Linewidth',3); ylabel('ppm');
xAX = get(gca,'YAxis');
set(xAX,'FontSize', 15);
xticks([]);
subplot(212); plot(time_(2:end-1), dtht(2:end-1), 'k', 'Linewidth',1); ylabel('d\theta'); xlabel('time (s)')
set(gcf,'color','w');
xAX = get(gca,'XAxis');
set(xAX,'FontSize', 15);
xAX = get(gca,'YAxis');
set(xAX,'FontSize', 15);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis... summary statistics panel d,e,f
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% replace with real landscape later
% bias = 8.;
% xx = linspace(0,15,3000);
% yy = linspace(-7,7,2500);
% [X,Y] = meshgrid(xx,yy);
% v = 0.5;   %flow in chamber
% D = 0.08;  %MEK
% Def = D*4;%(1 + 6.25^2/7.5);  %effective diffusion
% C0 = 200;  %initial odor source
% % Z = C0/2*(1-erf(Y.^2 ./ (2*sqrt(Def.*X./v)) ));  %1D
% Z = C0/1*(1-erf(X ./ (2*sqrt(Def.*X./v)*10) )) .* exp(-(Y-bias).^2./(4*Def*X./v));  %combine
% % Z = C0./(4*pi*Def.*X./v).^0.1 .*(1-erf(Y.^2./(4*Def*X./v)*1));   %solve with BC!!!
% 
% figure;
% imagesc(Z)
% 
% %% contour and quiver plot of the landscape gradient
% figure
% contour(xx,yy,Z)
% hold on
% x_ = linspace(0,15,15);
% y_ = linspace(-7,7,15);
% z_ = C0/1*(1-erf(x_ ./ (2*sqrt(Def.*x_./v)*5) )) .* exp(-(y_-bias)'.^2./(4*Def*x_./v));
% [px,py] = gradient(z_);
% quiver(x_,y_,px,py)

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis loop --- for BRW
nn = 1;
fixlen = 14;  %we only compute a 2d vector when it moves forward this much
% [fx,fy] = gradient((M),1:3000,1:2500);%gradient(fliplr((Z)),1);
[fx,fy] = gradient((conv2(M,ones(100,100),'same')/10000),1);  %prepare 2D gradient field
all_grad = [];
all_angs = [];

figure()
for nn = 1:length(Tracks)
    if isempty(find(cand==nn))==0

vec_i = [];    %2d vectors with adaptive sampling rate
grad_i = [];   %at this location, what was the gradient direction

speed_i = Tracks(nn).SmoothSpeed;
path_i = Tracks(nn).Path;
angspeed_i = Tracks(nn).AngSpeed;
runs = Tracks(nn).Runs;
        
ii = 1;
pos_temp = path_i(1,:);  %initial location
while ii<length(speed_i)
%     delta_t = min(round(fixlen/speed_i(ii)), floor(length(speed_i)/2));  %discrete time window to update, adpated to the velocity
    delta_t = min(fixlen*1, floor(length(speed_i)/2));
    vec_i = [vec_i; path_i(ii,:)-pos_temp];  %compute dispacement vector
    grad_i = [grad_i; [fx(floor(path_i(ii,2)),floor(path_i(ii,1))), fy(floor(path_i(ii,2)),floor(path_i(ii,1)))] ];  %gradident direction at this location
    pos_temp = path_i(ii,:);  %update postion
    ii = ii + delta_t+1;
end

angs = zeros(1, length(vec_i)-1);
grad = angs*1;
for pp = 1:length(vec_i)-1
    angs(pp) = angles(vec_i(pp,:)/norm(vec_i(pp,:)),vec_i(pp+1,:)/norm(vec_i(pp+1,:)));
    grad(pp) = angles(vec_i(pp,:)/norm(vec_i(pp,:)), grad_i(pp,:)/norm(grad_i(pp,:)));%dot(vec_i(pp,:), grad_i(pp,:));%
end

% subplot(121); plot(grad); hold on; plot(angs); hold off;
% % subplot(121); plot(angspeed_i./speed_i)
% subplot(122); plot(path_i(:,1),path_i(:,2))
% pause();

all_grad = [all_grad  grad];
all_angs = [all_angs  angs];
nn
    end
end

%% BRW
figure()

thre_pr = 120;   %threshold for a piroutte
thre_grad = 60;  %threshold for a gradient
cnt_i = []; cnt_b = [];
pos_0 = find(abs(all_grad)<thre_grad);
angs_0 = find(abs(all_angs(pos_0))>thre_pr);
aa = length(angs_0)/length(pos_0);  cnt_i = [cnt_i length(angs_0)]; cnt_b = [cnt_b length(pos_0)];
pos_60 = find(abs(all_grad)>thre_grad & abs(all_grad)<120);
angs_0 = find(abs(all_angs(pos_60))>thre_pr);
bb = length(angs_0)/length(pos_60);  cnt_i = [cnt_i length(angs_0)]; cnt_b = [cnt_b length(pos_60)];
pos_120 = find(abs(all_grad)>120);
angs_0 = find(abs(all_angs(pos_120))>thre_pr);
cc = length(angs_0)/length(pos_120);  cnt_i = [cnt_i length(angs_0)]; cnt_b = [cnt_b length(pos_120)];

EE = ( ((cnt_i-1)./(cnt_b.^2)) + (cnt_i.^2.*(cnt_b-1)./(cnt_b.^4)) ).^0.5 *1/1;

errorbar([1,2,3], [aa,bb,cc], EE,'ko','LineWidth',2); hold on
xlabel('bearing angle');  ylabel('turn probability per second')
bar([1,2,3],[aa,bb,cc])
xticks([1 2 3]); xticklabels({'<60','60~120','>120'})
set(gca,'Fontsize',20); set(gcf,'color','w');

%% Chi test
x1 = [abs(all_angs(pos_60))>thre_pr];
x2 = [abs(all_angs(pos_120))>thre_pr];
ll = min(length(x1),length(x2));
[tbl,chi2,p] = crosstab(x1(1:ll),x2(1:ll)) 

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis loop --- for WV
nn = 1;
filt = 14*2;
fixlen = 1;  %we only compute a 2d vector when it moves forward this much
% [fx,fy] = gradient(fliplr((Z)),1);
[fx,fy] = gradient((conv2(M,ones(100,100),'same')/10000),1);  %prepare 2D gradient field
all_grad = [];
all_angs = [];

figure()
for nn = 1:length(Tracks)
    if isempty(find(cand==nn))==0

vec_i = [];    %2d vectors with adaptive sampling rate
grad_i = [];   %at this location, what was the gradient direction
sped_i = [];

speeds = Tracks(nn).SmoothSpeed;
paths = Tracks(nn).Path;
angspeed_i = Tracks(nn).AngSpeed;
runs = Tracks(nn).Runs;

for rr = 1:size(runs,1)
        path_i = paths(runs(rr,1):runs(rr,2),:); 
        speed_i = speeds(runs(rr,1):runs(rr,2)); 
        x_smooth = smooth(path_i(:,1), filt,'sgolay',poly_degree);
        y_smooth = smooth(path_i(:,2), filt,'sgolay',poly_degree);
        path_i = [x_smooth   y_smooth];  
%         angs = angspeed_i(runs(rr,1):runs(rr,2));  %%%directly from the pipeline
        
ii = 2;
pos_temp = path_i(1,:);  %initial location
while ii<length(speed_i)
%     delta_t = min(floor(fixlen/speed_i(ii)), floor(length(speed_i)/2));  %discrete time window to update, adpated to the velocity
    delta_t = min(14*fixlen, floor(length(speed_i)/2));%
    vec_i = [vec_i; path_i(ii,:)-pos_temp];  %compute dispacement vector
    grad_i = [grad_i; [fx(floor(path_i(ii,2)),floor(path_i(ii,1))), fy(floor(path_i(ii,2)),floor(path_i(ii,1)))] ];  %gradident direction at this location
    pos_temp = path_i(ii,:);  %update postion
    sped_i = [sped_i; speed_i(ii)];
    ii = ii + delta_t+1;
%     ii
end

angs = zeros(1, length(vec_i)-1);
grad = angs*1;
for pp = 1:length(vec_i)-1
    angs(pp) = angles(vec_i(pp+1,:)/norm(vec_i(pp+1,:)),vec_i(pp,:)/norm(vec_i(pp,:))) / (norm(vec_i(pp,:))*pix2mm); %/fixlen;% / ((sped_i(pp)+sped_i(pp+1))/2);%   %
%     grad(pp) = dot(vec_i(pp,:), grad_i(pp,:));%
    grad(pp) = angles(vec_i(pp,:)/norm(vec_i(pp,:)), grad_i(pp,:)/norm(grad_i(pp,:)))*norm(grad_i(pp,:));
    end

all_grad = [all_grad  grad];
all_angs = [all_angs  angs];
nn

end

% subplot(131); plot(grad); hold on; plot(angs);plot(angspeed_i); hold off;
% % subplot(121); 
% subplot(132); plot(path_i(:,1),path_i(:,2))
% subplot(133); plot(speed_i)
% pause();

    end
end

% pos = find(all_grad==0 | all_grad==0);
% all_grad(pos) = [];
% all_angs(pos) = [];
%% WV!
nbs = linspace(-150,150,15);%
figure()
pos_0 = find((all_grad)<-10);
pos_60 = find(abs(all_grad)<10);
pos_120 = find((all_grad)>10);

% pos_0 = find((all_grad)>-110 & all_grad<-70);
% pos_60 = find(abs(all_grad)<50);
% pos_120 = find((all_grad)>70 & all_grad<110);

% pos_0 = find((all_grad)>0.1);
% pos_60 = find((all_grad)<0.1 & all_grad>0);
% pos_120 = find((all_grad)<-0. & all_grad>-2);

H1 = histogram(all_angs(pos_0), nbs, 'Normalization', 'pdf'); hold on
H2 = histogram(all_angs(pos_60), nbs, 'Normalization', 'pdf'); hold on
H3 = histogram(all_angs(pos_120), nbs, 'Normalization','pdf');
% close(fig);

figure()
aa = H1.Values;  bb = H1.BinEdges;
bb = (bb(2:end) + bb(1:end-1))/2;
plot(bb,aa/sum(aa) / 1); hold on %max(aa/sum(aa))
med = mean((aa/sum(aa) / max(aa/sum(aa))).*bb);
plot([med,med],[0,1])
y = skewness(all_angs(pos_0))
hold on
aa = H2.Values;  bb = H2.BinEdges;
bb = (bb(2:end) + bb(1:end-1))/2;
plot(bb,aa/sum(aa) / 1); hold on
med = mean((aa/sum(aa) / max(aa/sum(aa))).*bb);
plot([med,med],[0,1])
y = skewness(all_angs(pos_60))
hold on
aa = H3.Values;  bb = H3.BinEdges;
bb = (bb(2:end) + bb(1:end-1))/2;
plot(bb,aa/sum(aa) / 1); hold on
med = mean((aa/sum(aa) / max(aa/sum(aa))).*bb);
plot([med,med],[0,1])
y = skewness(all_angs(pos_120))

%% KS test
x1 = all_angs(pos_0);
x2 = all_angs(pos_120);
[h,p] = kstest2(x1,x2,'Alpha',0.01)


%% analysis loop --- for debug with angular velocity
bin = 14;  %compute every this many elements (0.5s for 14 hz sampling)
[fx,fy] = gradient((M),1);%gradient(fliplr((Z)),1); %prepare 2D gradient field
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
for rr = 1:size(runs,1)
        path_i = paths(runs(rr,1):runs(rr,2),:); 
        speed_i = speeds(runs(rr,1):runs(rr,2)); 
        x_smooth = smooth(path_i(:,1), filt,'sgolay',poly_degree);
        y_smooth = smooth(path_i(:,2), filt,'sgolay',poly_degree);
        path_i = [x_smooth   y_smooth];  
%         angs = angspeed_i(runs(rr,1):runs(rr,2));  %%%directly from the pipeline

%%% full trajectory


vec_i = diff(path_i,1);
grad_i = zeros(1,length(vec_i)-1);
angs = zeros(1, length(vec_i)-1);
delc = zeros(1, length(vec_i)-1);
effv = zeros(1, length(vec_i)-1);
for ii = 1:bin:length(angs)-1
    angs(ii) = angles(vec_i(ii,:)/norm(vec_i(ii,:)),vec_i(ii+1,:)/norm(vec_i(ii+1,:)));
    %use gradient
    grad_dir = [fx(floor(path_i(ii,2)),floor(path_i(ii,1))), fy(floor(path_i(ii,2)),floor(path_i(ii,1)))];
    delc(ii) = norm(grad_dir);
    % use coordinate for now
%     grad_dir = targt_xy - [path_i(ii,2) , path_i(ii,1)];
%     grad_i(ii) = dot(vec_i(ii,:), grad_dir);%
    grad_i(ii) = angles(vec_i(ii,:)/norm(vec_i(ii,:)), grad_dir/norm(grad_dir));
    effv(ii) = sum(vec_i(ii,:).*grad_dir/norm(grad_dir));
end

all_grad = [all_grad  grad_i];
all_angs = [all_angs  angs];
all_delc = [all_delc  delc];
all_effv = [all_effv  effv];
nn

end

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
