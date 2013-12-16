% timeDomain
function ExpScripter(expName)

exp = ExpManager();

deviceName = 'IBM_PhaseII';
exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, expName));

expSettings = json.read(getpref('qlab', 'CurScripterFile'));
instrSettings = expSettings.instruments;
sweepSettings = expSettings.sweeps;
measSettings = expSettings.measurements;

for instrument = fieldnames(instrSettings)'
    fprintf('Connecting to %s\n', instrument{1});
    instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
    add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
end

for sweep = fieldnames(sweepSettings)'
    add_sweep(exp, sweepSettings.(sweep{1}).order, SweepFactory(sweepSettings.(sweep{1}), exp.instruments));
end

%Loop over the measurments: insert the non-dependent single channel measurements, keep
%back the correlators and then apply them,
correlators = {};
measFilters = struct();
measNames = fieldnames(measSettings);
for meas = measNames'
    measName = meas{1};
    params = measSettings.(measName);
    if strcmp(params.filterType,'Correlator')
        %If it is a correlator than hold it back
        correlators{end+1} = measName;
    elseif ~params.dependent
        %Otherwise load it and keep a reference to it
        % look for children
        if ~isempty(params.childFilter)
            childParams = measSettings.(params.childFilter);
            childFilter = MeasFilters.(childParams.filterType)(childParams);
            measFilters.(measName) = MeasFilters.(params.filterType)(childFilter, params);
        else
            measFilters.(measName) = MeasFilters.(params.filterType)(params);
        end
        add_measurement(exp, measName, measFilters.(measName));
    end
end

%Loop back and apply any correlators
for meas = correlators
    measName = meas{1};
    childFilters = cellfun(@(x) measFilters.(x), measSettings.(measName).filters, 'UniformOutput', false);
    add_measurement(exp, measName, MeasFilters.Correlator(childFilters{:}));
end

exp.init();
exp.run();

end