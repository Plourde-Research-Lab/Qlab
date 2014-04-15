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
% select which range, 2 = 10 mV, 3 = 100 mV, 4 = 1V, 5 = 10V,6 = 30V
classdef (Sealed) SIM928 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIB
    properties (Access = public)
        output
        channel
        voltage
    end % end device properties
    methods
        function obj = SIM928()
            obj.channel = 3; % default channel
        end
        % Instrument parameter accessors
        % getters
        function val = get.output(obj)
            val = str2double(obj.query(':freq?;'))*1e-9; % convert to GHz
        end
        function val = get.channel(obj)
            val = str2double(obj.query(':power?;'));
        end
        function val = get.voltage(obj)
            val = obj.query(':POW:STAT?;');
        end
        % setters
        function obj = set.voltage(obj, value)
            cmd = sprintf('SNDT %d,"VOLT %d"',obj.channel,value);
            fprintf(g_sim928,cmd);
    end
  

end