function [ output_args ] = StateSeparation( dataname )
%STATESEPARATION Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% INITIALIZE SOME SETTINGS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    numRepeats = 100;
    numAvg = 1;
    awg = 'APS22';
    awgChannel = '2';
    scope = 'Scope';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% RIGHT WELL MEASUREMENT
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    display('Taking Right Well Data....');
    
    exp = ExpManager();

    deviceName = getpref('qlab', 'deviceName');
    exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, [dataname ' Right']));

    expSettings = json.read(getpref('qlab', 'CurScripterFile'));
    exp.dataFileHeader = expSettings;
    exp.CWMode = expSettings.CWMode;
    instrSettings = expSettings.instruments;
    measSettings = expSettings.measurements;

    % Set Scope to acquire one average
    instrSettings.(scope).averager.nbrRoundRobins = numAvg;

    for instrument = fieldnames(instrSettings)'
        instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
        add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
    end

    add_sweep(exp, 1, SweepFactory(struct('type', 'Repeat', 'numRepeats', numRepeats), exp.instruments))

    measFilters = struct();
    measNames = fieldnames(measSettings);
    for meas = measNames'
        measName = meas{1};
        params = measSettings.(measName);
        %Otherwise load it and keep a reference to it
        measFilters.(measName) = MeasFilters.(params.filterType)(measName,params);
        add_measurement(exp, measName, measFilters.(measName));

    end

    exp.init();
    exp.run();


    brightData = load_data('latest');


    exp.delete();
    clear exp;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% LEFT MEASUREMENT
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    display('Taking Left Well Data....');
    
    %% Make Changes to Experiment

    exp = ExpManager();

    deviceName = getpref('qlab', 'deviceName');
    exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, [dataname ' Left']));

    exp.dataFileHeader = expSettings;
    exp.CWMode = expSettings.CWMode;

    % Set Scope to acquire one average
    instrSettings.(scope).averager.nbrRoundRobins = numAvg;
    instrSettings.(awg).(['chan_' awgChannel]).enabled = 0;
    
    for instrument = fieldnames(instrSettings)'
        instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
        add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
    end

    add_sweep(exp, 1, SweepFactory(struct('type', 'Repeat', 'numRepeats', numRepeats), exp.instruments))

    measFilters = struct();
    measNames = fieldnames(measSettings);
    for meas = measNames'
        measName = meas{1};
        params = measSettings.(measName);
        %Otherwise load it and keep a reference to it
        measFilters.(measName) = MeasFilters.(params.filterType)(measName,params);
        add_measurement(exp, measName, measFilters.(measName));

    end
    
    exp.init();
    exp.run();

    darkData = load_data('latest');
    
    figure;
    scatter(real(brightData.data), imag(brightData.data));
    hold all;
    scatter(real(darkData.data), imag(darkData.data))


    leg = legend('$$\left| L \right>$$', '$$\left| R \right>$$');
    set(leg, 'interpreter', 'latex');
    
    axis equal;
    
    datanumber = strsplit(darkData.filename, '_');
    datanumber = datanumber(1);
    
    plotname = strcat(datanumber, getpref('qlab', 'deviceName'), dataname, '-IQ');
    plotname = strrep(plotname, ' ', '_');
    
    title(plotname, 'interpreter', 'none');
    
    display(plotname);
    display(fullfile(darkData.path, plotname));
    saveas(gcf, char(fullfile(darkData.path, plotname)), 'fig');
    saveas(gcf, char(fullfile(darkData.path, plotname)), 'png');
end
