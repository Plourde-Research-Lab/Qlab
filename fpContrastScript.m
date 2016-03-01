%% Sweep through pulse widths, calculate contrast

contrastData = [];
brightData = [];
darkData = [];


mainfig = figure;
contrastfig = figure;
title('Fast Pulse Contrast');

start = 10;
final = 300;
step = 10;

for length = start:step:final
   
    %% Compile new Pulses
    fpLengthSequence(length);
    
%     % Pick Bright Experiment Settings
%     setpref('qlab', 'curScripterFile', 'C:/Users/Caleb/Development/pyqlab/BrightExpSettings.json');
    
    %% Run Experiment
    ExperimentName = ['Bright_' num2str(length) 'ns'];
    display(ExperimentName);
    JPMExpScripter(ExperimentName, 'bright');
    
    %% Load BrightData, append
    brightcurve = load_jpm_data('latest');
    brightData = [brightData brightcurve.data];
    
    figure(contrastfig);
    plot(brightcurve.xpoints, brightcurve.data)
    
    %% Pick Dark Experiment Settings
%     setpref('qlab', 'curScripterFile', 'C:/Users/Caleb/Development/pyqlab/DarkExpSettings.json');
    
    %% Run Experiment
    ExperimentName = ['Dark_' num2str(length) 'ns'];
    display(ExperimentName);
    JPMExpScripter(ExperimentName, 'dark');
    
    %% Load BrightData, append
    darkcurve = load_jpm_data('latest');
    darkData = [darkData darkcurve.data];
    
    figure(contrastfig); hold all;
    plot(darkcurve.xpoints, darkcurve.data, darkcurve.xpoints, brightcurve.data-darkcurve.data)
    
    contrastData = [contrastData brightcurve.data-darkcurve.data];
    
    %% Adjust Plot
    figure(mainfig);
    imagesc(start:step:length, darkcurve.xpoints, contrastData);
    title('Fast Pulse Contrast');
    
    %% Upload to Plotly
    
%     pause(1);
%     fig2plotly(mainfig, 'filename', 'JPM/FP Contrast', 'open', false);
    
end