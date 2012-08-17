function RamseySequence()

fixedPt = 20000;

% setup PatternGen object with defaults
pg = PatternGen(...
    'dPiAmp', 6000, ... % amplitude for a pi pulse (8191 = full scale)
    'dPiOn2Amp', 3000, ... % amplitude for a pi/2 pulse
    'dSigma', 12, ... % width of gaussian pulse in samples (12 samples = 10 ns at 1.2 GS/s)
    'dPulseType', 'drag', ... % pulse shape: square, gauss, tanh, drag, etc
    'dDelta', -0.5, ... % DRAG pulse scale factor
    'correctionT', eye(2),... % mixer imperfection correction: 2x2 matrix applied to all I/Q pairs
    'bufferDelay', -24,... % relative delay of gating pulse in samples
    'bufferReset', 120,... % minimum spacing between gate pulses
    'bufferPadding', 24, ... % additional width of gate pulses
    'dBuffer', 4, ... % space between pulses
    'dPulseLength', 4*12, ... % pulse length, 4*12 gives a +/- 2sigma cutoff for Gaussian pulses
    'cycleLength', 21000, ... % total length of each pulse sequence
    'linkList', true, ... % enabled for use with APS
    'dmodFrequency', 0e6); % SSB modulation frequency in Hz

numsteps = 150;
stepsize = 120; % 100ns steps
delaypts = 0:stepsize:(numsteps-1)*stepsize;
patseq = {...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('X90p')
   };

% build the link lists
delay = -12; % relative analog I/Q channel delay (for aligning channels on various hardware platforms)
addGatePulses = false;
IQ_seq = pg.build(patseq, numsteps, delay, fixedPt, addGatePulses);

% plot sequence
figure
[ch1, ch2] = pg.linkListToPattern(IQ_seq, 20); % look at the 20th sequence
plot(ch1)
hold on
plot(ch2, 'r')

% export file Ramsey.h5
relpath = './';
basename = 'Ramsey';
APSPattern.exportAPSConfig(relpath, basename, IQ_seq);

end