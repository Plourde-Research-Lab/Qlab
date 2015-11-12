classdef Counter < MeasFilters.MeasFilter
    %COUNTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        saveRecords
        fileHandle
        channel
        headerWritten = false;
    end
    
    methods
        
        function obj = Counter(label, settings)
            obj = obj@MeasFilters.MeasFilter(label, settings);
            obj.channel = str2double(settings.channel);
            obj.saved = false; %until we figure out a new data format then we don't save the raw streams
            
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandle = fopen([settings.recordsFilePath, '.real'], 'wb');
            end
            
        end
        
        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandle);
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

