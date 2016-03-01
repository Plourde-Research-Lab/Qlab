%% Sweep through pulse widths, calculate contrast

contrastData = [];
brightData = [];
darkData = [];


% mainfig = figure;
% contrastfig = figure;
% title('Fast Pulse Contrast');

start = 310;
final = 500;
step = 10;

for length = start:step:final
    display([num2str(length) 'ns'])
    %% Compile new Pulses
    fpLengthSequence(length);
    
    JPMExpScripter(['Bright'  num2str(length) 'ns']);
    
end