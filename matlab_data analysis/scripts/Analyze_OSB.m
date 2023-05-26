%Analyze_OSB
clear all
%% load data
% dir_ = '/tigress/LEIFER/Kevin/OdorSensorArray/';
% dir_ = '/tigress/LEIFER/Kevin/OdorSensorArray/temperature/';
dir_ = '/tigress/LEIFER/Kevin/OdorSensorArray/OSA_recordings/';
listing = dir(dir_);

%% time seties
%reading
%%% file indexing %%%
%13-15 0.002Hz
%16-18 0.02Hz
%19 rotate in solftware readout
%20-22 rotate in physical space (0.02, 0.01, and 0.005 Hz)
%23 stationary cone
%%%%%%%%%%%%%%%%%%%%%
ii = 11;%23;
foi = listing(ii).name
foi = '20211007171409_osa_reset_70min.txt';
% foi = '20211001191307_osa.txt';
ftable = readtable([dir_,foi]);  %read value from OSB
H2 = ftable.data_1;
EtOH = ftable.data_2;
code = ftable.code;
valid = ftable.valid;
% H2 = ftable.Var6;
% EtOH = ftable.Var7;
% code = ftable.Var2;
% valid = ftable.Var8;

%condition on reading and validity
inds = find(code==1);  %these are valid (?)
H22 = H2(inds);
EtOH2 = EtOH(inds);
% reset invalid data to NaN for plotting
H22(valid==0) = NaN;
EtOH2(valid==0) = NaN;

%array structure
rnd = floor(length(H22)/16)*16;
data_h2 = reshape(H22(1:rnd),16,[]);  %channel by time (16 X seconds)
data_Et = reshape(EtOH2(1:rnd),16,[]);

