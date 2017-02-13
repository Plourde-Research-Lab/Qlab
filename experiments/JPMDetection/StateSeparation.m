function [ output_args ] = StateSeparation( dataname )
%STATESEPARATION Summary of this function goes here
%   Detailed explanation goes here

    % Initialize Plot figures
    figure;
    histplt = subplot(2,1,1);
    xlabel(histplt, 'Amplitude');
    ylabel('Probability');
    title('Single Shot Histogram');
    
    iqplt = subplot(2,1,2);
    title('Single Shot IQ Values');
    xlabel('Real (I)');
    ylabel('Imaginary (Q)');   
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Perform first state experiment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Setup the first (bright) Experiment and press any key to continue');
    pause;
    
    ExpScripter(['BrightStateSeparation' dataname]);
    
    % Load State 1 Data
    brightdata = load_data('latest');
    
    % Plot in IQ Plane
    scatter(iqplt, real(brightdata.data), imag(brightdata.data), 'DisplayName', 'Bright');
    legend(iqplt);
    
    % Fit Histogram to gaussian

    % Plot Histogram and gaussian
    histogram(histplt, abs(brightdata.data), 101, 'Normalization', 'Probability', 'DisplayName', 'Bright');
    legend(histplt);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Perform second state experiment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    display('Setup the second (dark) Experiment and press any key to continue');
    pause;
    
    ExpScripter(['Dark State Separation' dataname]);
        
    % Load State 2 Data
    darkdata = load_data('latest');
    
    % Plot in IQ Plane
    hold(iqplt,'on');
    scatter(iqplt, real(darkdata.data), imag(darkdata.data), 'DisplayName', 'Dark');
    legend('show');
    
%     Fit Histogram to gaussian
%     dpd = fitdist(abs(darkdata.data), 'Normal');
%     x2_values = 0:0.01:15;
%     drkpdfit = pdf(dpd, x2_values);
%     
    % Plot Histogram and gaussian
    hold(histplt, 'on');
    histogram(histplt, abs(darkdata.data), 101, 'Normalization', 'Probability', 'DisplayName', 'Dark');
    legend('show');
    
    hold off;
    
    % Calculate Overlap of Histogram area
    % Update Plot with results
    
    % Calculate linear discrimination in IQ plane
    % Update Plot with results
    
    % Update threshold in Measurement JSON
    
end

