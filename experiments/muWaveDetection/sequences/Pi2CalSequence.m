function Pi2CalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'Pi2Cal';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;
numsteps = 1;

numPi2s = 9; % number of odd numbered pi/2 sequences for each rotation direction

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q1; % choose target qubit here
IQkey = 'TekAWG12';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode);

pulseLib = containers.Map();
pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
for p = pulses
    pname = cell2mat(p);
    pulseLib(pname) = pg.pulse(pname);
end

sindex = 1;

% +X rotations
% QId
% (1, 3, 5, 7, 9, 11, 13, 15, 17, 19) x X90p
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('X90p');
    end
end
sindex = sindex + numPi2s + 1;

% -X rotations
% QId
% (1, 3, 5, 7, 9, 11, ...) x X90m
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('X90m');
    end
end
sindex = sindex + numPi2s + 1;

% +Y rotations
% QId
% (1, 3, 5, 7, 9, 11) x Y90p
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('Y90p');
    end
end
sindex = sindex + numPi2s + 1;

% -Y rotations
% QId
% (1, 3, 5, 7, 9, 11) x Y90m
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('Y90m');
    end
end

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
else
    error('Unable to find compiler for IQkey: %s',IQkey) 
end

end