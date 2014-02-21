% Module Name :  SingleShotFidelity.m
%
% Author/Date : Colm Ryan  / 9 April, 2012
%
% Description : Analyses single shot readout fidelity

%
% Copyright 2012 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef SingleShotFidelity < handle
    
    properties
        experiment % an instance of the ExpManager class
        settings % a structure of instrument/measurement/sweep settings
        qubit %which qubit we are on
    end
    
    methods
        %% Class constructor
        function obj = SingleShotFidelity()
        end
        
        function Init(obj, settings)
            obj.settings = settings;   
            obj.qubit = obj.settings.qubit;
            
            % create an ExpManager object
            obj.experiment = ExpManager();
            
            obj.experiment.dataFileHandler = HDF5DataHandler(settings.fileName);
            
            % load ExpManager settings
            expSettings = jsonlab.loadjson(obj.settings.cfgFile);
            instrSettings = expSettings.instruments;
            
            % construct data file header
            headerStruct = expSettings;
            headerStruct.singleshot = settings;
            obj.experiment.dataFileHeader = headerStruct;
            
            % add instruments
            for instrument = fieldnames(instrSettings)'
                fprintf('Connecting to %s\n', instrument{1});
                instr = InstrumentFactory(instrument{1});
                %If it is an AWG, point it at the correct file
                if ExpManager.is_AWG(instr)
                    if isa(instr, 'deviceDrivers.APS')
                        ext = 'h5';
                    else
                        ext = 'awg';
                    end
                    instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), 'SingleShot', ['SingleShot-' instrument{1} '.' ext]);
                end
                add_instrument(obj.experiment, instrument{1}, instr, instrSettings.(instrument{1}));
            end
            
            % set scope to digitizer mode
            obj.experiment.instrSettings.scope.acquireMode = 'digitizer';
            
            % set digitizer with the appropriate number of segments and
            % round robins
            obj.experiment.instrSettings.scope.averager.nbrSegments = 2;
            obj.experiment.instrSettings.scope.averager.nbrRoundRobins = settings.numShots/2;
            
            %Add the instrument sweeps
            sweepSettings = settings.sweeps;
            sweepNames = fieldnames(sweepSettings);
            for sweepct = 1:length(sweepNames)
                add_sweep(obj.experiment, sweepct, SweepFactory(sweepSettings.(sweepNames{sweepct}), obj.experiment.instruments));
            end
            if isempty(sweepct)
                % create a generic SegmentNum sweep
                %Even though there really is two segments there only one data
                %point (SS fidelity) being returned at each step.
                add_sweep(obj.experiment, 1, sweeps.SegmentNum(struct('label', 'Segment', 'start', 0, 'step', 1, 'numPoints', 1)));
            end

            % add single-shot measurement filter
            import MeasFilters.*
            measSettings = expSettings.measurements;
            dh = DigitalHomodyneSS(measSettings.(obj.settings.measurement));
            add_measurement(obj.experiment, 'single_shot', SingleShot(dh, obj.settings.numShots));
            
            %Create the sequence of alternating QId, 180 inversion pulses
            if obj.settings.createSequence
                obj.SingleShotSequence(obj.qubit)
            end
            
            % intialize the ExpManager
            init(obj.experiment);
        end
        
        function SSData = Do(obj)
            obj.SingleShotFidelityDo();
            SSData = obj.experiment.data.single_shot;
        end
        
    end
    
end
