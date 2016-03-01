function resetLengthSequence(length)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'resetLengthSequence.py');
[status, cmdout] = system(sprintf('python "%s" "%s" "%d"', scriptName, getpref('qlab', 'PyQLabDir'), length));

end
