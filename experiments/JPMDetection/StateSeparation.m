function [ output_args ] = StateSeparation( dataname )
%STATESEPARATION Summary of this function goes here
%   Detailed explanation goes here

%     Initialize Plot figures
%     figure;
%     histplt = subplot(2,1,1);
%     xlabel(histplt, 'Amplitude');
%     ylabel('Probability');
%     title('Single Shot Histogram');
%
%     iqplt = subplot(2,1,2);
%     title('Single Shot IQ Values');
%     xlabel('Real (I)');
%     ylabel('Imaginary (Q)');
%
%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Perform first state experiment
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     display('Setup the first (bright) Experiment and press any key to continue');
%     pause;
%
%     ExpScripter(['BrightStateSeparation' dataname]);
%
%     Load State 1 Data
%     brightdata = load_data('latest');
%
%     Plot in IQ Plane
%     scatter(iqplt, real(brightdata.data), imag(brightdata.data), 'DisplayName', 'Bright');
%     legend(iqplt);
%
%     Fit Histogram to gaussian
%
%     Plot Histogram and gaussian
%     histogram(histplt, abs(brightdata.data), 101, 'Normalization', 'Probability', 'DisplayName', 'Bright');
%     legend(histplt);
%
%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Perform second state experiment
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     display('Setup the second (dark) Experiment and press any key to continue');
%     pause;
%
%     ExpScripter(['Dark State Separation' dataname]);
%
%     Load State 2 Data
%     darkdata = load_data('latest');
%
%     Plot in IQ Plane
%     hold(iqplt,'on');
%     scatter(iqplt, real(darkdata.data), imag(darkdata.data), 'DisplayName', 'Dark');
%     legend('show');
%
%     Fit Histogram to gaussian
%     dpd = fitdist(abs(darkdata.data), 'Normal');
%     x2_values = 0:0.01:15;
%     drkpdfit = pdf(dpd, x2_values);
%
%     Plot Histogram and gaussian
%     hold(histplt, 'on');
%     histogram(histplt, abs(darkdata.data), 101, 'Normalization', 'Probability', 'DisplayName', 'Dark');
%     legend('show');
%
%     hold off;
%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% INITIALIZE SOME SETTINGS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    numRepeats = 100;
    awg = 'APS22');
    awgChannel = 2;
    scope = 'Scope';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% BRIGHT MEASUREMENT
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    exp = ExpManager();

    deviceName = getpref('qlab', 'deviceName');
    exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, [dataname ' Bright']));

    expSettings = json.read(getpref('qlab', 'CurScripterFile'));
    exp.dataFileHeader = expSettings;
    exp.CWMode = expSettings.CWMode;
    instrSettings = expSettings.instruments;
    measSettings = expSettings.measurements;

    % Set Scope to acquire one average
    instrSettings.(scope).averager.nbrRoundRobbins = 1;

    for instrument = fieldnames(instrSettings)'
        fprintf('Connecting to %s\n', instrument{1});
        instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
        add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
    end

    add_sweep(exp, 1, SweepFactory(struct('type', 'Repeat', 'numRepeats', numRepeats), instruments))

    measFilters = struct();
    measNames = fieldnames(measSettings);
    for meas = measNames'
        measName = meas{1};
        params = measSettings.(measName);
            %Otherwise load it and keep a reference to it
            measFilters.(measName) = MeasFilters.(params.filterType)(measName,params);
            add_measurement(exp, measName, measFilters.(measName));
        end
    end

    exp.init();
    exp.run();


    brightData = load_data('latest');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% DARK MEASUREMENT
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Make Changes to Experiment

    exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, [dataname ' Dark']));
    exp.instruments.(awg).set_channel_enabled(awgChannel, 0);

    exp.init();
    exp.run();

    darkData = load_data('latest');
end
