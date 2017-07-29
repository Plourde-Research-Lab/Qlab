% Calculates State Parameters as well as Fidelity

% Author/Date : Caleb Howington / June 6, 2017

classdef StateCalibration < MeasFilters.MeasFilter
    
    properties
        state1Data
        state2Data
        pdfData
        analysed = false
        analysing = false
        setStateParams = false
        kernel
        m
        b
        midpoint
    end
    
    methods
         function obj = StateCalibration(label, settings)
            obj = obj@MeasFilters.MeasFilter(label, settings);
            if isfield(settings, 'setStateParams')
                obj.setStateParams = settings.setStateParams;
            end
        end
        
        function out = apply(obj, src, ~)
            % just grab (and sort) latest data from source 
            % data comes recordsLength x numShots segments
            obj.state1Data = src.latestData(:,1:2:end);
            obj.state2Data = src.latestData(:,2:2:end);
            out = [];
        end
        
        function out = get_data(obj)
            %If we don't have all the data yet return empty
            %Since we only have one round robin the ground data is either
            %unset or NaN
            if isempty(obj.state1Data) || isnan(obj.state1Data(1))
                out = [];
                return
            end
            
            if ~obj.analysing
                obj.analysing = true;
                obj.kernel = ones(1, size(obj.state1Data, 1));
                %Integrate Data
                if size(obj.state1Data,1) ~= size(obj.kernel,1)
                    obj.kernel(end:size(obj.state1Data,1)) = 0;
                    obj.kernel(size(obj.state1Data,1)+1:end) = [];
                end
                obj.state1Data = MeasFilters.dotFirstDim(obj.state1Data, single(obj.kernel));
                obj.state2Data = MeasFilters.dotFirstDim(obj.state2Data, single(obj.kernel));
                
                
                state1Mean = mean(obj.state1Data, 2);
                state2Mean = mean(obj.state2Data, 2);
                obj.midpoint = (state1Mean + state2Mean) / 2;
                distance = abs(mean(state1Mean - state2Mean));
                fprintf('LeftWell: %g, %f +/- %f\n', real(state1Mean), imag(state1Mean), std(obj.state1Data));
                fprintf('RightWell: %g, %f +/- %f\n', real(state2Mean), imag(state2Mean), std(obj.state2Data));
                fprintf('Distance: %f\n', distance);
                bias = mean(state1Mean + state2Mean)/distance;
                fprintf('bias: %g\n', bias(end));
                
                % Slope of perpendicular bisector
                % m_p = -1/m
                obj.m = (real(state2Mean) - real(state1Mean)) / (imag(state1Mean) - imag(state2Mean) );
%               
                % Y-intercept of perpendicular bisector
                % b = y - mx
                % Using midpoint (x, y)
                
                obj.b = (imag(state1Mean) + imag(state2Mean))/2 - obj.m * (real(state1Mean) + real(state2Mean))/2;
                
                % Returning slope and y-intercept of bisector line as
                % complex number (m + b*j)
%                 out = complex(obj.m, obj.b);
                out = distance;
                obj.analysed = true;
                
            else
                out = obj.pdfData.maxFidelity_I + 1j*obj.pdfData.maxFidelity_Q;
            end
        end
        
        function reset(obj)
            obj.state1Data = [];
            obj.state2Data = [];
            obj.analysed = false;
            obj.analysing = false;
        end
        
        function plot(obj, figH)
            if obj.analysed
%                 clf(figH);
%                 axes1 = subplot(2,1,1, 'Parent', figH);
%                 plt_fcn = @plot; %@semilogy
%                 plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.gPDF_I, 'b');
%                 hold(axes1, 'on');
%                 plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.g_gaussPDF_I, 'b--')
%                 plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.ePDF_I, 'r');
%                 plt_fcn(axes1, obj.pdfData.bins_I, obj.pdfData.e_gaussPDF_I, 'r--')
%                 allData = [obj.pdfData.gPDF_I(:); obj.pdfData.ePDF_I(:)];
%                 ylim(axes1, [1e-3*max(allData), 2*max(allData)]);
%                 title(axes1,'Real quadrature fidelity');
%                 legend(axes1, {'Ground', 'Ground Gaussian Fit', 'Excited', 'Excited Gaussian Fit'})
%                 snrFidelity = 100-0.5*(100-0.5*100*(obj.pdfData.bins_I(2)-obj.pdfData.bins_I(1))*sum(abs(obj.pdfData.g_gaussPDF_I - obj.pdfData.e_gaussPDF_I)));
%                 text(0.1, 0.75, sprintf('Fidelity: %.1f%% (SNR Fidelity: %.1f%%)',100*obj.pdfData.maxFidelity_I, snrFidelity),...
%                     'Units', 'normalized', 'FontSize', 14, 'Parent', axes1)
%                 
%                 %Fit gaussian to both peaks and return the esitmate
%                     
%                 axes2 = subplot(2,1,2, 'Parent', figH);
%                 semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.gPDF_Q, 'b');
%                 hold(axes2, 'on');
%                 semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.g_gaussPDF_Q, 'b--')
%                 semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.ePDF_Q, 'r');
%                 semilogy(axes2, obj.pdfData.bins_Q, obj.pdfData.e_gaussPDF_Q, 'r--')
%                 allData = [obj.pdfData.gPDF_Q(:); obj.pdfData.ePDF_Q(:)];
%                 ylim(axes2, [1e-3*max(allData), 2*max(allData)]);
%                 title(axes2,'Imaginary quadrature fidelity');
%                 legend(axes2, {'Ground', 'Ground Gaussian Fit', 'Excited', 'Excited Gaussian Fit'})
%                 text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*obj.pdfData.maxFidelity_Q), 'Units', 'normalized', 'FontSize', 14, 'Parent', axes2)
%                 drawnow();
                
                clf(figH);
                axes1 = subplot(1, 1, 1, 'Parent', figH);
                hold(axes1, 'on');
                scatter(axes1, real(obj.state1Data), imag(obj.state1Data));
                scatter(axes1, real(obj.state2Data), imag(obj.state2Data));
                
%                 axes2 = subplot(2, 1, 2, 'Parent', figH);
%                 hold(axes2, 'on');
%                                 
%                 histogram(axes2, bsxfun(@hypot, obj.midpoint, obj.state1Data), 101);
%                 histogram(axes2, bsxfun(@hypot, obj.midpoint, obj.state2Data), 101);
%                 axis equal 
                drawnow();
%                 figure;scatter(real(obj.groundData), imag(obj.groundData))
%                 hold all;scatter(real(obj.excitedData), imag(obj.excitedData))
            end
        end

        
    end
end