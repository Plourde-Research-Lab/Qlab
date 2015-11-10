% A Pulse sweep class.

% Author/Date : Blake Johnson and Colm Ryan / February 4, 2013

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
classdef Pulse < sweeps.Sweep
    properties
        mode
        channel
    end
    
    methods
        % constructor
        function obj = Pulse(sweepParams, Instr)
            
            obj.mode = sweepParams.mode;
            obj.channel = sweepParams.channel;
            
            if isfield(sweepParams, 'label')
                obj.axisLabel = sweepParams.axisLabel;
            else
                switch lower(obj.mode)
                    case 'amp'
                        obj.axisLabel = 'Amplitude (V)';
                    case 'width'
                        obj.axisLabel = 'Width (us)';
                end
            end
            
            start = sweepParams.start;
            stop = sweepParams.stop;
            step = sweepParams.step;
            if start > stop
                step = -abs(step);
            end
            
            % look for an instrument with the name 'genID'
            obj.Instr = Instr.(sweepParams.instr);
            
            % generate step points
            obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
        end
        
        
        function stepAmp(obj, index)
            obj.instr.set('amp', obj.points(index));
        end
        
        function stepWidth(obj, index)
            obj.instr.set('width', obj.points(index));
        end
        % pulse stepper
        function step(obj, index)
            switch lower(obj.mode)
                case 'amp'
                    obj.stepAmp(index)
                case 'width'
                    obj.stepWidth(index)
                otherwise
                    error('Unknown awg stepping mode %s (must be "amp" or "width").',obj.mode);
            end
        end
    end
end
