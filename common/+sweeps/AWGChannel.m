% An AWG channel sweep

% Author/Date : Blake Johnson / November 9, 2010

% Copyright 2013 Raytheon BBN Technologies
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
classdef AWGChannel < sweeps.Sweep
    properties
        AWGType
        mode
        channelList
    end
    
    methods
        % constructor
        function obj = AWGChannel(sweepParams, Instr)
            obj.axisLabel = ['AWG Channel(s) ' sweepParams.channel ' ' sweepParams.mode ' (V)'];
            
            % look for the AWG instrument object
            assert(isfield(Instr, sweepParams.instr), 'Could not find AWG instrument');
            obj.Instr = Instr.(sweepParams.instr);
            
            switch sweepParams.instr(1:6)
                case 'TekAWG'
                    obj.AWGType = 'Tek';
                case 'BBNAPS'
                    obj.AWGType = 'APS';
                otherwise
                    error('Unrecognized AWG type');
            end
            
            obj.mode = sweepParams.mode;
            
            % construct channel list
            switch sweepParams.channel
                case {'1', '2', '3', '4'}
                    obj.channelList = str2double(sweepParams.channel);
                case '1&2'
                    obj.channelList = [1, 2];
                case '3&4'
                    obj.channelList = [3, 4];
                otherwise
                    error('Unrecognized channel parameter');
            end
            
            % generate channel points
            start = sweepParams.start;
            stop = sweepParams.stop;
            step = sweepParams.step;
            if start > stop
                step = -abs(step);
            end
            obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
            
        end
        
        function stepAmplitude(obj, index)
            for ch = obj.channelList
                obj.Instr.setAmplitude(ch, obj.points(index));
            end
        end
        
        function stepOffset(obj, index)
            for ch = obj.channelList
                obj.Instr.setOffset(ch, obj.points(index));
            end
        end
        
        function step(obj, index)
            switch lower(obj.mode)
                case 'amp.'
                    obj.stepAmplitude(index);
                case 'offset'
                    obj.stepOffset(index);
                otherwise
                    error('Unknown awg stepping mode %s (must be "amp." or "offset").',obj.mode);
            end
        end
    end
end
