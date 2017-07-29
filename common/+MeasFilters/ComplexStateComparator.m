% A measurement filter to convert a demodulated signal into a vector of
% hard decisions on qubit state outcomes.

% Author/Date : Blake Johnson and Colm Ryan / July 12, 2013

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
classdef ComplexStateComparator < MeasFilters.MeasFilter

    properties
        leftwell = 0 + 0j
        rightwell = 0 + 0j
        kernel
    end

    methods
        function obj = ComplexStateComparator(label, settings)
            obj = obj@MeasFilters.MeasFilter(label,settings);
            obj.leftwell = complex(settings.state1I, settings.state1Q);
            obj.rightwell = complex(settings.state2I, settings.state2Q);
        end

        function apply(obj, src, ~)
             data = src.latestData;
            
             sumdata = sum(data(:,:,:,:), 1);
%             obj.latestData = double(bsxfun(@hypot, data, obj.leftwell) <= bsxfun(@hypot, data, obj.rightwell));

            dist1 = abs(bsxfun(@minus, sumdata, obj.leftwell));
            dist2 = abs(bsxfun(@minus, sumdata, obj.rightwell));
%             fprintf('L: %f R: %f', dist1, dist2);
%             obj.latestData = double(dist1 < dist2);
            obj.latestData = bsxfun(@le, dist2, dist1);
%             obj.latestData = dist1;
            accumulate(obj);
            notify(obj, 'DataReady');
            
        end

    end
end
