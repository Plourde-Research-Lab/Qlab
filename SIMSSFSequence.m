function SIMSSFSequence(amp)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'SIMSSFSequence.py');
system(sprintf('python "%s" %f', scriptName, amp), '-echo');

end