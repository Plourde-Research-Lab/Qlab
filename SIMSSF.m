function SIMSSF(expName)
    
    SIMSSFSequence(0.45);
    data = ExpScripter(['SSF ' expName]);
    
    dipdata = data.data(1:2:end);
    nodipdata = data.data(2:2:end);
    
    figure;scatter(real(dipdata), imag(dipdata));
    hold all;scatter(real(nodipdata), imag(nodipdata));
    
    
    xlabel('Real (I)');ylabel('Imag (Q)');title([expName 'SingleShotData']);
    axis equal
    
    saveas(gcf, fullfile(data.path, [strrep(data.filename, '.h5', ' IQ.png')]));
    saveas(gcf, fullfile(data.path, [strrep(data.filename, '.h5', ' IQ.fig')]));
end