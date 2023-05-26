% Equilibrium protocol
mfc_fname1 = '20200306160040_MFCPID_equilibrate.txt';
mfc_fname2 = '20200306170705_MFCPID_equilibrate2.txt';

mfc_table1 = readtable(mfc_fname1);  %ms timer | PID | MFC-command | MFC-read
mfc_table2 = readtable(mfc_fname2);
time_mfc = mfc_table.Var1;
time_mfc = (time_mfc-time_mfc(1))/1000;  % ms ticks
PID1 = mfc_table1.Var2;
MFC_read1 = mfc_table1.Var4;
PID2 = mfc_table2.Var2;
MFC_read2 = mfc_table2.Var4;
mfc = [MFC_read1; MFC_read2];
pid = [PID1; PID2];

%%
figure()
plot(mfc); hold on; plot(pid)

%% Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
%  time structure
dt = .1;
T = 200;
time = 0:dt:T;
lt = length(time);
% odor control
q = zeros(1,lt);
q(50:end) = 1;
% physical parameters
c1 = 110;  %concentration of odor
phi = 1;  % influx ratio
tau = 1;  %decay time scale
ka = 1e-2;  %association constant
kd = 1e-1;  %dessociation constant
Max_the = 1000;  %saturation concentration
w = 1;  %with or without plate
% initialize
c2 = zeros(1,lt);
the = zeros(1,lt);
% dynamics
for tt = 1:lt-1
    dthdt = w*ka*c2(tt)*(Max_the-the(tt)) - kd*the(tt);  %surface interation
    temp = the(tt) + dt*dthdt;
    temp = min(Max_the,temp);  %cap ratio
    temp = max(0,temp);  %positive ration
    the(tt+1) = temp;
    c2(tt+1) = c2(tt) + dt*( q(tt)*phi*c1 - 1/tau*c2(tt) - w*dthdt );  %dynamics
    if tt>150
        c1 = 11;
        q(tt) = 2;
    end
end

%plotting
figure()
subplot(4,1,1:2)
plot(time, c2);  ylabel('[odor]')
subplot(4,1,3)
plot(time, the);  ylabel('\theta')
subplot(4,1,4)
plot(time, q);  ylabel('q');  xlabel('time'); axis([0,max(time), 0, max(q)+0.2])

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% opterations
%  time structure
dt = .1;
T = 250;
time = 0:dt:T;
lt = length(time);
% odor control
q = zeros(1,lt);
q(50:end) = 1;
% physical parameters
c1 = 110;%150;  %concentration of odor
targC = 7.5;
phi = 1;  % influx ratio
tau = 1.;  %decay time scale
ka = 1e-3;  %association constant  8
kd = 1e-1;  %dessociation constant  4
Max_the = 15000;  %saturation concentration
w = 1;  %with or without plate
% initialize
c2 = zeros(1,lt);
the = zeros(1,lt);
% dynamics
for tt = 1:lt-1
    dthdt = w*ka*c2(tt)*(Max_the-the(tt)) - kd*the(tt);  %surface interation
    temp = the(tt) + dt*dthdt;
%     temp = min(Max_the,temp);  %cap ratio
%     temp = max(0,temp);  %positive ration
    the(tt+1) = temp;
    c2(tt+1) = c2(tt) + dt*( q(tt)*phi*c1 - 1/tau*c2(tt) - w*dthdt );  %dynamics
    if tt>150
        c1 = targC;
        q(tt) = 2;
    end
end

figure()
plot(time, c2)

%% subplots
target = max(c2_wo);  %target w/o agar
figure()
subplot(131)
plot(time, c2_wo', 'Linewidth',3); %hold on; plot([0,250],[target,target],'--','Color',uint8([170 170 170]),'Linewidth',3)
xlabel('time'); ylabel('ppm');  legend('target','time trace');
xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20);  
subplot(132)
plot(time, c2_ne', 'Linewidth',3); %hold on; plot([0,250],[target,target],'--','Color',uint8([170 170 170]),'Linewidth',3)
xlabel('time'); xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20); 
subplot(133)
plot(time, c2_eq, 'Linewidth',3); %hold on; plot([0,250],[target,target],'--','Color',uint8([170 170 170]),'Linewidth',3)
xlabel('time'); xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20); 
set(gcf,'color','w');

%%
ccs = ['r','g','b'];
figure()
for ii = 1:3
    subplot(131)
    target = max(c2_wo(ii,:));
    plot(time, c2_wo(ii,:), 'Color', ccs(ii), 'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',1)
    xlabel('time'); ylabel('ppm');  legend('target','time trace');
    xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20);  
    subplot(132)
    plot(time, c2_ne(ii,:), 'Color', ccs(ii), 'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',1)
    xlabel('time'); xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20); 
    subplot(133)
    plot(time, c2_eq(ii,:), 'Color', ccs(ii), 'Linewidth',3); hold on; plot([0,250],[target, target],'--','Color', ccs(ii),'Linewidth',1)
    xlabel('time'); xlim([0,250]); ylim([0,225]); set(gca,'Fontsize',20); 
    set(gcf,'color','w');
