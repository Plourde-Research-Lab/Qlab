function continuousWave()
%
% hard coded continuous wave form the aps channels 3 and 4
% with a microwave tone form the top Agilent
% usage: >> continuousWave()
%
aps = APS();
ag = deviceDrivers.AgilentN5183A();
% ag = deviceDrivers.AgilentE8257D();

instrLibrary = json.read(getpref('qlab', 'CurScripterFile'));
instrSettings = instrLibrary.instruments.('Scope');
scope = InstrumentFactory('Scope', instrSettings);
scope.setAll(instrSettings);

scope

channelA = 3;
channelB = 4;

ag.connect(30);
% aps.connect('A6001ixV');
aps.connect('A6001nBT');
aps.stop();

% create the wave form
ssbFreq = 10000000;
waveformLength = 1200;

tpts = (1/1200000000)*(0:(waveformLength-1));
iwf = 0.5 * cos(2*pi*ssbFreq*tpts);
qwf = -0.5 * sin(2*pi*ssbFreq*tpts);
aps.setAmplitude(channelA, .5);
aps.setAmplitude(channelB, .5);
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

ag.frequency = 10;
ag.power = 13.0;
ag.output = 1;
ag.pulse = 0;

scope.acquire();

% wait for user input
% headbutt keyboard
pause;

scope.stop();

figure;plot(scope.transfer_waveform(1));

% shut things down
ag.output = 0;
ag.disconnect();
delete(ag);
aps.stop();
aps.disconnect();
delete(aps);

scope.disconnect;scope.delete;

end