%plotting
figure;
subplot(1,2,1);
plot(data_h2(1:8,:)','b-o'); hold on;
plot(data_h2(9:16,:)','r-o'); hold off;
title('raw h2');
set(gca,'FontSize',20); xlabel('time (s)');
subplot(1,2,2);
plot(data_Et(1:8,:)','b-o'); hold on;
plot(data_Et(9:16,:)','r-o'); hold off;
title('raw EtOH');
set(gca,'FontSize',20); xlabel('time (s)');


%% solving dropping problems
figure()
barnum = ftable.osb_index;
pickOSB = [3,6];
c=['r','b'];
for ii = 1:2
    odori = find(code==1);  %for oder
    osbi = find(barnum==pickOSB(ii));  %which OSB
    inds = intersect(odori,osbi);
    % inds = inds(1:end-6);
%     H22 = ones(length(H2),1)*NaN;
    H22 = H2(inds);
%     EtOH2 = ones(length(H2),1)*NaN;
    EtOH2 = EtOH(inds);
    % reset invalid data to NaN for plotting
    H22(valid==0) = NaN;
    EtOH2(valid==0) = NaN;
    
    %array structure
    rnd = floor(length(H22)/16)*16;
    data_h2 = reshape(H22(1:rnd),16,[]);  %channel by time (16 X seconds)
    data_Et = reshape(EtOH2(1:rnd),16,[]);
    
    subplot(1,2,1);
    plot(data_h2',c(ii)); hold on;
    title('raw h2');
    set(gca,'FontSize',20); xlabel('time (s)');
    subplot(1,2,2);
    plot(data_Et',c(ii)); hold on;
    title('raw EtOH');
    set(gca,'FontSize',20); xlabel('time (s)');
    
end
% legend('OSB1','OSB7')

%%
tt = ftable.ms_timer;
figure()
ind1 = find(barnum==1);
ind7 = find(barnum==7);
plot(tt(ind1),barnum(ind1),'r-o'); hold on;
plot(tt(ind7),barnum(ind7),'b-o'); hold off;
set(gca,'FontSize',20); xlabel('ms timer'); ylabel('osb#');

%% spectrum
for ii = 1:8  %9:16
X = data_Et;  %data time series
Fs = 1;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
L = size(data_h2,2);             % Length of signal
t = (0:L-1)*T;        % Time vector
Y = fft(X(ii,:));

P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;
plot(f,P1,'r') 
xlabel('f (Hz)')
ylabel('|P1(f)|')
xlim([0 0.1]); ylim([0 150]);
hold on
end

%% phase-lag detection
LAGS = zeros(16,16);
for ii = 1:16
    for jj = 1:16
nOSB = ii;
aa = X(ii,:);
bb = X(jj,:);  %nOSB+8
[c,lags] = xcorr(bb-mean(bb),aa-mean(aa),'coeff');
[val,loc] = max(c);
LAGS(ii,jj) = lags(loc);
% plot(lags,c)
% hold on
    end
end
imagesc(LAGS)
title('Lag of 1st peak in cross-correlation (s)')
xlabel('IDs');ylabel('IDs');set(gca,'FontSize',25)


%%
%%%
%temperature measurements
%%%
%% time trace
figure();
% fname = '20200122163758_osa_wo_thermal.txt';
% fname = '20200122170100_osa_w_tape.txt';
% fname = '20200122172650_osa_w_tape_paste.txt';
% fname = '20200123115454_osa_wo_OS.txt';
% fname = '20200123125809_osa_w_OS.txt';
fname = '20200123132814_osa_w_paste_tape.txt';
fname = '20200123171611_osa_OS_off.txt';
fname = '20200123170202_osa_w_temp';
fname = '20200124105811_osa_tightcontact.txt';
fname = '20200131175541_osa_out_heating.txt';
fname = '20200131184928_osa_outheat_swap71.txt';
fname = '20200203164756_osa_0.004Hz.txt';

ftable = readtable(fname);  %read value from OSB
% H2 = ftable.data_1;
% EtOH = ftable.data_2;
% code = ftable.code;
% valid = ftable.valid;
H2 = ftable.Var6;
EtOH = ftable.Var7;
code = ftable.Var2;
valid = ftable.Var8;

%condition on reading and validity
inds = find(code==2);  %these are valid (?)
% inds = inds(1:end-6);
H22 = H2(inds);
EtOH2 = EtOH(inds);
% reset invalid data to NaN for plotting
% H22(valid==0) = NaN;
% EtOH2(valid==0) = NaN;

%array structure
data_h2 = reshape(H22,8,[]);  %channel by time (16 X seconds)
data_Et = reshape(EtOH2,8,[]);

plot(data_h2')
title('raw h2');
xlabel('time (s)'); ylabel('temperature (C)')
set(gca,'FontSize',20); xlabel('time (s)');

%%
%%%
%flow test
%%%
%%
fname = '20200128162330_osa_flow.txt';  %sptial gradient test
% fname = '20200129163012_osa_marker.txt';  %marker individual OSB test
fname = '20200203164756_osa_0.004Hz.txt';
% fname = '20200203172031_osa_0.004Hz_2.txt';
ftable = readtable(fname);  %read value from OSB
H2 = ftable.Var6;
EtOH = ftable.Var7;
code = ftable.Var2;
valid = ftable.Var8;
osb_index = ftable.Var3;

for ii = 3%7:-1:2
%condition on reading and validity
pickOSB = ii;
odori = find(code==1);  %for oder
osbi = find(osb_index==pickOSB);  %which OSB
inds = intersect(odori,osbi);
% inds = inds(1:end-6);
H22 = H2(inds);
EtOH2 = EtOH(inds);
% reset invalid data to NaN for plotting
% H22(valid==0) = NaN;
% EtOH2(valid==0) = NaN;

%array structure
data_h2 = reshape(H22,16,[]);  %channel by time (16 X seconds)
data_Et = reshape(EtOH2,16,[]);

figure
% subplot(2,3,ii-1)
% subplot(6,1,ii-1)
plot(data_h2(6,1:300)')
set(gca,'xtick',[])
% title(['OSB#',num2str(pickOSB)])
% xlabel('time (s)'); ylabel('raw H2')
set(gca,'FontSize',20); %xlabel('time (s)');

end
%% spatial plot!
fname = '20200128162330_osa_flow.txt';  %sptial gradient test
ftable = readtable(fname);  %read value from OSB
H2 = ftable.Var6;
EtOH = ftable.Var7;
code = ftable.Var2;
valid = ftable.Var8;
osb_index = ftable.Var3;
time = 300;  %at one time point
OSA = [];
for OI = 7:-1:2
    
    %condition on reading and validity
    odori = find(code==1);  %for oder
    osbi = find(osb_index==OI);  %which OSB
    if OI ~= 5
        inds = intersect(odori,osbi);
        H22 = H2(inds);
        EtOH2 = EtOH(inds);
        H22(valid==0) = NaN;
        EtOH2(valid==0) = NaN;
        data_h2 = reshape(H22,16,[]);  %channel by time (16 X seconds)
        data_Et = reshape(EtOH2,16,[]);
        
    elseif OI == 5  %hand-tune due to recording cutoff
        inds = intersect(odori,osbi);
        inds = inds(1:end-5);
        H22 = H2(inds);
        EtOH2 = EtOH(inds);
        H22(valid==0) = NaN;
        EtOH2(valid==0) = NaN;
        data_h2 = reshape(H22,16,[]);  %channel by time (16 X seconds)
        data_Et = reshape(EtOH2,16,[]);
    end
    
    OSA = [OSA  reshape(data_h2(:,time),8,2)];
end

figure
imagesc(OSA)

%%
%% spatial plot (for temperature)
fname = '20200128162330_osa_flow.txt';  %sptial gradient test
% fname = '20200131175541_osa_out_heating.txt';
fname = '20200131184928_osa_outheat_swap71.txt';
fname = '20200203164756_osa_0.004Hz.txt';
ftable = readtable(fname);  %read value from OSB
H2 = ftable.Var6;
EtOH = ftable.Var7;
code = ftable.Var2;
valid = ftable.Var8;
osb_index = ftable.Var3;
time = 500;  %at one time point
OSA = [];
for OI = 7:-1:2
    
    %condition on reading and validity
    odori = find(code==2);  %for oder
    osbi = find(osb_index==OI);  %which OSB
    if OI ~= 8
        inds = intersect(odori,osbi);
        H22 = H2(inds);
        EtOH2 = EtOH(inds);
%         H22(valid==0) = NaN;
%         EtOH2(valid==0) = NaN;
        data_h2 = reshape(H22,8,[]);  %channel by time (16 X seconds)
        data_Et = reshape(EtOH2,8,[]);
        
    elseif OI == 8  %hand-tune due to recording cutoff
        inds = intersect(odori,osbi);
        inds = inds(1:end-5);
        H22 = H2(inds);
        EtOH2 = EtOH(inds);
        H22(valid==0) = NaN;
        EtOH2(valid==0) = NaN;
        data_h2 = reshape(H22,16,[]);  %channel by time (16 X seconds)
        data_Et = reshape(EtOH2,16,[]);
    end
    
    OSA = [OSA  data_h2(:,time)];
end

figure
imagesc(OSA)