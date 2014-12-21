function continuousWave_2()

% hard coded continuous wave form the aps channels 3 and 4
% with a microwave tone form the top Agilent

aps = deviceDrivers.APS();

%Generator info
ag = deviceDrivers.AgilentE8257D();
ag.connect(6);


aps.connect('A6001ixV');
aps.stop();

% create the wave form
ssbFreq = 19000000;
waveformLength = 1200;

tpts = (1/1200000000)*(0:(waveformLength-1));
iwf = 1.0 * cos(2*pi*ssbFreq*tpts);
qwf = -1.0 * sin(2*pi*ssbFreq*tpts);
aps.setAmplitude(4, 0.5);
aps.setAmplitude(3, 0.5);
aps.setOffset(3, 0.05);
aps.setOffset(4, 0.0231);
aps.loadWaveform(4, qwf);
aps.loadWaveform(3, iwf);
 
for ct = 1:4
    aps.setRunMode(ct, aps.RUN_WAVEFORM);
    aps.setRepeatMode(ct, aps.CONTINUOUS);
end

%Mixer Channel 
aps.setEnabled(4, 4);
aps.setEnabled(3, 3);

aps.run()

%generator settings
ag.frequency = 6.94856;
ag.power = 18;
ag.output = 1;
ag.pulse = 0;

% wait for user input
% headbutt keyboard
pause;

% shut things down
ag.output = 0;
ag.disconnect();
delete(ag);
aps.stop();
aps.disconnect();
delete(aps);

end