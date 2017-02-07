function continuousWave()
%
% hard coded continuous wave form the aps channels 3 and 4
% with a microwave tone form the top Agilent
% usage: >> continuousWave()
%
aps = APS2();

% ag = deviceDrivers.Agilent();
ag = deviceDrivers.AgilentE8257D();


ag.connect(6);

aps.connect('192.168.2.4');
% aps.connect('A6001nBT');
aps.stop();

% create the wave form
ssbFreq = 10*1e6;
waveformLength = 1200;

tpts = (1/1200000000)*(0:(waveformLength-1));
iwf = 0.5 * cos(2*pi*ssbFreq*tpts);
qwf = -0.5 * sin(2*pi*ssbFreq*tpts);

aps.set_channel_scale(1, .5);
aps.set_channel_scale(2, .5);
% aps.setOffset(1, -.01825);
% aps.setOffset(2, 0);
aps.load_waveform(1, qwf);
aps.load_waveform(2, iwf);


% for ct = 1:4 
%     aps.setRunMode(ct, aps.RUN_WAVEFORM);
%     aps.setRepeatMode(ct, aps.CONTINUOUS);
% end

aps.set_channel_enabled(1, true);
aps.set_channel_enabled(2, true);

aps.run()

<<<<<<< HEAD
ag.frequency = 6;
=======
ag.frequency = 6.4;
>>>>>>> d9d59ff326e4eca46a8fbb459801121500e91620
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