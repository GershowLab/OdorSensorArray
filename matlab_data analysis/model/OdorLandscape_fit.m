% OdorLandscape_fit

%% load ppm data in sensor space
load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1d_hex_data2.mat')
load('/projects/LEIFER/Kevin/Figures/Odor_Flow_figs/fig1e_data3.mat')

%% construct point measurements
osa_check = checkerboard(1,8, 7*2);
osa_check = osa_check(:,1:end/2);
xx = linspace(-7,7,16);   %change to actualy space
yy = linspace(0.1,14,14);
[X,Y] = meshgrid(xx,yy);
check_fill = [];%check*0;
xyv = [];

ii = 1;
tempv = ppms;%reshape(osa_foi,45,1);  %to fill in checkerboard pattern
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
% Create input independent variable:
xx = xyv(:,1);
yy = xyv(:,2);
C0 = max(xyv(:,3));

% setup physics
v = 0.5;   %flow in chamber
D = 0.08;  %MEK
Def = D*(1 + 6.25^2/7.5);  %effective diffusion
Dv = [Def, D];%, Def/v];  %coefficient along x and y
z = xyv(:,3);

% Create Objective Function: 
% % flowfit = @(Dv, XY)  C0*(1 - erf(XY(:,:,1) ./ (2*sqrt(XY(:,:,1).*Dv)) )) .* exp(-XY(:,:,2).^2./(4*XY(:,:,1)*Dv));
flowfit = @(Dv, XY)  C0*(1 - erf( XY(:,2) ./ (2*sqrt(XY(:,2).*Def/v*Dv(1))) )) .* exp(-XY(:,1).^2./(4*XY(:,2)*Def/v*Dv(2)));   % independent x-y
% flowfit = @(Dv, XY)  (C0./XY(:,2))./sqrt(4*pi*XY(:,2)./v*D*Dv(1)) .* exp( -v*XY(:,1).^2./(4*XY(:,2)*Def) );           % unbounded
% flowfit = @(Dv, XY)  ((C0./XY(:,2))./(4*sqrt(XY(:,2).*Def/v*Dv(1)))).* ...
%     1/2.*( erfc(( XY(:,1)./(2*sqrt(XY(:,2)./v.*Def*Dv(1))) ) ) + erfc(( -XY(:,1)./(2*sqrt(XY(:,2)./v.*Def*Dv(1))) ) ));  % bounded solution
% flowfit = @(Dv, XY)  C0*(1 - erf( XY(:,2) ./ (2*sqrt(XY(:,2).*Def/v*Dv(1))) )) .*(erfc( abs(XY(:,1))/2.*sqrt(v./(D*XY(:,2)*Dv(2))) ));

[B,Resnorm] = lsqcurvefit(flowfit, Dv, xyv(:,1:2), z)
% Calculate Fitted Surface:
Z = flowfit(B, xyv); 
Z_meas = reshape(xyv(:,3),8,14);

% make smooth prediction
xx_pred = linspace(-7,7,size(vq1_coved,1));   %change to actualy space
yy_pred = linspace(0.1,14,size(vq1_coved,2));
[X_pred,Y_pred] = meshgrid(xx_pred,yy_pred);
% Z_pred = reshape((Z),8,14);
totl = size(vq1_coved,1)*size(vq1_coved,2);
xy_pred = zeros(totl,2);
xy_pred(:,1) = reshape(X_pred, 1, totl);
xy_pred(:,2) = reshape(Y_pred, 1, totl);
Z_pred = reshape(flowfit(B,xy_pred), size(vq1_coved,2), size(vq1_coved,1));

%%
% Plot: 
figure()
stem3(yy,xx,z,'r', 'fill')                     % Original Data
hold on
stem3(yy, xx, Z, 'k', 'fill') 
hold on
% surf(reshape(yy,8,14), reshape(xx,8,14), Z_pred)  % Fitted Surface
s = surf(Y_pred, X_pred, Z_pred)
s.EdgeColor = 'none';
hold off
xlabel('X \rightarrow')
ylabel('\leftarrow Y')
zlabel('Z \rightarrow')
grid


%% simulation
%%
xx = linspace(0,15,433);
yy = linspace(-7,7,375);
[X,Y] = meshgrid(xx,yy);
v = 0.5;   %flow in chamber
D = 0.08;  %MEK
Def = D*(1 + 6.25^2/7.5);  %effective diffusion
C0 = 200;  %initial odor source
% Z = C0/2*(1-erf(Y.^2 ./ (2*sqrt(Def.*X./v)) ));  %1D
Z = C0/1*(1-erf(X ./ (2*sqrt(Def.*X./v)*5) )) .* exp(-Y.^2./(4*Def*X./v));  %combine
% Z = C0./(4*pi*Def.*X./v).^0.1 .*(1-erf(Y.^2./(4*Def*X./v)*1));   %solve with BC!!!

figure;
imagesc(Z)

%% BC interaction
CM = 500;
activity_c = @(c) 1+3*exp(-x./25);  %activity coefficient as a function of ratio
C_air = Z_pred';%Z*1;
C_gel = C_air./ (1+3*exp(-C_air./25/1) .*CM);
figure;
subplot(121); imagesc(xx,yy,C_air); h = colorbar(); caxis([0,200]); title('odor in air')
set(gca,'Fontsize',20); set(gcf,'color','w');
subplot(122); imagesc(xx,yy,C_gel); h = colorbar(); caxis([0,200]);  title('odor in agar')
set(gca,'Fontsize',20); set(gcf,'color','w');
