% timeDomain
function prob_data = JPMExpScripter(expName, plotMode, cal, contrast)

    if nargin < 2
        plotMode='amp';
    elseif nargin < 3
        cal = false;
    end
    
    
    if cal
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% Run Well Calibration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    calExp = ExpManager();
    deviceName = getpref('qlab', 'deviceName');
    calExp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, [expName '_Cal']));

    expSettings = json.read(getpref('qlab', 'CurScripterFile'));
    calExp.dataFileHeader = expSettings;
    calExp.CWMode = expSettings.CWMode;
    instrSettings = expSettings.instruments;
    measSettings = expSettings.measurements;
    numShots = 2000;

    for instrument = fieldnames(instrSettings)'
        fprintf('Connecting to %s\n', instrument{1});
        instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
        %If it is an AWG, point it at the correct file
        if ExpManager.is_AWG(instr)
            instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-' instrument{1} '.h5']);
        elseif ExpManager.is_scope(instr)
            scopeName = instrument{1};
            % set scope to digitizer mode
            instrSettings.(scopeName).acquireMode = 'digitizer';
            % set digitizer with the appropriate number of segments and
            % round robins
            instrSettings.(scopeName).averager.nbrSegments = numShots;
            instrSettings.(scopeName).averager.nbrRoundRobins = 1;
        end
        calExp.add_instrument(instrument{1}, instr, instrSettings.(instrument{1}));
    end

    calExp.add_sweep(1, sweeps.SegmentNum(struct('axisLabel', 'Segment', 'start', 0, 'step', 1, 'numPoints', numShots)));

    %Loop over the measurments: insert the single channel measurements, keep
    %back the correlators and then apply them
    measFilters = struct();
    measNames = fieldnames(measSettings);
    for meas = measNames'
        measName = meas{1};
        params = measSettings.(measName);
        measFilters.(measName) = MeasFilters.(params.filterType)(measName,params);
        add_measurement(calExp, measName, measFilters.(measName));
    end

    calExp.init();
    calExp.run();
    calExp.delete();

    cal_data = load_data('latest');
    normalized_cal_data = gdivide(cal_data.data{1,1}, cal_data.data{1,2});
    leftdata = normalized_cal_data(1:2:end);
    rightdata = normalized_cal_data(2:2:end);
    leftwell = mean(leftdata);
    rightwell = mean(rightdata);
    setpref('qlab', 'leftWell', leftwell);
    setpref('qlab', 'rightWell', rightwell);
    
    fidelity = mean(gsubtract(abs(leftdata - leftwell), abs(leftdata - rightwell)) < 0);
    
    figure;hold on;
    scatter(real(normalized_cal_data(1:2:end)), imag(normalized_cal_data(1:2:end)));
    scatter(real(normalized_cal_data(2:2:end)), imag(normalized_cal_data(2:2:end)));
    scatter(real(leftwell), imag(leftwell));scatter(real(rightwell), imag(rightwell));
    title(sprintf('Fidelity: %f %', fidelity*100));
    hold off;
    
    else
        leftwell = getpref('qlab', 'leftWell');
        rightwell = getpref('qlab', 'rightWell');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% Run Exp
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    data = ExpScripter(expName, plotMode);   
    int = squeeze(read_records(fullfile(getpref('qlab', 'recordLocation'), 'integrate')));
    ref_int = squeeze(read_records(fullfile(getpref('qlab', 'recordLocation'), 'ref_integrate')));

    % Determine if segmented or not
    
    sweeps = data.expSettings.sweeps;
    seg = false;
    if isfield(sweeps, 'SegmentNum') || isfield(sweeps, 'SegmentNumWithCals')
        seg = true;
    end
    normalized_data = gdivide(int, ref_int);

    if data.dimension{1} > 1
%         normalized_data = reshape(normalized_data, length(data.xpoints{1}),[], length(data.ypoints{1}));
        if seg
            normalized_data = reshape(normalized_data, length(data.xpoints{1}),[], length(data.ypoints{1})); % Non-Segmented
        else 
            normalized_data = reshape(normalized_data, [], length(data.xpoints{1}), length(data.ypoints{1})); % 2-D Non-Segmented
        end
    else
        if seg
            normalized_data = reshape(normalized_data, length(data.xpoints{1}), []);
        else
            normalized_data = reshape(normalized_data, [], length(data.xpoints{1})); % Non Segmented
        end
    end

    leftDist = bsxfun(@minus, normalized_data, leftwell);
    rightDist = bsxfun(@minus, normalized_data, rightwell);

    distDiff = abs(leftDist) > abs(rightDist);

    if seg
        prob_data = mean(distDiff, length(size(distDiff))); % Segmented Scan
    else
        prob_data = squeeze(mean(distDiff, 1)); %Non Segmented Scan
    end
    
    if data.dimension{1} > 1
        figure;imagesc(data.xpoints{1}, data.ypoints{1}, prob_data');
        xlabel(data.xlabel{1})
        ylabel(data.ylabel{1});
        title(data.filename);
    else
        figure;plot(data.xpoints{1}, prob_data');
        xlabel(data.xlabel{1});
        ylabel('Switching Probability');
        title(data.filename);
    end
    
    save(fullfile(data.path, strrep(data.filename, 'h5', 'sp')), 'prob_data');
    saveas(gcf, fullfile(data.path, strrep(data.filename, '.h5', '-Prob')));
    saveas(gcf, fullfile(data.path, strrep(data.filename, '.h5', '-Prob')), 'png');
end
