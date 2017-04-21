function [gateFidelitySDP, gateFidelityLSQ, choiSDP, choiLSQ] = analyzeProcessTomo(data, idealProcess, nbrQubits, nbrPrepPulses, nbrReadoutPulses, nbrCalRepeats, varargin)
%analyzeProcess Performs SDP tomography, calculates gates fidelites and plots pauli maps.
%
% [gateFidelity, choiSDP] = analyzeProcessTomo(data, idealProcessStr, nbrQubits, nbrPrepPulses, nbrReadoutPulses, nbrRepeats)

% optional arguments:
% newplot: If true, make new figure windows
% vardata: variance matrix

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

p = inputParser;
addParameter(p,'newplot', false, @islogical)
addParameter(p,'vardata', [], @iscell)
addParameter(p,'prep_meas_axes', 'Clifford', @ischar)
parse(p, varargin{:});
newplot = p.Results.newplot;
vardata = p.Results.vardata;
prep_meas_axes = p.Results.prep_meas_axes;

%separate calibration experiments from tomography data and flatten the
%experiment data

%The data comes in as a matrix (numSeqs X numExpsPerSeq) with
%the calibration data the last nbrCalRepeats2^nbrQubits of each row. We need to go
%through each column and extract the calibration data and record a map of
%which measurement operator each experiment corresponds to.

% Cell array signals multi-measurement data
if iscell(data)
    numMeasChans = length(data);
    
    % Figure out whether data is split into multiple sequences if we have more
    % than one non-singleton dimension then assume each row is an AWGSequence
    % with cals at end of rows. 
    if sum(size(data{1}) > 1) == 1
        data = cellfun(@transpose, data, 'UniformOutput', false);
    end
    data = cat(1, data{:});
else
    numMeasChans = 1;
    if sum(size(data) > 1) == 1
        data = transpose(data);
    end
end


%Number of different preparations and readouts
numPreps = nbrPrepPulses^nbrQubits;
numMeas = nbrReadoutPulses^nbrQubits;
numExps = numPreps*numMeas*numMeasChans;
numCals = 2^(nbrQubits)*nbrCalRepeats;

if isempty(vardata)
%Rough rescaling by the variance to equalize things for the least squares
    approxScale = std(data(:,end-numCals+1:end), 0, 2);
    data = bsxfun(@rdivide, data, approxScale);
end

%Pull out the raw experimental data
rawData = data(:, 1:end-numCals);
if ~isempty(vardata)
    vardata = cat(1, vardata{:});
    varMat = vardata(:, 1:end-numCals);
    weightMat = 1./sqrt(varMat);
    weightMat = weightMat/sum(weightMat(:));
else
    weightMat = ones(size(data,1),size(data,2)-numCals);
end

%Pull out the calibration data as measurement operators and assign each exp. to a meas. operator
measOps = cell(size(data,1),1);
measMap = nan(numExps,1);
results = nan(numExps,1);

%Go through row first as fast axis
idx = 1;
for row = 1:size(rawData,1)
    measOps{row} = diag(mean(reshape(data(row, end-numCals+1:end), nbrCalRepeats, 2^nbrQubits),1));
    for col = 1:size(rawData,2)
        results(idx) = rawData(row,col);
        measMap(idx) = row;
        idx = idx + 1;
    end
end

%Setup the state preparation and measurement pulse sets
U_preps = tomo_gate_set(nbrQubits, nbrPrepPulses, 'type', prep_meas_axes, 'prep_meas', 1);
U_meas  = tomo_gate_set(nbrQubits, nbrReadoutPulses, 'type', prep_meas_axes, 'prep_meas', 2);

%Call the SDP program to do the constrained optimization
[choiSDP, choiLSQ] = QPT_SDP(results, measOps, measMap, U_preps, U_meas, nbrQubits, weightMat);

%Calculate the overlaps with the ideal gate
if ischar(idealProcess)
    unitaryIdeal = str2unitary(idealProcess);
else
    unitaryIdeal = idealProcess;
end
choiIdeal = unitary2choi(unitaryIdeal);

%Create the pauli operator strings
[~, pauliStrs] = paulis(nbrQubits);

%Convert to chi representation to compute fidelity metrics
chiExp = choi2chi(choiSDP);
chiIdeal = choi2chi(choiIdeal);

processFidelitySDP = real(trace(chiExp*chiIdeal));
gateFidelitySDP = (2^nbrQubits*processFidelitySDP+1)/(2^nbrQubits+1);

processFidelityLSQ = real(trace(choi2chi(choiLSQ)*chiIdeal));
gateFidelityLSQ = (2^nbrQubits*processFidelityLSQ+1)/(2^nbrQubits+1);


%Create the pauli map for plotting
pauliMapIdeal = choi2pauliMap(choiIdeal);
pauliMapLSQ = choi2pauliMap(choiLSQ);
pauliMapExp = choi2pauliMap(choiSDP);

%Permute according to hamming weight
weights = cellfun(@pauliHamming, pauliStrs);
[~, weightIdx] = sort(weights);

pauliMapIdeal = pauliMapIdeal(weightIdx, weightIdx);
pauliMapLSQ = pauliMapLSQ(weightIdx, weightIdx);
pauliMapExp = pauliMapExp(weightIdx, weightIdx);
pauliStrs = pauliStrs(weightIdx);

%Create red-blue colorscale
cmap = [hot(50); 1-hot(50)];
cmap = cmap(19:19+63,:); % make a 64-entry colormap

if newplot
    figure();
else
    if ~isfield(figHandles, 'pauliMapLSQ') || ~ishandle(figHandles.('pauliMapLSQ'))
        figHandles.('pauliMapLSQ') = figure('Name', 'pauliMapLSQ');
    else
        figure(figHandles.('pauliMapLSQ')); clf;
    end
end
imagesc(real(pauliMapLSQ),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('LSQ Reconstruction');

if newplot
    figure();
else
    if ~isfield(figHandles, 'pauliMapExp') || ~ishandle(figHandles.('pauliMapExp'))
        figHandles.('pauliMapExp') = figure('Name', 'pauliMapExp');
    else
        figure(figHandles.('pauliMapExp')); clf;
    end
end
imagesc(real(pauliMapExp),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('MLE Reconstruction');

if newplot
    figure();
else
    if ~isfield(figHandles, 'pauliMapIdeal') || ~ishandle(figHandles.('pauliMapIdeal'))
        figHandles.('pauliMapIdeal') = figure('Name', 'pauliMapIdeal');
    else
        figure(figHandles.('pauliMapIdeal')); clf;
    end
end
imagesc(real(pauliMapIdeal),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^nbrQubits);
set(gca, 'XTickLabel', pauliStrs);

set(gca, 'YTick', 1:4^nbrQubits);
set(gca, 'YTickLabel', pauliStrs);
xlabel('Input Pauli Operator');
ylabel('Output Pauli Operator');
title('Ideal Map');


% how much did MLE change the idealProcessStr maps?
% dist2_mle_ideal = sqrt(abs(trace((choi_mle-choi_ideal)'*(choi_mle-choi_ideal))))/2
% dist2_mle_raw = sqrt(abs(trace((choi_mle-choi_raw)'*(choi_mle-choi_raw))))/2
% dist2_raw_ideal = sqrt(abs(trace((choi_ideal-choi_raw)'*(choi_ideal-choi_raw))))/2
% negativity_raw = real((sum(eig(choi_raw)) - sum(abs(eig(choi_raw))))/2)

end
