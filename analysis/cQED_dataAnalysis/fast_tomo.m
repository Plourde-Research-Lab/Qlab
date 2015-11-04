function [bins, PDFvec, data_con, rhoa,rhob]=fast_tomo(cond, threshold)
%load tomo from single shots, postselect on ancilla
%cond = 1,-1,0 for conditioned (>, <), unconditioned
%threshold = ancilla value for postselection.
numSegments = 48; %including calibrations (data + ancilla)
ASegments = [45;47]; %segments with A in 0 and 1, used to find opt. threshold
calSegments = 12; %number of calibrations
numTomo = 44; %subset of segments with tomography + calibrations (not including ancilla)

data=load_data('latest');
alldata=reshape_cells(data);
if cond~=0
    docond=1;
else
    docond=0;
end
[bins,PDFvec,data_con,var_con,~,~,~,~,~]=initByMsmt_2D(alldata,1,numSegments,1,ASegments,1,cond,threshold,docond,calSegments);
datatemp.data{1}=data_con{1}(1:numTomo); datatemp.data{2}=data_con{2}(1:numTomo); datatemp.data{3}=data_con{3}(1:numTomo);
datatemp.realvar{1}=var_con{1}(1:numTomo); datatemp.realvar{2}=var_con{2}(1:numTomo); datatemp.realvar{3}=var_con{3}(1:numTomo);
[rhoa,rhob]= analyzeStateTomo(datatemp,2,6,2);
end