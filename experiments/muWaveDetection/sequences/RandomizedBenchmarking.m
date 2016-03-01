function RandomizedBenchmarking(qubit, makePlot)

basename = 'RB';

fixedPt = 12000;
nbrRepeats = 1;
introduceError = 0;
errorAmp = 0.2;

pg = PatternGen(qubit);

% load in random Clifford sequences from text file
% FID = fopen('RBsequences-long.txt');
FID = fopen('RB_ISeqs.txt');
%FID = fopen('RBsequences.txt');
% FID = fopen('RB-interleave-Y90p.txt');
if ~FID
    error('Could not open Clifford sequence list')
end

%Read in each line
tmpArray = textscan(FID, '%s','delimiter','\n');
fclose(FID);
%Split each line
seqStrings = cellfun(@(x) textscan(x,'%s'), tmpArray{1});

% convert sequence strings into pulses
pulseLibrary = containers.Map();
for ii = 1:length(seqStrings)
    for jj = 1:length(seqStrings{ii})
        pulseName = seqStrings{ii}{jj};
        if ~isKey(pulseLibrary, pulseName)
            % intentionally introduce an error in one of the
            % pulses, if desired
            if introduceError && strcmp(pulseName, 'X90p')
                pulseLibrary(pulseName) = pg.pulse('Xtheta', 'amp', qParams.pi2Amp*(1+errorAmp));
            else
                pulseLibrary(pulseName) = pg.pulse(pulseName);
            end
        end
        currentSeq{jj} = pulseLibrary(pulseName);
    end
    patseq{ii} = currentSeq(1:jj);
end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt);

patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = getpref('qlab','MeasCompileList');
awgs = getpref('qlab','AWGCompileList');

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);


end