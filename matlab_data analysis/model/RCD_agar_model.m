% ----------------------------------------------------------------------- %
% Reaction-diffusion-diffusion model for odor-agar interaction
%%%
% The aim is to capture steady-state odor landscape, the odor-agar
% interaction, and how we can compensate via pre-equilibration protocol
%%%
% ----------------------------------------------------------------------- %
%  Modified from                                                          %
%   CRECK Modeling Group <http://creckmodeling.chem.polimi.it>            %
%   Department of Chemistry, Materials and Chemical Engineering           %
%-------------------------------------------------------------------------%

%%% PE parameters 
%%%%%
% Tune these parameters to mimic pre-equilibration protcol
% comment out the condition of interest
%%% without agar %%%
PE_time = 30;  % time using the highC input for pre-equilibration
hiC = 1;   % equilibrium protocol control (1 for none and higher (like 2-10) for hiC) 5
condition = 0;  % w/==1, w/o==0, with or without agar in space

%%% with agar, but not equilibrated %%%
% PE_time = 30;  % time using the highC input for pre-equilibration
% hiC = 1;   % equilibrium protocol control (1 for none and higher (like 2-10) for hiC) 5
% condition = 1;  % w/==1, w/o==0, with or without agar in space

%%% without agar %%%
% PE_time = 30;  % time using the highC input for pre-equilibration
% hiC = 8;   % equilibrium protocol control (1 for none and higher (like 2-10) for hiC) 5
% condition = 1;  % w/==1, w/o==0, with or without agar in space

%%%%%

%%% flow parameters and geometry
nx = 30;                  % number of grid points along x (0.5 cm per bin)
ny = 28;                  % number of grid points along y
nstep = 500;              % number of time steps
lengthx = 15.0;           % domain length along x [cm]
lengthy = 14.0;           % domain length along y [cm]
D = 0.1;                  % diffusion coefficient [cm2/s]
u = 0.5;                  % velocity along x [cm/s]
v = 0.;                   % velocity along y [cm/s]
A = 1.25;                 % arbitrary constant
B = 0.75;                 % arbitrary constant

%%% agar parameters
ka = 0.5;   % accociation constant  0.5
kd = 0.05;  % deccociation constant  0.05
Cm = 5;     % non-equilibrium effect of agar capacity (0 for without agar and higher for large plate)

% Pre-processing of user-defined data
% Calculate grid steps
hx = lengthx/(nx-1);      % grid step along x [cm]
hy = lengthy/(ny-1);      % grid step along y [cm] 
x = 0:hx:lengthx;         % x coordinates [cm]
y = 0:hy:lengthy;         % y coordinates [cm]

% Numerical setup: time step (stability conditions)
sigma = 0.75;                       % safety coefficient
dt_diff  = 1/4*min(hx^2, hy^2)/D;   % diffusion [s]
dt_conv = 4*D/(u^2+v^2);            % convection [s]
dt = sigma*min(dt_diff, dt_conv);   % time step [s]
fprintf('Co=%f Di=%f Pe=%f \n', ...
            max(u,v)*dt/min(hx,hy), D*dt/min(hx^2,hy^2), ...
            max(hx,hy)*max(u,v)/D);

% Memory allocation
pid_read = zeros(1,nstep); % recording the downstream concentration as we do experimentally
f = zeros(nx,ny);          % current numerical solution
f0 = zeros(nx,ny);         % initial numerical solution
fan = zeros(nx,ny);        % analytical solution
ag = zeros(nx,ny);         % agar substrate
dag = ag*1;                % agar for iterations
dair = dag*1;              % change in air concentration due to agar (used for first-oder model)

% Initial condition
% for i=1:nx
%         for j=1:ny
%             csi = u*x(i)+v*y(j);
%             eta = v*x(i)-u*y(j);
%             f0(i,j) = C*sin(B*pi*eta)*exp((1-sqrt(1+4*(A*pi*D)^2))/(2*D)*csi);
%         end
% end
f0(1, floor(ny/2)-1:floor(ny/2)+1) = 1;  %influx ppm condition (we use 1 but can be rescaled accordingly)
% mols = sum(sum(f0));
% f0(end,:) = -ones(1,ny)*mols/(ny*1);

% Advancing in time
%-------------------------------------------------------------------------%
t = 0.;
figure;
for m = 1:nstep
    
    % Constant
    gamma = D*pi*pi*(u^2+v^2)*(B^2-A^2);
    
%     % Analytical solution
%     for i=1:nx
%         for j=1:ny
%             fan(i,j) = f0(i,j) * exp(-gamma*t);
%         end
%     end
%     
%     % Error (mean) between numerical and analytical solution
%     error = sum(sum(abs(f-fan)))/(nx*ny);
    
    % Plot the current solution
    plot(x,f(:,ny/2))%, x,fan(:,ny/2));
    title('Solution along the horizontal axis at y=Ly/2'); % legend('numerical', 'analytical');
    xlabel('x-axis [m]'); ylabel('f value');
