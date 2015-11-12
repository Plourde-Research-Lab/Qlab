function PiRabiSequence(controlQ, targetQ, makePlot)
%PiRabiSequence Cross resonance Rabi width sequence with and without pi pulses on the control qubit.
% PiRabiSequence(controlQ, targetQ, makePlot)
%   controlQ - control qubit e.g. 'q1'
%   targetQ - target qubuit, e.g. 'q2'
%   makePlot - whether to plot a sequence or not (boolean)
%
% Example usage:
% PiRabiSequence('q1', 'q2', false)  

basename = 'PiRabi';
fixedPt = 4000;
nbrRepeats = 1;

numsteps = 80;

pg1 = PatternGen(controlQ);
pg2 = PatternGen(targetQ);
pgCR = PatternGen('CR', 'buffer', 0);

minWidth = 64;
% stepsize = 32;
stepsize = 8;
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;
% pulseLength = 160;
% angle = linspace(0, pi, numsteps);
angle = 1.193;
% amps = 3800:15:4985;
amps = 8000;


channelParams = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
clockCycle = max(channelParams.(controlQ).pulseLength+channelParams.(controlQ).buffer,...
                        channelParams.(targetQ).pulseLength+channelParams.(targetQ).buffer);
CRParams = channelParams.CR;

%%%%%%%%%%%%%% Regular %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
patSeq1 = {{pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('Xp')},...
            {pg1.pulse('QId')}};
patSeqCR = {...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('Utheta', 'angle', angle, 'width', pulseLength-4*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-2))), ...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('QId', 'width', clockCycle)};
patSeqCR = repmat({patSeqCR}, 1, 2);

patSeq2 = {{pg2.pulse('QId')}, {pg2.pulse('QId')}};

%%%%%%%%%%%%%% Refocussed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% patSeq1  = {...
%     {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('QId')},...
%     {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('Xp')}...
%     };
% patSeqCR = {...
%     pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', amps), ...
%     pgCR.pulse('Utheta', 'angle', angle, 'width', pulseLength-4*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-2))), ...
%     pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', clockCycle), ...
%     pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', amps), ...
%     pgCR.pulse('Utheta', 'angle', angle+pi, 'width', pulseLength-4*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-2))), ...
%     pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', amps), ...
%     pgCR.pulse('QId', 'duration', clockCycle) ...
%     };
% patSeqCR = repmat({patSeqCR}, 1, 2);
% 
% % patseq2 = {{pg2.pulse('U90p', 'angle', pi/2)}, {pg2.pulse('U90p', 'angle', pi/2)}};
% patSeq2 = {{pg2.pulse('X90p')}, {pg2.pulse('X90p')}};


calSeq1 = [];
calSeq2 = [];
calSeqCR = [];
% calSeq1 = {{pg1.pulse('QId')}, {pg1.pulse('QId')}};
% calSeq2 = {{pg2.pulse('QId')}, {pg2.pulse('Xp')}};
% calSeqCR = {{pgCR.pulse('QId')}, {pgCR.pulse('QId')}};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt);
patternDict = containers.Map();
if ~isempty(calSeq1), calSeq1 = {calSeq1}; end
if ~isempty(calSeq2), calSeq2 = {calSeq2}; end
if ~isempty(calSeqCR), calSeqCR = {calSeqCR}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey1 = qubitMap.(controlQ).IQkey;
IQkey2 = qubitMap.(targetQ).IQkey;
IQkeyCR = qubitMap.CR.IQkey;


patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patSeq1}, 'calseq', calSeq1, 'channelMap', qubitMap.(controlQ));
patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patSeq2}, 'calseq', calSeq2, 'channelMap', qubitMap.(targetQ));
patternDict(IQkeyCR) = struct('pg', pgCR, 'patseq', {patSeqCR}, 'calseq', calSeqCR, 'channelMap', qubitMap.CR);
measChannels = {'M1'};
awgs = {'TekAWG1', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

end
