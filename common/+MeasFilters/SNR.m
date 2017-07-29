% An SNR estimator

% Author/Date : Caleb Howington / April 2017

classdef SNR < MeasFilters.MeasFilter
    
    properties
        rawData
        intData
        Ipdf
        Qpdf
        Apdf
        S
        N
        SNRData
        analysed = false
        analysing = false
    end
    
    methods
         function obj = SNR(label, settings)
            obj = obj@MeasFilters.MeasFilter(label, settings);
            obj.plotMode = 'real/imag';
        end
        
        function out = apply(obj, src, ~)
            % just grab (and sort) latest data from source 
            % data comes recordsLength x numShots segments
            obj.rawData = src.latestData(:,:);
            out = [];
        end
        
        function out = get_data(obj)
            %If we don't have all the data yet return empty
            %Since we only have one round robin the ground data is either
            %unset or NaN
            if isempty(obj.rawData)
                out = [];
                return
            end
            
            % Integrate
            obj.intData = zeros(1,length(obj.rawData(1,:)));
            for i=1:length(obj.intData)
               obj.intData(i) = MeasFilters.dotFirstDim(obj.rawData(:,i), single(ones(1,length(obj.rawData(:,i)))));
%                obj.intData(i) = mean(obj.rawData(:,i));
            end
            obj.intData = mean(obj.rawData)';
            % Analyze
%             
%             obj.Ipdf = fitdist(real(obj.intData), 'normal');
%             obj.Qpdf = fitdist(imag(obj.intData), 'normal');
%             obj.Apdf = fitdist(abs(obj.intData), 'normal');
            
%             obj.S = sqrt(obj.Ipdf.mu^2 + obj.Qpdf.mu^2);
%             obj.N = sqrt(obj.Ipdf.sigma^2 + obj.Qpdf.sigma^2); 
%             obj.S = obj.Apdf.mean;
%             obj.N = sqrt(obj.Ipdf.sigma^2 + obj.Qpdf.sigma^2);
%             global globalInt
%             obj.SNRData = obj.S/obj.N;
%             globalInt = [globalInt obj.intData];
            obj.analysed = true;
%             fprintf('Amplitude: %.5f +/- %.5f \n', obj.Apdf.mean, obj.Apdf.sigma);
%             fprintf('Sqrt(I^2 + Q^2): %.5f +/- %.5f \n', obj.S, obj.N);
%             fprintf('Amplitude SNR: %.5f\n', obj.S/obj.N);
%             fprintf('I : %2.5f +/- %.5f \n', obj.Ipdf.mean, obj.Ipdf.sigma);
%             fprintf('Q : %2.5f +/- %.5f \n', obj.Qpdf.mean, obj.Qpdf.sigma);
%             out = complex(obj.Ipdf.mean/obj.Ipdf.std, obj.Qpdf.mean/obj.Qpdf.std);
                out = 0;
        end
        
        function reset(obj)
            obj.rawData = [];

            obj.analysed = false;
            obj.analysing = false;
        end
        
        function plot(obj, figH)
%             if obj.analysed
%                 clf(figH);
                ax = subplot(1,1,1, 'Parent', figH);
                hold(ax, 'on');
                scatter(ax, real(obj.intData), imag(obj.intData))
%                 xlim(ax, [-50, 50]);
%                 ylim(ax, [-50, 50]);
%                 if obj.S
%                     viscircles(ax, [0, 0], obj.S);
%                 end
                drawnow();
%                 axis(ax, 'equal');
%                 figure;scatter(real(obj.intData), imag(obj.intData));axis equal;
%             end
        end

        
    end
end