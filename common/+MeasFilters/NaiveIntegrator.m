% A shot in the dark at implementing a naiev signal intensity measure

% Author/Date : Matthew Ware / Sept. 4, 2014

% Copyright 2014 Raytheon BBN Technologies
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
classdef NaiveIntegrator < MeasFilters.MeasFilter
    
    properties
        samplingRate
        boxCarStart
        boxCarStop
        filter
        IFfreq
        bandwidth
        fileHandleReal
        fileHandleImag
        saveRecords
        headerWritten = false;
    end
    
    methods
        function obj = NaiveIntegrator(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.samplingRate = settings.samplingRate;
            obj.boxCarStart = settings.boxCarStart;
            obj.boxCarStop = settings.boxCarStop;
            obj.bandwidth = settings.bandwidth;
            obj.IFfreq = settings.IFfreq;
            
            if isfield(settings, 'filterFilePath') && ~isempty(settings.filterFilePath)
                obj.filter = load(settings.filterFilePath, 'filterCoeffs', 'bias');
            else
                obj.filter = [];
            end
            
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandleReal = fopen([settings.recordsFilePath, '.real'], 'wb');
                obj.fileHandleImag = fopen([settings.recordsFilePath, '.imag'], 'wb');
            end
        end
        
        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandleReal);
                fclose(obj.fileHandleImag);
            end
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
			% going to implement a blind copy of the run CQED code ..
            [demodSignal, decimFactor] = digitalDemod(data, obj.IFfreq, obj.bandwidth, obj.samplingRate);
			signal = demodSignal;	
			% define some filter constants
			%K = (1/obj.IFfreq)*(obj.samplingRate +1);
			K = length(signal);
            A(1:K) = 0; A(1)=1;
			B(1:K) = 1/K;
            %run_QCED.filterCoeffs = [B];
            %obj.filter = 'run_CQED';
			
			%Box car the demodulated signal
            if ndims(signal) == 2
                signal = signal(max(1,floor(obj.boxCarStart/decimFactor)):floor(obj.boxCarStop/decimFactor),:);
            elseif ndims(signal) == 4
                signal = signal(max(1,floor(obj.boxCarStart/decimFactor)):floor(obj.boxCarStop/decimFactor),:,:,:);
                %If we have a file to save to then do so
                if obj.saveRecords
                    if ~obj.headerWritten
                        %Write the first three dimensions of the demodSignal:
                        %recordLength, numWaveforms, numSegments
                        sizes = size(signal);
                        fwrite(obj.fileHandleReal, sizes(1:3), 'int32');
                        fwrite(obj.fileHandleImag, sizes(1:3), 'int32');
                        obj.headerWritten = true;
                    end
                    
                    fwrite(obj.fileHandleReal, real(signal), 'single');
                    fwrite(obj.fileHandleImag, imag(signal), 'single');
                end
                
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end

            %If we have a pre-defined filter use it, otherwise integrate
            %and rotate
            if ~isempty(obj.filter)
                %obj.latestData = sum(bsxfun(@times, demodSignal, obj.filter.filterCoeffs')) + obj.filter.bias;
                %obj.latestData = dotFirstDim(signal, obj.filter.filterCoeffs);
                obj.latestData = dotFirstDim(signal, single(B));
                obj.latestData = obj.latestData + obj.filter.bias;
            else
                %Integrate 
                signal = mean(signal);
                signal = signal - filter(B,A,signal);
                %time = (obj.boxCarStart:obj.boxCarStop)/obj.samplingRate;
                %COS = cos(2 * pi * time .* obj.IFfreq);
                %SIN = sin(2 * pi * time .* obj.IFfreq);
				%signal = sqrt(sum(COS.*data).^2 + sum(SIN.*data).^2);
                obj.latestData = mean(signal,1);
            end
            
            obj.accumulate();
            out = obj.latestData;
        end
    end
    
    
end
