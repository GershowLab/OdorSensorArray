load('fig1d_hex_data2.mat')
load('figSI_invese_hex_data.mat')
load('figSI_shallow_hex_data.mat')
ppms = flipud(ppms);
figure(1);
subplot(2,2,1); osa2hex(ppms); title('normalized - to be interped and gaussian smoothed')
subplot(2,2,2); osa2Interp(ppms,.5); title('sigma = .5 cm');subplot(2,2,3); osa2Interp(ppms,1); title('sigma = 1 cm');subplot(2,2,4); osa2Interp(ppms,1.5); title('sigma = 1.5 cm');
figure(2);
subplot(2,2,1); osa2hex(ppms); title('normalized - to be spline interped')
subplot(2,2,2); osa2SplineInterp(ppms,.01); title('s = .01');subplot(2,2,3); osa2SplineInterp(ppms,.1); title('s = .1');subplot(2,2,4); osa2SplineInterp(ppms,1); title('s = 1');
figure(3);
subplot(2,2,1); osa2hex(ppms,false); title ('unnormalized - to be interped and gaussian smoothed')
subplot(2,2,2); osa2Interp(ppms,.5,false); title('sigma = .5 cm');subplot(2,2,3); osa2Interp(ppms,1,false); title('sigma = 1 cm');subplot(2,2,4); osa2Interp(ppms,1.5,false); title('sigma = 1.5 cm');
figure(4);
subplot(2,2,1); osa2hex(ppms,false); title('unnormalized - to be spline interped')
subplot(2,2,2); osa2SplineInterp(ppms,.01,false); title('s = .01');subplot(2,2,3); osa2SplineInterp(ppms,.1,false); title('s = .1');subplot(2,2,4); osa2SplineInterp(ppms,1,false); title('s = 1');
