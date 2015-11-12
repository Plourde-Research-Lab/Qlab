function continuousWave()
%
% hard coded continuous wave form the aps channels 3 and 4
% with a microwave tone form the top Agilent
% usage: >> continuousWave()
%
aps = APS();
%ag = deviceDrivers.AgilentN5183A();
ag = deviceDrivers.AgilentE8257D();


ag.connect(6);
aps.connect('A6001ixV');
aps.stop();

% create the wave form
ssbFreq = 19000000;
waveformLength = 1200;

tpts = (1/1200000000)*(0:(waveformLength-1));
iwf = 0.5 * cos(2*pi*ssbFreq*tpts);
qwf = -0.5 * sin(2*pi*ssbFreq*tpts);
aps.setAmplitude(2, 1.0);
aps.setAmplitude(1, 1.0);
aps.setOffset(1, -0.0082);
aps.setOffset(2, -0.0132);
aps.loadWaveform(2, qwf);
aps.loadWaveform(1, iwf);
 
for ct = 1:4
    aps.setRunMode(ct, aps.RUN_WAVEFORM);
    aps.setRepeatMode(ct, aps.CONTINUOUS);
end

aps.setEnabled(2, 2);
aps.setEnabled(1, 1);

aps.run()

ag.frequency = 8;
ag.power = 18.0;
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