%     pause(0.0001)
    
    % Boundary conditions (Dirichlet, constant in time)
    f(:,1)  = f0(:,1)*exp(-gamma*t);
    f(:,ny) = f0(:,ny)*exp(-gamma*t);
    f(1,:)  = f0(1,:);  %*exp(-gamma*t);
    f(nx,:) = f0(nx,:)*exp(-gamma*t);
    
    % EQU protocol
    if t < PE_time
        f(1,:)  = f0(1,:)*hiC;  % influx concentration controlled
    end

    % Agar interaction
    for i=6:nx-6
        for j=5:ny-5
            dag(i,j) =  (ka*f(i,j)*(Cm-ag(i,j))/Cm - kd*ag(i,j));  %agar concentration dynamics (with capacity term)
%             dag(i,j) =  (ka*f(i,j) - kd*ag(i,j));  % agar concentration dynamics (first-oder interaction model, from Marc)

            dair(i,j) = (kd*ag(i,j) - ka*f(i,j));  % airborne concentration dynamics (corresponding to the first-order model)
        end
    end
    ag = ag + dag*dt;  % odor concentration in agar
    
    % Forward Euler method for the RCD model
    fo = f;
    for i=2:nx-1
        for j=2:ny-1
            f(i,j) = fo(i,j)...
                    -(0.5*dt*u/hx)*(fo(i+1,j)-fo(i-1,j))...
                    -(0.5*dt*v/hy)*(fo(i,j+1)-fo(i,j-1))...
                    +(D*dt/hx^2)*(fo(i+1,j)-2*fo(i,j)+fo(i-1,j))...
                    +(D*dt/hy^2)*(fo(i,j+1)-2*fo(i,j)+fo(i,j-1))...
                    -dag(i,j)*condition;  %-dair(i,j)*condition;  % reaction-convection-diffusion model
        end
    end
    
    % record downstream
    pid_read(m) = sum(f(nx-1,:));  % sum over the last row to mimic PID downstream recordings
    
    % New time step
    t = t+dt;
    
end

% Solution
figure;
pcolor(x, y, f'); 
colorbar; shading interp; colormap(jet); 
title('numerical solution');
xlabel('x-axis [cm]'); ylabel('y-axis [cm]');

% time trace
figure;
plot(pid_read);
title('downstream readout');
xlabel('time'); ylabel('sum concentration');

% % Difference to analytical form
% figure;
% abserr = abs(f-fan);
% pcolor(x, y, abserr'); 
% colorbar; shading interp; colormap(jet); 
% title('absolute error');
% xlabel('x-axis [m]'); ylabel('y-axis [m]');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plotting for comparison
% once we have all three conditions:
%                                   wo_f for condition without agar
%                                   ne_f for condition with agar and not equilibrated yet
%                                   eq_f for condition after the PE protocol
% we can plot and compare profiles and boundary conditions
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plotornot = 0;
if plotornot == 1
%% compare spatial profiles
% use "f" from above with different conditions
figure();
subplot(131);pcolor(x, y, wo_f);shading interp; colormap(jet); set(gca,'FontSize',20); title('w/o agar')
subplot(132);pcolor(x, y, ne_f);shading interp; colormap(jet); set(gca,'FontSize',20); title('w/ agar')
subplot(133);pcolor(x, y, eq_f);shading interp; colormap(jet); set(gca,'FontSize',20); title('w/ agar + PE')
% colorbar; 
% xlabel('x-axis [cm]'); ylabel('y-axis [cm]');
set(gcf,'color','w');

%% individual profiles
figure;
pcolor(x, y, abs(wo_f - eq_f)); caxis([0,1]); shading interp; colormap(jet); set(gca,'FontSize',20); title('\Delta concentration')
colorbar; 
xlabel('x (cm)'); ylabel('y (cm)');
set(gcf,'color','w');

%% 
figure;
plot(y,wo_f(:,2)); hold on
plot(y,ne_f(:,2))
plot(y,eq_f(:,2))
xlabel('y (cm)'); ylabel('concentration'); title('upstream')
legend('w/o agar', 'w/ agar', 'w/ agar + PE')
set(gcf,'color','w');

figure;
plot(y,wo_f(:,end-1)); hold on
plot(y,ne_f(:,end-1))
plot(y,eq_f(:,end-1))
xlabel('y (cm)'); ylabel('concentration'); title('downstream')
legend('w/o agar', 'w/ agar', 'w/ agar + PE')
set(gcf,'color','w');

end
