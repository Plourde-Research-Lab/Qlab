% Module Name : SIM928.m
%
% Author/Date : Matthew Ware 04/14/14
%
% Description : Object to manage access to the Stanford SIM.  This is VERY
% much a work in progress.  This does nothing more than send voltage 
% commands to the sim channel 3.

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
        value
    end % end device properties
    methods
        function obj = SIM928()
            obj.channel = 3; % default channel
        end
        function reset(obj)
            obj.write('SRST');
            obj.write('*CLS');
        end
        
        % Instrument parameter accessors
        % getters
        function val = get.output(obj)
            val = str2double(obj.query('SNDT %d,"EXON?"',obj.channel)); % convert to GHz
        end
        function val = get.channel(obj)
            val = obj.channel;
        end
        function val = get.value(obj)
            cmd = sprintf('SNDT %d,"VOLT?"',obj.channel);
            val = obj.query(cmd);
        end
        % setters
        function obj = set.value(obj, value)
            cmd = sprintf('SNDT %d,"VOLT %d"',3,value);
            obj.write(cmd);
        end
    end
end