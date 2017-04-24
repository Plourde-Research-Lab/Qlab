% An SNR estimator

% Author/Date : Caleb Howington / April 2017

classdef SNR < MeasFilters.MeasFilter
    
    properties
        rawData
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
        end
        
        function out = apply(obj, src, ~)
            % just grab (and sort) latest data from source 
            % data comes recordsLength x numShots segments
            obj.rawData = src.latestData(:,:)';
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
            
            % Analyze
            
            obj.Ipdf = fitdist(real(obj.rawData), 'normal');
            obj.Qpdf = fitdist(imag(obj.rawData), 'normal');
            obj.Apdf = fitdist(abs(obj.rawData), 'normal');
            
            obj.S = sqrt(obj.Ipdf.mu^2 + obj.Qpdf.mu^2);
%             obj.N = sqrt(obj.Ipdf.sigma^2 + obj.Qpdf.sigma^2); 
%             obj.S = obj.Apdf.mean;
            obj.N = obj.Apdf.sigma;
            
            obj.SNRData = obj.S/obj.N;
            
            obj.analysed = true;
            
            fprintf('Amplitude SNR: %.5f\n', obj.S/obj.N);
            fprintf('I Sigma: %2.5f\n', obj.Ipdf.sigma);
            fprintf('Q Sigma: %2.5f\n', obj.Qpdf.sigma);
            out = obj.SNRData;
        end
        
        function reset(obj)
            obj.rawData = [];

            obj.analysed = false;
            obj.analysing = false;
        end
        
        function plot(obj, figH)
            if obj.analysed
                clf(figH);
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
                
                %Fit gaussian to both peaks and return the esitmate
                    
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

                ax = subplot(1,1,1, 'Parent', figH);
                scatter(ax, real(obj.rawData), imag(obj.rawData))
%                 drawnow();
%                 axis(ax, 'equal');
            end
        end

        
    end
end