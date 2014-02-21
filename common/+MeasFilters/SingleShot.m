% A single-shot fidelity estimator

% Author/Date : Blake Johnson and Colm Ryan / February 12, 2013

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
classdef SingleShot < MeasFilters.MeasFilter
    
    properties
        groundData
        excitedData
        pdfData
        numShots = -1
        analysed = false
        analysing = false
        bestIntegrationTime
    end
    
    methods
        function obj = SingleShot(childFilter, varargin)
            obj = obj@MeasFilters.MeasFilter(childFilter, struct('plotMode', 'real/imag'));
            if length(varargin) == 1
                obj.numShots = varargin{1};
            end
        end
        
        function out = apply(obj, data)
            % just grab (and sort) latest data from child filter
            data = apply@MeasFilters.MeasFilter(obj, data);
            %Assume that the data is recordLength x 1 (waveforms) x 2
            %(segments ground/excited) x roundRobinsPerBuffer
            obj.groundData = cat(2, obj.groundData, squeeze(data(:,1,1,:)));
            obj.excitedData = cat(2, obj.excitedData, squeeze(data(:,1,2,:)));
            out = [];
        end
        
        function out = get_data(obj)
            %If we don't have all the data yet return empty
            if size(obj.groundData,2) ~= obj.numShots/2
                out = [];
                return
            end
            
            if ~obj.analysing
                obj.analysing = true;

                % return histogrammed data
                obj.pdfData = struct();
                
                groundMean = mean(obj.groundData, 2);
                excitedMean = mean(obj.excitedData, 2);
                centre = 0.5*(groundMean+excitedMean);
                rotAngle = angle(excitedMean-groundMean);
%                 groundData = obj.groundData;
%                 excitedData = obj.excitedData;
%                 save('SSData.mat', 'excitedData', 'groundData')
%                 clear groundData excitedData
                unwoundGroundData = bsxfun(@times, bsxfun(@minus, obj.groundData, centre), exp(-1j*rotAngle));
                unwoundExcitedData = bsxfun(@times, bsxfun(@minus, obj.excitedData, centre), exp(-1j*rotAngle));
                
                %Use the difference magnitude as a weight function
                diffMag = abs(excitedMean-groundMean);
                weights = diffMag/sum(diffMag);
                groundIData = bsxfun(@times, real(unwoundGroundData), weights);
                excitedIData = bsxfun(@times, real(unwoundExcitedData), weights);
                groundQData = bsxfun(@times, imag(unwoundGroundData), weights);
                excitedQData = bsxfun(@times, imag(unwoundExcitedData), weights);
                clear unwoundGroundData unwoundExcitedData
                
                %Take cummulative sum up to each timestep
                intGroundIData = cumsum(groundIData, 1);
                intExcitedIData = cumsum(excitedIData, 1);
                intGroundQData = cumsum(groundQData, 1);
                intExcitedQData = cumsum(excitedQData, 1);
                
                %Loop through each intergration point; esimtate the CDF and
                %then calculate best measurement fidelity
                numTimePts = size(intGroundIData,1);
                fidelities = zeros(numTimePts,1);
                for intPt = 1:2:numTimePts
                    %Setup bins from the minimum to maximum measured voltage
                    bins = linspace(min([intGroundIData(intPt,:), intExcitedIData(intPt,:)]), max([intGroundIData(intPt,:), intExcitedIData(intPt,:)]));
                    
                    %Estimate the PDF for the ground and excited states
                    gPDF = ksdensity(intGroundIData(intPt,:), bins);
                    ePDF = ksdensity(intExcitedIData(intPt,:), bins);
                    
                    fidelities(intPt) = 0.5*(bins(2)-bins(1))*sum(abs(gPDF-ePDF));
                end
                
                [maxFidelity_I, intPt] = max(fidelities);
                obj.bestIntegrationTime = intPt;
                fprintf('Best integration time found at %d decimated points out of %d\n', intPt, numTimePts);
                obj.pdfData.bins_I = linspace(min([intGroundIData(intPt,:), intExcitedIData(intPt,:)]), max([intGroundIData(intPt,:), intExcitedIData(intPt,:)]));
                obj.pdfData.gPDF_I = ksdensity(intGroundIData(intPt,:), obj.pdfData.bins_I);
                obj.pdfData.ePDF_I = ksdensity(intExcitedIData(intPt,:), obj.pdfData.bins_I);
                obj.pdfData.maxFidelity_I = maxFidelity_I;
                tmpData = intGroundIData(intPt,:);
                [mu, sigma] = normfit(tmpData(tmpData<0));
                obj.pdfData.g_gaussPDF_I = normpdf(obj.pdfData.bins_I, mu, sigma);
                tmpData = intExcitedIData(intPt,:);
                [mu, sigma] = normfit(tmpData(tmpData>0));
                obj.pdfData.e_gaussPDF_I = normpdf(obj.pdfData.bins_I, mu, sigma);
                clear groundIData intGroundIData excitedIData intExcitedIData
                
                %Calculate the kernel density estimates for the other
                %quadrature too
                obj.pdfData.bins_Q = linspace(min([intGroundQData(intPt,:), intExcitedQData(intPt,:)]), max([intGroundQData(intPt,:), intExcitedQData(intPt,:)]));
                obj.pdfData.gPDF_Q = ksdensity(intGroundQData(intPt,:), obj.pdfData.bins_Q);
                obj.pdfData.ePDF_Q = ksdensity(intExcitedQData(intPt,:), obj.pdfData.bins_Q);
                obj.pdfData.maxFidelity_Q = 0.5*(obj.pdfData.bins_Q(2)-obj.pdfData.bins_Q(1))*sum(abs(obj.pdfData.gPDF_Q-obj.pdfData.ePDF_Q));
                [mu, sigma] = normfit(intGroundQData(intPt,:));
                obj.pdfData.g_gaussPDF_Q = normpdf(obj.pdfData.bins_Q, mu, sigma);
                [mu, sigma] = normfit(intExcitedQData(intPt,:));
                obj.pdfData.e_gaussPDF_Q = normpdf(obj.pdfData.bins_Q, mu, sigma);

                out = maxFidelity_I + 1j*obj.pdfData.maxFidelity_Q;
                clear groundQData intGroundQData excitedQData intExcitedQData

                obj.analysed = true;
                
                %Logistic regression
                allData = cat(1, cat(2, real(obj.groundData)', imag(obj.groundData)'), cat(2, real(obj.excitedData)', imag(obj.excitedData)'));
                prepStates = [zeros(size(obj.groundData,2),1); ones(size(obj.excitedData,2),1)];
                %Matlab's logistic regression support is quite weak.  The
                %code below takes forever and overfits.  It looks like in
                %more recent versions lassoglm might provide some
                %regularization
