% Module Name : HP8563E.m
%
% Author/Date : Matthew Ware 04/14/14
%
% Description : Object to manage access to the HP8563E Spectrum
% analyzer.

% Copyright 2014 Matthew Ware 
%
% I suppose this has to go under the Apache license...
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

classdef (Sealed) HP8563E < deviceDrivers.lib.GPIBorEthernet
    % HP8563E Spectrum analyser
    %
    %
    
    properties
        %LOsource don't think we need this  
        centerFreq
        span
        %numSweepPts set to 600 for HP8563E
        %sweepPts set to 600 for HP8563E
        %sweepData don't think we need this  
        
        sweep_mode
        resolution_bw
        %sweep_points set to 600 for HP8563E 
        number_averages
        video_averaging
        
    end
    methods
        
        function obj = HP8563E()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.GPIBorEthernet();
        end
        %function connect(obj, address)
        %    connect@deviceDrivers.lib.GPIBorEthernet(obj, address)
        %end
        %function disconnect(obj)
        %    disconnect@deviceDrivers.lib.GPIBorEthernet(obj)
        %end
        % overwrite reset
        function reset(obj)
            obj.write('IP;');
        end
        %overwrite identity
        function val = identity(obj)
            val = obj.query('ID?;');
        end
        %getters
        function val = get.centerFreq(obj)
            val = str2double(obj.query('CF?;'))*1e-9; % convert to GHz
        end
        function val = get.span(obj)
            val = str2double(obj.query('SP?;'))*1e-9; % convert to GHz
        end
        function val = get.video_averaging(obj)
            val = obj.query('VAVG?;');
        end
        function val = get.resolution_bw(obj)
            val = str2double(obj.query('RB?;'));
        end
        function val = peakAmplitude(obj)
            % move to the peak
            err = str2double(obj.write('MKPK HI'));
            if err
                fprintf('Spectrum analyser error in moving to peak')
                return
            end
            % get the peak amplitude
            val = str2double(obj.query('MKA?;'));
        end
        %setters
        function obj = set.span(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf('SP %fHZ;', value));
        end
        function obj = set.centerFreq(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf('CF %fHZ;', value));
        end
        function obj = set.resolution_bw(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf('RB %fHZ;', value));
        end
        function obj = set.video_averaging(obj, value)
            assert(isnumeric(value), 'Requires numeric (bool) input [0,1]');
            obj.write(sprintf('VAVG %i;', value));
        end
        function obj = set.sweep_mode(obj, value)
            assert(ischar(value), 'Requires "single" of "contiuous"');
            assert(strcmpi(value,'single') | strcmpi(value,'continuous'), 'Requires "single" of "contiuous"');
            if strcmpi(value,'single')
                obj.write('SNGLS;');
            else
                obj.write('CONTS;');
            end
        end
    end
    
end