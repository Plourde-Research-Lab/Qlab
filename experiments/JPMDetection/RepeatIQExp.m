function RepeatIQExp( expName, numRepeats )
    
    fig = figure;
    ax = subplot(1, 1, 1, 'Parent', fig);
    hold(ax, 'on');
    
    phases = [];
    
    for i=1:numRepeats
       data = ExpScripter([expName num2str(i)], 'None');
       scatter(ax, real(data.data), imag(data.data));
       axis(ax, 'equal');
       phases = [phases,  mean(angle(data.data))];
    end
    
    fprintf('Phase Delta: %f\n', rad2deg(max(phases) - min(phases)))


end

