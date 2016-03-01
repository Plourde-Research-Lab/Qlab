function RBoverlaps(varargin)

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

basename = 'RBoverlaps';
fixedPt = 15000; %15000
cycleLength = 25000; %19000
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

for ct = 1:8
    
    % load in random Clifford sequences from text file
    FID = fopen(['RB-interleave-X90p-overlap' num2str(ct) '.txt']);
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
                pulseLibrary(pulseName) = pg.pulse(pulseName);
            end
            currentSeq{jj} = pulseLibrary(pulseName);
        end
        patseq{ii} = currentSeq(1:jj);
    end

    calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};


    compiler = ['compileSequence' IQkey];
    compileArgs = {basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot, 64, ['_' num2str(ct)]};
    if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
        feval(compiler, compileArgs{:});
    end

end

end