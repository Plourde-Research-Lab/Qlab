function cutSubtractedData = cut_subtract_data( rawdata )
%UNTITLED Summary of this function goes here
    %   Detailed explanation goes here

    
    cutSubtractedData = zeros(size(rawdata.data));
    medians = [];
    % Find Frequency Axis
    if ~isempty(strfind(rawdata.ylabel, 'Freq'))
       for i=1:length(rawdata.ypoints)
           row = abs(rawdata.data(i,:));
           display(median(row))
           cutSubtractedData(i,:) = row - ones(size(row)) * median(row);
       end
    else
       for i=1:length(rawdata.xpoints)
           row = abs(rawdata.data(:,i));
           display(median(row))
           cutSubtractedData(:,i) = row - ones(size(row)) * median(row);
       end
    end
    
    figure;imagesc(rawdata.xpoints, rawdata.ypoints, cutSubtractedData);
    
    
end

