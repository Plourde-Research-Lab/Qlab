function [metainfo, segmentPoints] = SPAMChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'SPAM.py');
[status, result] = system(sprintf('python "%s" %s', scriptName, qubit), '-echo');

numPsId = 10; % number pseudoidentities
numAngles = 9;
segmentPoints = 1:numPsId*(1 + numAngles);

metainfo = obj.getMetaInfo('SPAM');

end
