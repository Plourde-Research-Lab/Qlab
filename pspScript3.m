%% Sweep through pulse widths, run frequency scan at each width

phData = [];


fig = figure;
title('Photon Oscillation 1MHz detuned');

start = .1;
final = 2;
step = .1;

for delay = start:step:final
   
    %% Compile new Pulses
    measLengthSequence(delay);

    %% Run Experiment
    ExperimentName = ['PhotonOscillation' num2str(delay) 'us'];
    display(ExperimentName);
    
    JPMExpScripter(ExperimentName);
    
    %% Load Data, append
    data = load_jpm_data('latest');
    point = data.data;
    phData = [phData point];
    %% Adjust Plot
    h = plot(start:step:delay, phData);
    title('Photon Oscillation 1MHz detuned');
    
    %% Upload to Plotly
    
    pause(1);
%     fig2plotly(fig, 'filename', 'Pointer State Preparation', 'open', false);
    
end