%                 betas = glmfit(allData, prepStates, 'binomial');
%                 guessStates = glmval(betas, allData, 'logit');
%                 fidelity = 2*sum(guessStates == prepStates)/size(allData,1) - 1 

                %Fortunately, liblinear is great!
                bestAccuracy = 0;
                bestC = 0;
                for c = logspace(0,2,5);
                    accuracy = train(prepStates, sparse(double(allData)), sprintf('-c %f -B 1.0 -v 3 -q -s 0',c));
                    if accuracy > bestAccuracy
                        bestAccuracy = accuracy;
                        bestC = c;
                    end
                end
                model = train(prepStates, sparse(double(allData)), sprintf('-c %f -B 1.0 -q -s 0',bestC));
                [predictedState, accuracy, ~] = predict(prepStates, sparse(double(allData)), model);
                fidelity = 2*accuracy(1)/100-1;
                c = 0.95;
                N = length(predictedState);
                S = sum(predictedState == prepStates);
                flo = betaincinv((1-c)/2.,S+1,N-S+1);
                fup = betaincinv((1+c)/2.,S+1,N-S+1);
                fprintf('Cross-validated logistic regression accuracy: %.2f\n', bestAccuracy);
                fprintf('In-place logistic regression fidelity %.2f, (%.2f, %.2f).\n', 100*fidelity, 200*flo-100, 200*fup-100);

            else
                out = obj.pdfData.maxFidelity_I + 1j*obj.pdfData.maxFidelity_Q;
            end
        end
        
        function reset(obj)
            obj.groundData = [];
            obj.excitedData = [];
            obj.analysed = false;
            obj.analysing = false;
        end
        
        function plot(obj, figH)
            if obj.analysed
                clf(figH);
                axes1 = subplot(2,1,1, 'Parent', figH);
                plot(axes1, obj.pdfData.bins_I, obj.pdfData.gPDF_I, 'b');
                hold(axes1, 'on');
                plot(axes1, obj.pdfData.bins_I, obj.pdfData.g_gaussPDF_I, 'b--')
                plot(axes1, obj.pdfData.bins_I, obj.pdfData.ePDF_I, 'r');
                plot(axes1, obj.pdfData.bins_I, obj.pdfData.e_gaussPDF_I, 'r--')
                legend(axes1, {'Ground','Excited'})
                snrFidelity = 100*0.5*(obj.pdfData.bins_I(2)-obj.pdfData.bins_I(1))*sum(abs(obj.pdfData.g_gaussPDF_I - obj.pdfData.e_gaussPDF_I));
                text(0.1, 0.75, sprintf('Fidelity: %.1f%% (SNR Fidelity: %.1f%%)',100*obj.pdfData.maxFidelity_I, snrFidelity),...
                    'Units', 'normalized', 'FontSize', 14, 'Parent', axes1)
                
                %Fit gaussian to both peaks and return the esitmat
                    
                axes2 = subplot(2,1,2, 'Parent', figH);
                plot(axes2, obj.pdfData.bins_Q, obj.pdfData.gPDF_Q, 'b');
                hold(axes2, 'on');
                plot(axes2, obj.pdfData.bins_Q, obj.pdfData.g_gaussPDF_Q, 'b--')
                plot(axes2, obj.pdfData.bins_Q, obj.pdfData.ePDF_Q, 'r');
                plot(axes2, obj.pdfData.bins_Q, obj.pdfData.e_gaussPDF_Q, 'r--')
                legend(axes2, {'Ground','Excited'})
                text(0.1, 0.75, sprintf('Fidelity: %.1f%%\nIntegration time: %d',100*obj.pdfData.maxFidelity_Q, obj.bestIntegrationTime), 'Units', 'normalized', 'FontSize', 14, 'Parent', axes2)
                drawnow();
            end
        end

        
    end
end