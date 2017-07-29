function StateCalibrationSequence(obj, jpm)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'StateCalibrationSequence.py');
[status, result] = system(sprintf('python "%s" "%s" %s', scriptName, jpm), '-echo');

end