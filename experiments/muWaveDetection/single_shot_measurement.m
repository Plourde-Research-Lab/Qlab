function SSData = single_shot_measurement(qubit, expName)

deviceName = getpref('qlab', 'deviceName');
ExpParams.fileName = DataNamer.get_data_filename(deviceName, expName);

ExpParams.qubit = qubit;
% ExpParams.dataSource = strcat('M',qubit(2),'Demod');
ExpParams.dataSource = strcat('Demod');
%ExpParams.dataSource = 'Ch1X6';
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 1000;
ExpParams.logisticRegression = false;
ExpParams.saveKernel = true;
ExpParams.optIntegrationTime = true;
ExpParams.setThreshold = 1; %0 = false; 1 = stream s_x1; 2 = stream s_x2;

ExpParams.zeroMean=0;
%Whether to auto-enable only the relevant AWGs
ExpParams.autoSelectAWGs = true;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = true;

ExpParams.sweeps = struct();
%sweep examples
% ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'APS22', 'channel', '1', 'mode', 'amp.', 'start', 0.98, 'stop', 1.02, 'step', 0.004);
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.354, 'stop', 6.355, 'step', 0.0001, 'instr', 'Autodyne_Mq3');
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.359, 'stop', 6.361, 'step', 0.0002, 'instr', 'JPApump');
%ExpParams.sweeps.power = struct('type','Power', 'start', 2.3, 'stop', 2.7, 'step', 0.025, 'instr', 'JPApump','units','dBm');

SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();
end