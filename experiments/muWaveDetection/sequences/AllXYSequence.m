function AllXYSequence(varargin)

%varargin assumes qubit and then makePlot
qubit = 'q1';
makePlot = true;

if length(varargin) == 1
    qubit = varargin{1};
elseif length(varargin) == 2
    qubit = varargin{1};
    makePlot = varargin{2};
elseif length(varargin) > 2
    error('Too many input arguments.')
end

basename = 'AllXY';
fixedPt = 2000;
cycleLength = 4000;
nbrRepeats = 2;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

% ground state:
% QId
% Xp Xm
% Yp Ym
% Xp Xp
% Yp Yp
% Xp Yp
% Yp Xp
% Yp Xm
% Xp Ym

patseq{1}={pg.pulse('QId')};

patseq{2}={pg.pulse('Xp'),pg.pulse('Xm')};
patseq{3}={pg.pulse('Yp'),pg.pulse('Ym')};
patseq{4}={pg.pulse('Xp'),pg.pulse('Xp')};
patseq{5}={pg.pulse('Yp'),pg.pulse('Yp')};

patseq{6}={pg.pulse('Xp'),pg.pulse('Yp')};
patseq{7}={pg.pulse('Yp'),pg.pulse('Xp')};

patseq{8}={pg.pulse('Yp'),pg.pulse('Xm')};
patseq{9}={pg.pulse('Xp'),pg.pulse('Ym')};

% superposition state:
% -1 * eps error
% X90p
% Y90p
% X90m
% Y90m

% 0 * eps error (phase sensitive)
% X90p Y90p
% Y90p X90p
% X90m Y90m
% Y90m X90m

% +1 * eps error
% Xp Y90p
% Yp X90p
% Xp Y90m
% Yp X90m
% X90p Yp (phase sensitive)
% Y90p Xp (phase sensitive)

% +3 * eps error
% Xp X90p
% Yp Y90p
% Xm X90m
% Ym Y90m

patseq{10}={pg.pulse('X90p')};
patseq{11}={pg.pulse('Y90p')};
patseq{12}={pg.pulse('X90m')};
patseq{13}={pg.pulse('Y90m')};

patseq{14}={pg.pulse('X90p'), pg.pulse('Y90p')};
patseq{15}={pg.pulse('Y90p'), pg.pulse('X90p')};
patseq{16}={pg.pulse('X90m'), pg.pulse('Y90m')};
patseq{17}={pg.pulse('Y90m'), pg.pulse('X90m')};


patseq{18}={pg.pulse('Xp'),pg.pulse('Y90p')};
patseq{19}={pg.pulse('Yp'),pg.pulse('X90p')};
patseq{20}={pg.pulse('Xp'),pg.pulse('Y90m')};
patseq{21}={pg.pulse('Yp'),pg.pulse('X90m')};
patseq{22}={pg.pulse('X90p'),pg.pulse('Yp')};
patseq{23}={pg.pulse('Y90p'),pg.pulse('Xp')};


patseq{24}={pg.pulse('Xp'),pg.pulse('X90p')};
patseq{25}={pg.pulse('Yp'),pg.pulse('Y90p')};
patseq{26}={pg.pulse('Xm'),pg.pulse('X90m')};
patseq{27}={pg.pulse('Ym'),pg.pulse('Y90m')};

% excited state;
% Xp
% Xm
% Yp
% Ym
% X90p X90p
% X90m X90m
% Y90p Y90p
% Y90m Y90m

patseq{28} = {pg.pulse('QId'),pg.pulse('Xp')};
patseq{29} = {pg.pulse('QId'),pg.pulse('Xm')};
patseq{30} = {pg.pulse('QId'),pg.pulse('Yp')};
patseq{31} = {pg.pulse('QId'),pg.pulse('Ym')};

patseq{32} = {pg.pulse('X90p'),pg.pulse('X90p')};
patseq{33} = {pg.pulse('X90m'),pg.pulse('X90m')};
patseq{34} = {pg.pulse('Y90p'),pg.pulse('Y90p')};
patseq{35} = {pg.pulse('Y90m'),pg.pulse('Y90m')};

calseq=[];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS'};

plotSeqNum = 10;

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);

end