end

%% 2-D flow pattern calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xx = linspace(0,15,433);
yy = linspace(-7,7,375);
[X,Y] = meshgrid(xx,yy);
v = 0.5;   %flow in chamber
D = 0.08;  %MEK
Def = D*(1 + 6.25^2/7.5);  %effective diffusion
C0 = 300;  %initial odor source
% Z = C0/2*(1-erf(Y.^2 ./ (2*sqrt(Def.*X./v)) ));  %1D
Z = C0/1*(1-erf(X ./ (2*sqrt(Def.*X./v)*10) )) .* exp(-Y.^2./(4*Def*X./v));  %combine
% Z = C0./(4*pi*Def.*X./v).^0.1 .*(1-erf(Y.^2./(4*Def*X./v)*1));   %solve with BC!!!

figure;
imagesc(Z)

%% flow sim
agar_bc = @(gamma, Z) (gamma(1).*exp(-Z./gamma(2)) + 1).*(1/gamma(2)) .* Z; 
Z_agar = Z';
Z_agar(86:end-86,57:end-57) = agar_bc([2,2],Z_agar(86:end-86,57:end-57));
figure
subplot(121); imagesc([1:size(Z,2)]*14/size(Z,2), [1:size(Z,1)]*12/size(Z,1),Z)
subplot(122); imagesc([1:size(Z,2)]*14/size(Z,2), [1:size(Z,1)]*12/size(Z,1), Z_agar');

%% numerical!
%%
%Specifying parameters
nx = 14*5;                          %Number of steps in space(x)
ny = 12*5;                          %Number of steps in space(y)->in a 90mm plate
nt = 200;                         %Number of time steps 
dt = 0.01;                        %Width of each time step
dx = 1/(nx-1);                    %Width of space step(x)
dy = 1/(ny-1);                    %Width of space step(y)
x = (0:dx:1)*14;                   %Range of x(0,9) and specifying the grid points
y = (0:dy:1)*12-6;                   %Range of y(0,9) and specifying the grid points
u = zeros(nx,ny);                 %Preallocating u
un = zeros(nx,ny);                %Preallocating un
vis = 0.081*1/dt;                    %Diffusion coefficient/viscocity   %%%MEK diffiusion coefficient in air
% UW=0;                             %x=0 Dirichlet B.C 
% UE=0;                             %x=L Dirichlet B.C 
% US=0;                             %y=0 Dirichlet B.C 
% UN=0;                             %y=L Dirichlet B.C 
UnW=0.;                            %x=0 Neumann B.C (du/dn=UnW) west
UnE=0;                            %x=L Neumann B.C (du/dn=UnE) east
UnS=0;                            %y=0 Neumann B.C (du/dn=UnS) south
UnN=0;                            %y=L Neumann B.C (du/dn=UnN) north
UnU=0;                            %z=0 Neumann B.C (du/dn=UnU) up
UnD=0;                            %z=L Neumann B.C (du/dn=UnD) down

vv = 0.5/dt;  %flow

%%
%Initial Conditions
C0 = 2;  %initial concentration

X0 = [0,0.5,-0.5,0.5]; %[4.,5.,0.0,0.25];  %butanone plug
% for i=1:nx
%     for j=1:ny
%         for k=1:nz
%             if ((X0(1)<=y(j)) & (y(j)<=X0(2)) & ...
%                 (X0(1)<=x(i)) & (x(i)<=X0(2)) & ...
%                 (X0(3)<=z(k)) & (z(k)<=X0(4)) )
%                 u(i,j,k)=C0;
%             else
%                 u(i,j,k)=0;
%             end
%         end
%     end
% end
xx = find(X0(1)<=x & X0(2)>=x);
yy = find(X0(3)<=y & X0(4)>=y);
u(xx,yy) = C0;
u0 = u;  %initial condition

%%
%B.C vector
bc=zeros(nx-2,ny-2);
% bc(1,:)=UW/dx^2; bc(nx-2,:)=UE/dx^2;  %Dirichlet B.Cs
% bc(:,1)=US/dy^2; bc(:,ny-2)=UN/dy^2;  %Dirichlet B.Cs
bc(1,:)=-UnW/dx; bc(nx-2,:)=UnE/dx;  %Neumann B.Cs
bc(:,1)=-UnS/dy; bc(:,ny-2)=UnN/dy;  %Neumann B.Cs
%B.Cs at the corners:
% bc(1,1)=UW/dx^2+US/dy^2;    bc(nx-2,1)=UE/dx^2+US/dy^2;
% bc(1,ny-2)=UW/dx^2+UN/dy^2; bc(nx-2,ny-2)=UE/dx^2+UN/dy^2;
% bc(1,1,1)=0;  bc(nx-2,1,1)=0;  bc(1,nx-2,1)=0; bc(1,1,nx-2)=0;
% bc(nx-2,nx-2,1)=0; bc(nx-2,1,nx-2)=0; bc(1,nx-2,nx-2)=0; bc(nx-2,nx-2,nx-2)=0;
% bc=vis*dt*bc;
%Calculating the coefficient matrix for the implicit scheme
Ex=sparse(2:nx-2, 1:nx-3, 1, nx-2, nx-2);
%Ax=Ex+Ex'-2*speye(nx-2);        %Dirichlet B.Cs
Ax(1,1)=-1; Ax(nx-2,nx-2)=-1;  %Neumann B.Cs
Ey=sparse(2:ny-2,1:ny-3,1,ny-2,ny-2);
%Ay=Ey+Ey'-2*speye(ny-2);        %Dirichlet B.Cs
Ay(1,1)=-1; Ay(ny-2,ny-2)=-1;  %Neumann B.Cs
%A=kron(Ay/dy^2,speye(nx-2))+kron(speye(ny-2),Ax/dx^2)+kron();
%D=speye((nx-2)*(ny-2))-vis*dt*A;

% e=ones(n,1); I=speye(n);
% L1=(alpha/(h^2))*spdiags([e -2*e e],-1:1,n,n);
% L = kron(L1,kron(I,kron(L1,I))+kron(I,kron(I,L1)));
% L = L + kron(L1,kron(I,I));
% A = kron();
%%
%Calculating the field variable for each time step for 3-D diffusion
u = u0;
figure;
for it=0:nt
    un=u;
    %h=surf(x,y,squeeze(u(:,:,3))','EdgeColor','none');       %plotting the field variable
    %h=surf(squeeze(u(:,:,4))','EdgeColor','none');       %plotting the field variable
    [X,Y] = ndgrid(1:size(u,1), 1:size(u,2));
    pointsize = 3;
    h = scatter(X(:), Y(:), pointsize, u(:));
    %h = slice(X,Y,Z,u,1,[],[],'nearest');
    shading interp
    %axis ([0 9 0 9 0 2])
    title({['3-D Diffusion with {\nu} = ',num2str(vis)];['time (\itt) = ',num2str(it*dt)]})
    xlabel('Spatial co-ordinate (x) \rightarrow')
    ylabel('{\leftarrow} Spatial co-ordinate (y)')
    zlabel('Transport property profile (u) \rightarrow')
    colormap jet
    colorbar;
    drawnow; 
    refreshdata(h)
    %Uncomment as necessary
    %Implicit method:
    %{
    U=un;U(1,:)=[];U(end,:)=[];U(:,1)=[];U(:,end)=[];
    U=reshape(U+bc,[],1);
    U=D\U;
    U=reshape(U,nx-2,ny-2);
    u(2:nx-1,2:ny-1)=U;
    %Boundary conditions
    %Dirichlet:
%     u(1,:)=UW;
%     u(nx,:)=UE;
%     u(:,1)=US;
%     u(:,ny)=UN;
    %Neumann:
    u(1,:)=u(2,:)-UnW*dx;
    u(nx,:)=u(nx-1,:)+UnE*dx;
    u(:,1)=u(:,2)-UnS*dy;
    u(:,ny)=u(:,ny-1)+UnN*dy;
    %}
    %Explicit method:{
    for i=2:nx-1
        for j=2:ny-1
                u(i,j)=un(i,j)+(vis*dt*(un(i+1,j)-2*un(i,j)+un(i-1,j))/(dx*dx)) + (-vv*dt*(un(i+1,j)-un(i-1,j))/2)/dx + ...
                (vis*dt*(un(i,j+1)-2*un(i,j)+un(i,j-1))/(dy*dy));
            
        end
    end
    %Boundary conditions
    %Dirichlet:
%     u(1,:)=UnW;
%     u(nx,:)=UnE;
%     u(:,1)=UnS;
%     u(:,ny)=UnN;
    %Neumann:
%     u(1,:,:)=u(2,:,:)-UnW*dx;
%     u(nx,:,:)=u(nx-1,:,:)+UnE*dx;
%     u(:,1,:)=u(:,2,:)-UnS*dy;
%     u(:,ny,:)=u(:,ny-1,:)+UnN*dy;
%     u(:,:,1)=u(:,:,2)-UnU*dz;
%     u(:,:,nz)=u(:,:,nz-1)+UnD*dz;
    %}
    %modified boundary condition
    k = 0.1; %leakage
    A = -3.5*10^-11;  B = 1/3.19;  %effective evaporation
    u(1,:)=u(2,:)-k*u(1,:)*dx;
    u(nx,:)=u(nx-1,:)+-100*u(nx,:)*dx;
    u(:,1)=u(:,2)-k*u(:,1)*dy;
    u(:,ny)=u(:,ny-1)-k*u(:,ny)*dy;
    u(xx,yy) = C0;
    u(find(u<0)) = 0;
end
