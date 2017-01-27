% A measurement filter for switching probabilities returned from digitizer
% card

% Author/Date : Caleb Howington / Jan 2017


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
classdef SwitchingProbabilityStream < MeasFilters.DigitalMeasFilter
    
    properties
        saveRecords
        fileHandleReal
        fileHandleImag
        channel
        headerWritten = false;
    end
    
    methods
        function obj = SwitchingProbabilityStream(label, settings)
            obj = obj@MeasFilters.DigitalMeasFilter(label, settings);
            obj.channel = str2double(settings.channel);
            obj.saved = false; %until we figure out a new data format then we don't save the raw streams
            
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandle = fopen([settings.recordsFilePath, '.data'], 'wb');
            end
            
        end
        
        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandleReal);
                fclose(obj.fileHandleImag);
            end
        end
        
        function apply(obj, src, ~)
            
            %Pull the raw stream from the digitizer
            obj.latestData = src.data{obj.channel};
            
            %If we have a file to save to then do so
            if obj.saveRecords
                if ~obj.headerWritten
                    %Write the first three dimensions of the signal:
                    %recordLength, numWaveforms, numSegments
                    sizes = size(obj.latestData);
                    if length(sizes) == 2
                        sizes = [sizes(1), 1, sizes(2)];
                    end
                    fwrite(obj.fileHandleHandle, sizes(1:3), 'int32');
                    obj.headerWritten = true;
                end

                fwrite(obj.fileHandle, real(obj.latestData), 'single');
            end
            
            accumulate(obj);
            notify(obj, 'DataReady');
        end
    end
end