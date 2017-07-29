% Module Name :  StateCalibration.m
%
% Author/Date : Caleb Howington / June 6, 2017
%
% Description : Analyses state separation of a two state experiment

classdef StateCalibration < handle

    properties
        experiment % an instance of the ExpManager class
        settings % a structure of instrument/measurement/sweep settings
        jpm %which jpm we are on
        controlAWG
        readoutAWG
        autoSelectAWGs
        threshold
        singleScope = true
    end

    methods
        %Class constructor
        function obj = StateCalibration()
        end

        function Init(obj, settings)
            obj.settings = settings;
            obj.jpm = obj.settings.jpm;

            % create an ExpManager object
            obj.experiment = ExpManager();

            obj.experiment.dataFileHandler = HDF5DataHandler(settings.fileName);

            % load ExpManager settings
            expSettings = json.read(obj.settings.cfgFile);
            instrSettings = expSettings.instruments;

            % construct data file header
            headerStruct = expSettings;
            headerStruct.singleshot = settings;
            obj.experiment.dataFileHeader = headerStruct;

            warning('off', 'json:fieldNameConflict');
            channelLib = json.read(getpref('qlab','ChannelParamsFile'));
            warning('on', 'json:fieldNameConflict');
            channelLib = channelLib.channelDict;

            tmpStr = regexp(channelLib.(obj.jpm).physChan, '-', 'split');
            obj.controlAWG = tmpStr{1};
            tmpStr = regexp(channelLib.(strcat(genvarname('M-'),obj.jpm)).physChan, '-', 'split');
            obj.readoutAWG = tmpStr{1};

            obj.autoSelectAWGs = settings.autoSelectAWGs;

            if ~isfield(settings,'kernelNumber')
                obj.settings.kernelNumber = NaN;
            end

            % add instruments
            for instrument = fieldnames(instrSettings)'
                fprintf('Connecting to %s\n', instrument{1});
                instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
                %If it is an AWG, point it at the correct file
                if ExpManager.is_AWG(instr)
                    if obj.autoSelectAWGs
                        if ~strcmp(instrument,obj.controlAWG) && ~strcmp(instrument,obj.readoutAWG) && ~instrSettings.(instrument{1}).isMaster
                            %ignores the AWGs which are not either driving or reading this jpm
                            continue
                        end
                    end
                    if isa(instr, 'deviceDrivers.APS') || isa(instr, 'APS2') || isa(instr, 'APS')
                        ext = 'h5';
                    else
                        ext = 'awg';
                    end
                    fprintf('Enabling %s\n', instrument{1});
                    %To get a different sequence loaded into the APS1 when used as a slave for the msm't only.
                    %if isa(instr,'deviceDrivers.APS') && instrSettings.(instrument{1}).isMaster == 0
                    %    instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), 'Reset', ['MeasReset-' instrument{1} '.' ext]);
                    %else
                    instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), 'StateCalibration', ['StateCalibration-' instrument{1} '.' ext]);
                    %end
                elseif ExpManager.is_scope(instr)
                    scopeName = instrument{1};
                    % set scope to digitizer mode
                    instrSettings.(scopeName).acquireMode = 'digitizer';
                    % set digitizer with the appropriate number of segments and
                    % round robins
                    instrSettings.(scopeName).averager.nbrSegments = settings.numShots;
                    instrSettings.(scopeName).averager.nbrRoundRobins = 1;
                end
                add_instrument(obj.experiment, instrument{1}, instr, instrSettings.(instrument{1}));
            end

            %Add the instrument sweeps
            sweepSettings = settings.sweeps;
            sweepNames = fieldnames(sweepSettings);
            for sweepct = 1:length(sweepNames)
                add_sweep(obj.experiment, sweepct, SweepFactory(sweepSettings.(sweepNames{sweepct}), obj.experiment.instruments));
            end
            if isempty(sweepct)
                % create a generic SegmentNum sweep
                %Even though there really are two segments there is only one data
                %point (SS fidelity) being returned at each step.
                add_sweep(obj.experiment, 1, sweeps.SegmentNum(struct('axisLabel', 'Segment', 'start', 0, 'step', 1, 'numPoints', 1)));
            end

            % add single-shot measurement filter
            measSettings = expSettings.measurements;
            add_measurement(obj.experiment, 'StateCalibration',...
                MeasFilters.StateCalibration('StateCalibration', struct('dataSource', obj.settings.dataSource, 'plotMode', 'real/imag', 'plotScope', true,...
                'setStateParams', obj.settings.setStateParams)));
            curSource = obj.settings.dataSource;
            while (true)
               sourceParams = measSettings.(curSource);
               curFilter = MeasFilters.(sourceParams.filterType)(curSource, sourceParams);
               add_measurement(obj.experiment, curSource, curFilter);
               if isa(curFilter, 'MeasFilters.RawStream') || isa(curFilter, 'MeasFilters.StreamSelector')
                   break;
               end
               curSource = sourceParams.dataSource;
            end

            %Disable unused scopes
            if obj.singleScope
                for instrName = fieldnames(obj.experiment.instruments)'
                    instr = obj.experiment.instruments.(instrName{1});
                    if (ExpManager.is_scope(instr) && ~strcmp(curFilter.dataSource, instrName{1}))
                        obj.experiment.remove_instrument(instrName{1})
                    end
                end
            end

            %Create the sequence of alternating LW, RW preparation pulses
            if obj.settings.createSequence
                obj.StateCalibrationSequence(obj.jpm)
            end

            % intialize the ExpManager
            init(obj.experiment);
        end

        function SCData = Do(obj)
            obj.experiment.run();
            drawnow();
            SCData = obj.experiment.data.StateCalibration;
            if obj.settings.setStateParams
                obj.Set_state_params()
            end
        end

        function Set_state_params(obj)
             leftwell = mean(obj.experiment.measurements.StateCalibration.state1Data);
             rightwell = mean(obj.experiment.measurements.StateCalibration.state2Data);

             measLib = json.read(getpref('qlab', 'MeasurementLibraryFile'));
             filters = fieldnames(measLib.filterDict);
             for i=1:numel(filters)
                 filt = measLib.filterDict.(filters{i});
                if strcmp(filt.x__class__, 'ComplexStateComparator')
                    measLib.filterDict.(filt.label).state1I = real(leftwell);
                    measLib.filterDict.(filt.label).state1Q = imag(leftwell);
                    measLib.filterDict.(filt.label).state2I = real(rightwell);
                    measLib.filterDict.(filt.label).state2Q = imag(rightwell);
                end
             end
             json.write(measLib, getpref('qlab', 'MeasurementLibraryFile'), 'indent', 2);
             
             expSettings = json.read(getpref('qlab', 'CurScripterFile'));
             filters = fieldnames(expSettings.measurements);
             for i=1:numel(filters)
                if strcmp(expSettings.measurements.(filters{i}).filterType, 'ComplexStateComparator')
                    expSettings.measurements.(filters{i}).state1I = real(leftwell);
                    expSettings.measurements.(filters{i}).state1Q = imag(leftwell);
                    expSettings.measurements.(filters{i}).state2I = real(rightwell);
                    expSettings.measurements.(filters{i}).state2Q = imag(rightwell);
%                         2+2;
                end
             end
             json.write(expSettings, getpref('qlab', 'CurScripterFile'), 'indent', 2);
        end
    end

end
