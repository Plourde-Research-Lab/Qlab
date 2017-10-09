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
classdef (Sealed) SIM928 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIB
    properties (Access = public)
    end % end device properties
    methods
        function obj = SIM928()
            
        end
        function reset(obj)
            obj.write('SRST');
            obj.write('*CLS');
        end
        
        function setAll(obj, settings)
            channels = {1,2,3};
            for ch = channels
                name = ['ch' num2str(ch{1}) 'Value'];
                if isfield(settings, name)
                    obj.setValue(ch{1}, settings.(name));
                    settings = rmfield(settings, name);
                end
            end

            fields = fieldnames(settings);
            for j = 1:length(fields);
                name = fields{j};
                if ismember(name, methods(obj))
                    args = eval(settings.(name));
                    feval(name, obj, args{:});
                elseif ismember(name, properties(obj))
                    obj.(name) = settings.(name);
                end
            end
        end
        
        % Instrument parameter accessors
        % getters
        function val = getOutput(obj, channel)
            val = str2double(obj.query(['SNDT ', num2str(channel), ',"EXON?"'])); % convert to GHz
        end

        function val = getValue(obj, channel)
            cmd = sprintf('SNDT %d,"VOLT?"',channel);
            val = obj.query(cmd);
        end
        % setters
        
        function obj = setValue(obj, channel, value)
            cmd = sprintf('SNDT %d,"VOLT %d"', channel, value);
            obj.write(cmd);
        end
        
%         function obj = set.output(obj, channel, value)
% 
%             Zero voltage
%             if not (value)
%                 cmd = sprintf('SNDT %d,"VOLT 0"',channel); 
%                 obj.write(cmd);
%             end
% 
%             if isnumeric(value)
%                 value = num2str(value);
%             end
%             
%             Comment out for now, just set to 0
%             % Validate input
%             checkMapObj = containers.Map({'on','1','true', 'off','0', 'false'},...
%                 {'ON','ON','ON','OF','OF','OF'});
%             if not (checkMapObj.isKey( num2str(lower(value)) ))
%                 error('Invalid input');
%             end            
%            cmd = ['SNDT ' num2str(obj.channel) ',"OP' checkMapObj(num2str(value)) '"'];
%            obj.write(cmd);
%         end
    end
end