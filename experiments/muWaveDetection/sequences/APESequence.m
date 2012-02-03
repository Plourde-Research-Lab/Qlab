function APESequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'APE';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q2; % choose target qubit here
IQkey = 'TekAWG34';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode);

angle = pi/2;
numPsQId = 4; % number pseudoidentities
numsteps = 11; %number of drag parameters (11)
deltamax=0.0;
deltamin=-1.0;
delta=linspace(deltamin,deltamax,numsteps);

sindex = 0;
% QId
% N applications of psuedoidentity
% X90p, (sequence of +/-X90p), U90p
% (1-numPsQId) of +/-X90p
for i=1:numsteps
    sindex=sindex+1;
    patseq{sindex} = {pg.pulse('QId')};
    for j = 1:numPsQId
        patseq{sindex + j} = {pg.pulse('X90p', 'delta', delta(i))};
        for k = 1:j
            patseq{sindex + j}(2*k:2*k+1) = {pg.pulse('X90p','delta',delta(i)),pg.pulse('X90m','delta',delta(i))};
        end
        patseq{sindex+j}{2*(j+1)} = pg.pulse('U90p', 'angle', angle, 'delta', delta(i));
    end
    sindex = sindex + numPsQId;
end

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot, 10};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end

end