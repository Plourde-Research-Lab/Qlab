function SNRData = snr_measurement(qubit, expName)

deviceName = getpref('qlab', 'deviceName');
ExpParams.fileName = DataNamer.get_data_filename(deviceName, expName);

ExpParams.qubit = qubit;

ExpParams.dataSource = 'Demod';

ExpParams.saveInt = false;
ExpParams.intDataSource = 'Integrate';
ExpParams.plotMode = 'real/imag';

ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 20;
ExpParams.numAvg = 1;
%Whether to auto-enable only the relevant AWGs
ExpParams.autoSelectAWGs = false;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = false;
ExpParams.sequenceName = 'MEAS';

ExpParams.sweeps = struct();
%sweep examples
% ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'APS21', 'channel', '2', 'mode', 'amp.', 'start', .05, 'stop', .5, 'step', 0.05);
ExpParams.sweeps.repeat = struct('type','Repeat', 'numRepeats', 50, 'delay', 0);
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.354, 'stop', 6.355, 'step', 0.0001, 'instr', 'Autodyne_Mq3');
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.359, 'stop', 6.361, 'step', 0.0002, 'instr', 'JPApump');
%ExpParams.sweeps.power = struct('type','Power', 'start', 2.3, 'stop', 2.7, 'step', 0.025, 'instr', 'JPApump','units','dBm');

SNRMeasurement = SNRFidelity();

SNRMeasurement.Init(ExpParams);
SNRData = SNRMeasurement.Do();
end