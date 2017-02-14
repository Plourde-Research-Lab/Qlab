classdef CounterStream < MeasFilters.CounterMeasFilter
    
    properties
        saveRecords
        fileHandleReal
        fileHandleImag
        channel
        headerWritten = false;
    end
    
    methods
        function obj = CounterStream(label, settings)
            obj = obj@MeasFilters.CounterMeasFilter(label, settings);
            obj.channel = str2double(settings.channel);
%             obj.saved = true; %until we figure out a new data format then we don't save the raw streams
            
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
        
        function apply(obj, src, ~)
            
            %Pull the raw stream from the digitizer
            obj.latestData = src.data;
            
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
    end
end