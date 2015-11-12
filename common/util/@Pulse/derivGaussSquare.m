function [outx, outy] = derivGaussSquare(params)

amp = params.amp;
n = params.width;
sigma = params.sigma;

numSigmas = 6; % currently hard coded to 6 sigma gaussians

passparams.amp = amp;
passparams.width = numSigmas*sigma/2;
passparams.sigma = sigma;

turnon = Pulse.derivGaussOn(passparams);
middle = amp*zeros(n-numSigmas*sigma, 1);
turnoff = Pulse.derivGaussOff(passparams);
outx = [turnon; middle; turnoff];
outy = zeros(n, 1);

end