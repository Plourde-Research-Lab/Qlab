%% Sweep through reset pulse widths, run repeat measurement

resetData = [];
resetH5s = [];

fig = figure;
title('Reset Pulse Optimization 4, On Resonance');

for delay = 0:.1:2
   
    %% Compile new Pulses
    resetLengthSequence(delay);

    %% Run Experiment
    ExperimentName = ['Reset0MHz' num2str(delay) 'us'];
    display(ExperimentName);
    
    JPMExpScripter(ExperimentName);
    
    %% Load Data, append
    data = load_jpm_data('latest');
    point = data.data;
    resetData = [resetData point];
    resetH5s = [resetH5s data];
    %% Adjust Plot
    h = plot(0:.1:delay, resetData);
    title('Reset Pulse Optimization, On Resonance');
    
    %% Upload to Plotly
    
%     pause(1);
%     fig2plotly(fig, 'filename', 'Pointer State Preparation', 'open', false);
    
end


