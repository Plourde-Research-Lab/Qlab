function [idx] = classifyWell( data )

    % Check if dataset or matrix
    if isstruct(data)
        datastruct = data;
        data = datastruct.data;
    end

    opts = statset('Display', 'final');
    
    % Probably a neater way of doing this
    X = [real(data)';imag(data)']';
    [idx, C] = kmeans(X, 2, 'Options', opts);
    
    % Calculate Separation
    center1 = complex(C(1,1), C(1,2));
    center2 = complex(C(2,1), C(2,2));
    
    well_separation = abs(dist(center1, center2));
    well_amp = mean([abs(center1), abs(center2)]);
    
    fprintf('Well 1 \t I = %f \t Q = %f \t Amp = %f\n', C(1,1), C(1,2), abs(center1));
    fprintf('Well 2 \t I = %f \t Q = %f \t Amp = %f\n', C(2,1), C(2,2), abs(center2));    
    
    fprintf('Separation/Signal = %f\n', well_separation/well_amp);
    
    figure;
    hold on;
    plot(X(idx==1,1),X(idx==1,2),'r.');
    plot(X(idx==2,1),X(idx==2,2),'b.')
    plot(C(:,1),C(:,2),'kx')

    xlabel('I');
    ylabel('Q');
    axis equal
    
end

