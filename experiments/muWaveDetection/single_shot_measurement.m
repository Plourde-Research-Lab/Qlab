function SSData = single_shot_measurement(qubit, expName)

deviceName = getpref('qlab', 'deviceName');
ExpParams.fileName = DataNamer.get_data_filename(deviceName, expName);

ExpParams.qubit = qubit;
% ExpParams.dataSource = strcat('M',qubit(2),'Demod');
ExpParams.dataSource = strcat('Demod');
%ExpParams.dataSource = 'Ch1X6'; 
ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
%Update some relevant parameters
ExpParams.numShots = 2000;
ExpParams.logisticRegression = false;
ExpParams.saveKernel = true;
ExpParams.optIntegrationTime = true;
ExpParams.setThreshold = 0; %0 = false; 1 = stream s_x1; 2 = stream s_x2;

ExpParams.zeroMean=0;
%Whether to auto-enable only the relevant AWGs
ExpParams.autoSelectAWGs = true;

%Whether to create the sequence (useful for using QGL instead)
ExpParams.createSequence = false;

ExpParams.sweeps = struct();
%sweep examples
% ExpParams.sweeps.AWGChannel = struct('type', 'AWGChannel', 'instr', 'APS22', 'channel', '1', 'mode', 'amp.', 'start', 0.98, 'stop', 1.02, 'step', 0.004);
%ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 6.354, 'stop', 6.355, 'step', 0.0001, 'instr', 'Autodyne_Mq3');
% ExpParams.sweeps.attenuation = struct('type', 'Attenuation', 'start', 10, 'stop', 30, 'step', 1, 'instr', 'Attenuator', 'channel', 2);
% ExpParams.sweeps.frequency = struct('type','Frequency', 'start', 5.4, 'stop', 5.5, 'step', 0.005, 'instr', 'HTCI');
% ExpParams.sweeps.power = struct('type','Power', 'start', 17, 'stop', 23, 'step', 0.5, 'instr', 'HTCI','units','dBm');
SSMeasurement = SingleShotFidelity();

SSMeasurement.Init(ExpParams);
SSData = SSMeasurement.Do();

% data = load_data('latest');
% 
% [M, I] = max(abs(data.data(:)));
% [i, j] = ind2sub(size(data.data), I);
% 
% 
% if data.dimension > 1
%     fprintf('Max fidelity of %f % found at %s = %f, %s = %f', M*100, data.xlabel, data.xpoints(i), data.ylabel, data.ypoints(j));
% else
%     fprintf('Max fidelity of %f found at %s = %f', M*100, data.xlabel, data.xpoints(i));
% end
end