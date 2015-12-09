function continuousWave()
%
% hard coded continuous wave form the aps channels 3 and 4
% with a microwave tone form the top Agilent
% usage: >> continuousWave()
%
aps = APS();
% ag = deviceDrivers.AgilentN5183A();
% ag = deviceDrivers.AgilentE8257D();

channelA = 1;
channelB = 2;


% ag.connect(30);
% aps.connect('A6001ixV');
aps.connect('A6001nBT');
aps.stop();

% create the wave form
ssbFreq = 13000000;
waveformLength = 1200;

tpts = (1/1200000000)*(0:(waveformLength-1));
iwf = 0.5 * cos(2*pi*ssbFreq*tpts);
qwf = -0.5 * sin(2*pi*ssbFreq*tpts);
aps.setAmplitude(channelA, 1.0);
aps.setAmplitude(channelB, 1.0);
aps.setOffset(channelA, 0); 
aps.setOffset(channelB, 0);
aps.loadWaveform(channelA, qwf);
aps.loadWaveform(channelB, iwf);
 
for ct = 1:4
    aps.setRunMode(ct, aps.RUN_WAVEFORM);
    aps.setRepeatMode(ct, aps.TRIGGERED);
%     aps.setTriggerDelay(ct, 1);
end

aps.setEnabled(channelA, true);
aps.setEnabled(channelB, true);

aps.run()

% ag.frequency = 8;
% ag.power = 18.0;
% ag.output = 1;
% ag.pulse = 0;

% wait for user input
% headbutt keyboard
pause;

% shut things down
% ag.output = 0;
% ag.disconnect();
% delete(ag);
aps.stop();
aps.disconnect();
delete(aps);

end