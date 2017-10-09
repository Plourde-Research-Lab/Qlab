% A single-channel kernel integration

% Author/Date : Colm Ryan / 22 November 2014
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
classdef KernelIntegration < MeasFilters.MeasFilter
    
    properties
        kernel
        bias
        saveRecords
        fileHandleReal
        fileHandleImag
        headerWritten = false;
    end
    
    methods
        function obj = KernelIntegration(label, settings)
            obj = obj@MeasFilters.MeasFilter(label, settings);
            %decode kernel
            %decode base64 then cast to byte array and then to float64
            %array
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandleReal = fopen(fullfile(getpref('qlab', 'recordLocation'), [settings.recordsFilePath, '.real']), 'wb');
                obj.fileHandleImag = fopen(fullfile(getpref('qlab', 'recordLocation'), [settings.recordsFilePath, '.imag']), 'wb');
            end
            
            tmp = typecast(org.apache.commons.codec.binary.Base64.decodeBase64(uint8(settings.kernel)), 'uint8');
            tmp = typecast(tmp, 'double');
            obj.kernel = tmp(1:2:end) + 1j*tmp(2:2:end);
            obj.bias = settings.bias;
        end
        
        function apply(obj, src, ~)
            % match kernel length to data
            if size(src.latestData,1) ~= size(obj.kernel,1)
                obj.kernel(end:size(src.latestData,1)) = 0;
                obj.kernel(size(src.latestData,1)+1:end) = [];
            end
%             obj.latestData = sum(bsxfun(@times, src.latestData, conj(obj.kernel))) + obj.bias;
            obj.latestData = MeasFilters.dotFirstDim(src.latestData, single(obj.kernel));
            obj.latestData = obj.latestData + obj.bias;
            
            %If we have a file to save to then do so
            if obj.saveRecords
                if ~obj.headerWritten
                    %Write the first three dimensions of the signal:
                    %recordLength, numWaveforms, numSegments
                    sizes = size(obj.latestData);
                    if length(sizes) == 2
                        sizes = [sizes(1), 1, sizes(2)];
                    end
                    fwrite(obj.fileHandleReal, sizes(1:3), 'int32');
                    fwrite(obj.fileHandleImag, sizes(1:3), 'int32');
                    obj.headerWritten = true;
                end

                fwrite(obj.fileHandleReal, real(obj.latestData), 'single');
                fwrite(obj.fileHandleImag, imag(obj.latestData), 'single');
            end
            
            accumulate(obj);
            notify(obj, 'DataReady');
        end
        
        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandleReal);
                fclose(obj.fileHandleImag);
            end
        end
    end
end
