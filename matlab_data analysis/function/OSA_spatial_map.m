function MAP = OSA_spatial_map(OSA_raw)
%%%
%input OSA_raw as rows x columns of multiple OSBs concatenated in
%two-columns per bar already
%return 16 x 2*OSBs full space with interpolation
%%%

%%% interpolation step
    inter = zeros(size(OSA_raw));  %all interpolated values
    OSA_BD = [ [OSA_raw(1,1) OSA_raw(1,:) OSA_raw(1,end)] ; [OSA_raw(:,1) OSA_raw OSA_raw(:,end)]; [OSA_raw(end,1) OSA_raw(end,:) OSA_raw(end,end)] ];  %map with boundary conditions
    for ii = 2:size(OSA_BD,1)-1
        for jj = 2:size(OSA_BD,2)-1
            M = zeros(size(OSA_BD));  %using the 2D convolution kernel method
            M(ii,jj) = 1; 
            meanval = median(median(  OSA_BD(conv2(M,[1,1,1;1,0,1;1,1,1],'same')>0)  ));
            inter(ii-1,jj-1) = meanval;
        end
    end
    
%%% intersect step
    check = checkerboard(1,8,size(OSA_raw,2));
    check = check(:,1:end/2);
    MAP = zeros(size(check));
    MAP(check==1) = inter;
    MAP(check==0) = OSA_raw;
end