function fpLengthSequence(length)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'fpLengthSequence.py');
[status, cmdout] = system(sprintf('python "%s" "%s" "%d"', scriptName, getpref('qlab', 'PyQLabDir'), length));
display(status)
display(cmdout)
end
