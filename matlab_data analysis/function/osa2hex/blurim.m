function im = blurim (im, sigma)
%function im = blurim (im, sigma)
%gk = gaussKernel(sigma);
gk = exp(-([-10:0.5:10]).^2/2/sigma^2);
padsize = floor(length(gk)/2);
padim = padarray(im, [padsize padsize], 'replicate');

im = conv2(gk, gk, padim, 'valid');