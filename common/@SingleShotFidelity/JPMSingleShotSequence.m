function JPMSingleShotSequence(obj, jpm)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'JPMSingleShotSequence.py');
[status, result] = system(sprintf('python "%s" "%s" %s', scriptName, jpm), '-echo');

end