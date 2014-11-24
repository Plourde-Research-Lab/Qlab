% A single-channel digital downconversion.

% Author/Date : Blake Johnson and Colm Ryan / February 4, 2013

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
classdef DigitalDemod < MeasFilters.MeasFilter
    
    properties
        saveRecords
        fileHandleReal
        fileHandleImag
        headerWritten = false;
        IFfreq
        bandwidth
        phase
        samplingRate
        decimFactor1
        decimFactor2
        decimFactor3
        nBandwidth
        nIFfreq
    end
    
    methods
        function obj = DigitalDemod(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.saved = false; %until we figure out a new data format then we don't save the raw streams
            
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandleReal = fopen([settings.recordsFilePath, '.real'], 'wb');
                obj.fileHandleImag = fopen([settings.recordsFilePath, '.imag'], 'wb');
            end
            
            obj.IFfreq = settings.IFfreq;
            obj.bandwidth = settings.bandwidth;
            obj.samplingRate = settings.samplingRate;
            
            %normalize frequencies to Nyquist
            obj.nBandwidth= obj.bandwidth/(obj.samplingRate/2);
            obj.nIFfreq = obj.IFfreq/(obj.samplingRate/2);
            
            obj.decimFactor1 = settings.decimFactor1;
            if ( obj.decimFactor1 > floor(0.45/(2*obj.nIFfreq + obj.nBandwidth/2)) )
                warning('First stage decimation factor is too high and 2*omega signal will alias.');
            end
            obj.nBandwidth = obj.nBandwidth * obj.decimFactor1;
            obj.nIFfreq = obj.nIFfreq * obj.decimFactor1;
            
            
            obj.decimFactor2 = settings.decimFactor2;
            obj.nBandwidth = obj.nBandwidth * obj.decimFactor2;
            obj.nIFfreq = obj.nIFfreq * obj.decimFactor2;
            if ( obj.nBandwidth < 0.05 )
                warning('Insufficient first and second stage decimation. IIR filter will be unstable.');
            end
            
            obj.decimFactor3 = settings.decimFactor3;
            
            obj.phase = settings.phase;
            
        end
        
        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandleReal);
                fclose(obj.fileHandleImag);
            end
        end
        
        
        function apply(obj, src, ~)
            
            data = src.latestData;
            
            %Digitally demodulates a signal at frequency IFfreq down to DC. Does this
            %by moving to the IFfreq rotating frame and low-passing the result.
            
            % If the IFfreq is too small, the resulting IIR lowpass is unstable. So, we
            % use a first stage of decimation as long as the 2*omega signal won't alias
            % when we digitally downconvert
            if obj.decimFactor1 > 1
                data = MeasFilters.polyDecimator(data, obj.decimFactor1);
            end
            
            %Create the weighted reference signal (the size of a single acquisition is
            %given by the first dimension of data)
            refSignal = single(exp(1i*pi*obj.nIFfreq*(1:size(data,1)))');
            % efficiently compute data .* refSignal (with singleton dimension
            % expansion)
            prodSignal = bsxfun(@times, data, refSignal);
            
            % We next want to low-pass filter the result, but if nbandwidth < 0.05, the
            % IIR filter will be unstable, so check if we need to decimate first.
            if obj.decimFactor2 > 1
                prodSignal = MeasFilters.polyDecimator(real(prodSignal), obj.decimFactor2) + 1i*MeasFilters.polyDecimator(imag(prodSignal), obj.decimFactor2);
            end
            
            %Get butterworth low-pass filter coefficients from a pre-computed lookup table
            [b,a] = MeasFilters.DigitalDemod.my_butter(obj.nBandwidth);
            % low-pass filter
            demodSignal = filter(b,a, prodSignal);
            
            if obj.decimFactor3 > 1
                demodSignal = MeasFilters.polyDecimator(real(demodSignal), obj.decimFactor3) +1i*MeasFilters.polyDecimator(imag(demodSignal), obj.decimFactor3);
            end
            
            obj.latestData = demodSignal;
            
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
    
    methods(Static)
        
        function [b,a] = my_butter(normIFFreq)
            %Steal variable-order butter-worth filter design from scipy in a table
            %form. These are created in create_butter_table.py.
            %We discretize at 0.01 of the sampling frequency
            
            %Find the closest cut-off frequency in percentage
            %For single-precision arithmetic, we need the normalized cutoff to be at
            %least 0.05 for filter coefficients to be greater than eps('single')
            assert(normIFFreq >= 0.05 && normIFFreq < 1, 'Oops! The normalized cutoff is not between 0.05 and 1')
            roundedCutOff = floor(normIFFreq*100)+1;
            
            %Create the arrays of a's and b's
            filterCoeffs.a = {...
                [ 1.         -4.94903918  9.79745281 -9.69810303  4.80000454 -0.95031514];...
                [ 1.         -4.89806045  9.59741832 -9.40373054  4.60745103 -0.90307833];...
                [ 1.         -4.84704587  9.39981573 -9.11662896  4.42200974 -0.85815042];...
                [ 1.         -4.79597747  9.20456769 -8.83655725  4.24336984 -0.8154019 ];...
                [ 1.         -4.74483721  9.01160012 -8.5632863   4.07123818 -0.7747121 ];...
                [ 1.         -4.69360697  8.8208422  -8.29659831  3.90533814 -0.7359685 ];...
                [ 1.         -4.6422685   8.63222622 -8.0362863   3.74540858 -0.69906612];...
                [ 1.         -4.59080346  8.44568752 -7.78215352  3.59120289 -0.6639069 ];...
                [ 1.         -4.53919333  8.26116444 -7.53401305  3.44248806 -0.63039918];...
                [ 1.         -4.48741942  8.07859822 -7.2916873   3.29904381 -0.59845725];...
                [ 1.         -4.43546287  7.89793298 -7.05500756  3.16066187 -0.56800086];...
                [ 1.         -4.38330457  7.71911566 -6.82381368  3.02714517 -0.53895484];...
                [ 1.         -4.33092518  7.542096   -6.59795361  2.89830723 -0.51124872];...
                [ 1.         -4.2783051   7.36682647 -6.3772831   2.77397149 -0.48481639];...
                [ 1.         -4.22542444  7.19326231 -6.16166535  2.65397071 -0.45959581];...
                [ 1.         -4.17226298  7.02136145 -5.9509707   2.53814644 -0.43552865];...
                [ 1.         -4.11880019  6.85108456 -5.74507632  2.42634849 -0.41256011];...
                [ 1.         -4.06501514  6.68239503 -5.54386595  2.31843444 -0.39063864];...
                [ 1.         -4.01088652  6.51525899 -5.34722966  2.21426923 -0.36971568];...
                [ 1.         -3.95639262  6.34964532 -5.15506353  2.11372467 -0.34974552];...
                [ 1.         -3.90151125  6.1855257  -4.96726949  2.01667909 -0.33068503];...
                [ 1.         -3.84621977  6.02287466 -4.78375506  1.92301696 -0.31249357];...
                [ 1.         -3.79049502  5.86166957 -4.60443315  1.83262854 -0.29513273];...
                [ 1.         -3.7343133   5.7018908  -4.42922184  1.74540952 -0.27856627];...
                [ 1.         -3.67765034  5.54352172 -4.25804422  1.66126078 -0.2627599 ];...
                [ 1.         -3.62048129  5.38654879 -4.09082816  1.580088   -0.2476812 ];...
                [ 1.         -3.56278065  5.2309617  -3.92750617  1.50180149 -0.23329947];...
                [ 1.         -3.50452224  5.07675345 -3.76801522  1.42631585 -0.21958562];...
                [ 1.         -3.4456792   4.92392047 -3.61229654  1.35354975 -0.20651209];...
                [ 1.         -3.38622391  4.7724628  -3.46029549  1.2834257  -0.1940527 ];...
                [ 1.         -3.32612798  4.62238417 -3.31196136  1.21586984 -0.18218263];...
                [ 1.         -3.2653622   4.47369226 -3.16724725  1.15081171 -0.17087824];...
                [ 1.         -3.20389651  4.32639883 -3.02610984  1.08818403 -0.16011709];...
                [ 1.         -3.14169995  4.18051994 -2.88850925  1.02792257 -0.14987779];...
                [ 1.         -3.0787406   4.03607619 -2.7544089   0.96996592 -0.14013995];...
                [ 1.         -3.01498558  3.89309296 -2.62377526  0.91425531 -0.13088413];...
                [ 1.         -2.95040098  3.75160071 -2.49657767  0.86073449 -0.12209176];...
                [ 1.         -2.88495181  3.61163524 -2.37278818  0.80934953 -0.11374507];...
                [ 1.         -2.81860194  3.47323803 -2.25238127  0.76004868 -0.10582708];...
                [ 1.         -2.75131412  3.3364566  -2.13533365  0.71278224 -0.09832149];...
                [ 1.         -2.68304983  3.20134491 -2.02162398  0.6675024  -0.09121265];...
                [ 1.         -2.61376932  3.06796373 -1.91123258  0.62416312 -0.08448555];...
                [ 1.         -2.54343152  2.93638115 -1.80414113  0.58272    -0.0781257 ];...
                [ 1.         -2.47199398  2.80667303 -1.7003323   0.5431302  -0.07211915];...
                [ 1.         -2.39941286  2.67892355 -1.5997894   0.50535226 -0.06645242];...
                [ 1.         -2.32564284  2.55322579 -1.50249588  0.46934608 -0.06111247];...
                [ 1.         -2.25063708  2.42968233 -1.4084349   0.43507277 -0.05608663];...
                [ 1.         -2.17434719  2.30840595 -1.31758874  0.40249461 -0.05136261];...
                [ 1.         -1.99240464  1.76714012 -0.74147506  0.12367918];...
                [ 1.         -1.93580565  1.69396072 -0.70184042  0.11604131];...
                [ 1.         -1.87801536  1.62158753 -0.66314202  0.10868654];...
                [ 1.         -1.81898119  1.55008801 -0.62538382  0.10161279];...
                [ 1.         -1.75864818  1.47953738 -0.58856973  0.09481827];...
                [ 1.         -1.69695894  1.41001936 -0.5527033   0.08830146];...
                [ 1.         -1.63385352  1.34162691 -0.51778748  0.08206111];...
                [ 1.         -1.56926929  1.27446315 -0.48382426  0.07609627];...
                [ 1.         -1.50314082  1.20864228 -0.45081427  0.07040627];...
                [ 1.         -1.43539979  1.1442906  -0.41875633  0.06499077];...
                [ 1.         -1.36597488  1.08154771 -0.38764685  0.05984978];...
                [ 1.         -1.29479165  1.0205677  -0.35747921  0.05498369];...
                [ 1.         -1.22177246  0.96152057 -0.32824304  0.05039332];...
                [ 1.         -1.14683634  0.90459369 -0.29992326  0.04608001];...
                [ 1.         -1.06989898  0.84999349 -0.27249911  0.04204566];...
                [ 1.         -0.99087259  0.79794722 -0.2459429   0.03829289];...
                [ 1.         -0.90966591  0.74870493 -0.22021864  0.03482515];...
                [ 1.         -0.82618416  0.70254157 -0.19528035  0.03164687];...
                [ 1.         -0.74032905  0.65975937 -0.17107021  0.02876374];...
                [ 1.         -0.65199884  0.62069028 -0.14751626  0.02618294];...
                [ 1.         -0.5610884   0.58569875 -0.12452987  0.02391347];...
                [ 1.         -0.84684203  0.52454393 -0.08918875];...
                [ 1.         -0.78089455  0.49572267 -0.08052808];...
                [ 1.         -0.7123403   0.46830402 -0.07197592];...
                [ 1.         -0.64102434  0.44251142 -0.06351954];...
                [ 1.         -0.56678218  0.41859931 -0.05514126];...
                [ 1.         -0.48943945  0.39685745 -0.04681712];...
                [ 1.         -0.40881162  0.3776157  -0.03851529];...
                [ 1.         -0.32470388  0.36124953 -0.03019404];...
                [ 1.         -0.23691114  0.34818621 -0.02179937];...
                [ 1.         -0.14521826  0.33891174 -0.01326194];...
                [ 1.         -0.04940057  0.33397875 -0.00449333];...
                [ 1.          0.05077527  0.33401517  0.00461851];...
                [ 1.          0.15554989  0.33973396  0.01421499];...
                [ 1.          0.26516925  0.35194372  0.02447382];...
                [ 1.          0.37988189  0.37156026  0.03561767];...
                [ 1.          0.49993527  0.39961896  0.0479247 ];...
                [ 1.          0.62557086  0.43728768  0.06174161];...
                [ 1.         -0.17766289  0.17715819];...
                [ 1.         -0.08190161  0.17275892];...
                [ 1.          0.02223749  0.17166029];...
                [ 1.          0.13572032  0.17483098];...
                [ 1.          0.2596123   0.18351257];...
                [ 1.          0.39506965  0.19930009];...
                [ 1.          0.54331478  0.22424622];...
                [ 1.          0.70558477  0.26099468];...
                [ 1.          0.88303547  0.31294802];...
                [ 1.          1.07657417  0.38447174];...
                [ 1.          1.28657997  0.48112883];...
                [ 1.          0.00336691];...
                [ 1.          0.33643223]};
            
            
            filterCoeffs.b = {...
                [  2.95072728e-11   1.47536364e-10   2.95072728e-10   2.95072728e-10  1.47536364e-10   2.95072728e-11];...
                [  9.21602999e-10   4.60801499e-09   9.21602999e-09   9.21602999e-09  4.60801499e-09   9.21602999e-10];...
                [  6.83616955e-09   3.41808477e-08   6.83616955e-08   6.83616955e-08  3.41808477e-08   6.83616955e-09];...
                [  2.81619443e-08   1.40809721e-07   2.81619443e-07   2.81619443e-07  1.40809721e-07   2.81619443e-08];...
                [  8.40829964e-08   4.20414982e-07   8.40829964e-07   8.40829964e-07  4.20414982e-07   8.40829964e-08];...
                [  2.04854420e-07   1.02427210e-06   2.04854420e-06   2.04854420e-06  1.02427210e-06   2.04854420e-07];...
                [  4.33852363e-07   2.16926181e-06   4.33852363e-06   4.33852363e-06  2.16926181e-06   4.33852363e-07];...
                [  8.29454644e-07   4.14727322e-06   8.29454644e-06   8.29454644e-06  4.14727322e-06   8.29454644e-07];...
                [  1.46680089e-06   7.33400444e-06   1.46680089e-05   1.46680089e-05  7.33400444e-06   1.46680089e-06];...
                [  2.43947512e-06   1.21973756e-05   2.43947512e-05   2.43947512e-05  1.21973756e-05   2.43947512e-06];...
                [  3.86114891e-06   1.93057446e-05   3.86114891e-05   3.86114891e-05  1.93057446e-05   3.86114891e-06];...
                [  5.86721920e-06   2.93360960e-05   5.86721920e-05   5.86721920e-05  2.93360960e-05   5.86721920e-06];...
                [  8.61647194e-06   4.30823597e-05   8.61647194e-05   8.61647194e-05  4.30823597e-05   8.61647194e-06];...
                [  1.22928003e-05   6.14640017e-05   1.22928003e-04   1.22928003e-04  6.14640017e-05   1.22928003e-05];...
                [  1.71070046e-05   8.55350230e-05   1.71070046e-04   1.71070046e-04  8.55350230e-05   1.71070046e-05];...
                [  2.32986992e-05   1.16493496e-04   2.32986992e-04   2.32986992e-04  1.16493496e-04   2.32986992e-05];...
                [  3.11383526e-05   1.55691763e-04   3.11383526e-04   3.11383526e-04  1.55691763e-04   3.11383526e-05];...
                [  4.09294853e-05   2.04647426e-04   4.09294853e-04   4.09294853e-04  2.04647426e-04   4.09294853e-05];...
                [  5.30110498e-05   2.65055249e-04   5.30110498e-04   5.30110498e-04  2.65055249e-04   5.30110498e-05];...
                [  6.77600205e-05   3.38800102e-04   6.77600205e-04   6.77600205e-04  3.38800102e-04   6.77600205e-05];...
                [  8.55942187e-05   4.27971094e-04   8.55942187e-04   8.55942187e-04  4.27971094e-04   8.55942187e-05];...
                [ 0.00010698  0.00053488  0.00106975  0.00106975  0.00053488  0.00010698];...
                [ 0.00013241  0.00066206  0.00132413  0.00132413  0.00066206  0.00013241];...
                [ 0.00016247  0.00081233  0.00162466  0.00162466  0.00081233  0.00016247];...
                [ 0.00019775  0.00098875  0.00197751  0.00197751  0.00098875  0.00019775];...
                [ 0.00023894  0.00119471  0.00238942  0.00238942  0.00119471  0.00023894];...
                [ 0.00028678  0.00143389  0.00286778  0.00286778  0.00143389  0.00028678];...
                [ 0.00034207  0.00171035  0.00342069  0.00342069  0.00171035  0.00034207];...
                [ 0.0004057  0.0020285  0.004057   0.004057   0.0020285  0.0004057];...
                [ 0.00047864  0.00239319  0.00478638  0.00478638  0.00239319  0.00047864];...
                [ 0.00056194  0.00280969  0.00561939  0.00561939  0.00280969  0.00056194];...
                [ 0.00065676  0.00328379  0.00656759  0.00656759  0.00328379  0.00065676];...
                [ 0.00076436  0.00382178  0.00764357  0.00764357  0.00382178  0.00076436];...
                [ 0.00088611  0.00443055  0.0088611   0.0088611   0.00443055  0.00088611];...
                [ 0.00102352  0.0051176   0.0102352   0.0102352   0.0051176   0.00102352];...
                [ 0.00117823  0.00589114  0.01178228  0.01178228  0.00589114  0.00117823];...
                [ 0.00135202  0.00676012  0.01352025  0.01352025  0.00676012  0.00135202];...
                [ 0.00154687  0.00773433  0.01546866  0.01546866  0.00773433  0.00154687];...
                [ 0.00176489  0.00882444  0.01764888  0.01764888  0.00882444  0.00176489];...
                [ 0.00200842  0.01004212  0.02008425  0.02008425  0.01004212  0.00200842];...
                [ 0.00228003  0.01140013  0.02280027  0.02280027  0.01140013  0.00228003];...
                [ 0.00258248  0.01291241  0.02582481  0.02582481  0.01291241  0.00258248];...
                [ 0.00291884  0.01459419  0.02918838  0.02918838  0.01459419  0.00291884];...
                [ 0.00329243  0.01646215  0.03292431  0.03292431  0.01646215  0.00329243];...
                [ 0.00370691  0.01853455  0.0370691   0.0370691   0.01853455  0.00370691];...
                [ 0.00416627  0.02083136  0.04166271  0.04166271  0.02083136  0.00416627];...
                [ 0.00467489  0.02337445  0.0467489   0.0467489   0.02337445  0.00467489];...
                [ 0.00523756  0.02618781  0.05237563  0.05237563  0.02618781  0.00523756];...
                [ 0.00980872  0.0392349   0.05885235  0.0392349   0.00980872];...
                [ 0.01077225  0.04308899  0.06463348  0.04308899  0.01077225];...
                [ 0.01181979  0.04727917  0.07091876  0.04727917  0.01181979];...
                [ 0.01295849  0.05183395  0.07775092  0.05183395  0.01295849];...
                [ 0.01419611  0.05678444  0.08517666  0.05678444  0.01419611];...
                [ 0.01554116  0.06216465  0.09324697  0.06216465  0.01554116];...
                [ 0.01700294  0.06801176  0.10201764  0.06801176  0.01700294];...
                [ 0.01859162  0.07436647  0.1115497   0.07436647  0.01859162];...
                [ 0.02031834  0.08127336  0.12191005  0.08127336  0.02031834];...
                [ 0.02219533  0.08878131  0.13317197  0.08878131  0.02219533];...
                [ 0.02423599  0.09694394  0.14541591  0.09694394  0.02423599];...
                [ 0.02645503  0.10582013  0.1587302   0.10582013  0.02645503];...
                [ 0.02886865  0.1154746   0.1732119   0.1154746   0.02886865];...
                [ 0.03149463  0.12597852  0.18896779  0.12597852  0.03149463];...
                [ 0.03435257  0.13741027  0.2061154   0.13741027  0.03435257];...
                [ 0.03746404  0.14985616  0.22478423  0.14985616  0.03746404];...
                [ 0.04085285  0.16341138  0.24511707  0.16341138  0.04085285];...
                [ 0.04454525  0.17818098  0.26727147  0.17818098  0.04454525];...
                [ 0.04857024  0.19428096  0.29142144  0.19428096  0.04857024];...
                [ 0.05295988  0.21183953  0.3177593   0.21183953  0.05295988];...
                [ 0.05774962  0.23099848  0.34649773  0.23099848  0.05774962];...
                [ 0.07356414  0.22069243  0.22069243  0.07356414];...
                [ 0.0792875   0.23786251  0.23786251  0.0792875 ];...
                [ 0.08549848  0.25649543  0.25649543  0.08549848];...
                [ 0.09224594  0.27673783  0.27673783  0.09224594];...
                [ 0.09958448  0.29875345  0.29875345  0.09958448];...
                [ 0.10757511  0.32272533  0.32272533  0.10757511];...
                [ 0.1162861  0.3488583  0.3488583  0.1162861];...
                [ 0.12579395  0.37738185  0.37738185  0.12579395];...
                [ 0.13618446  0.40855339  0.40855339  0.13618446];...
                [ 0.14755394  0.44266183  0.44266183  0.14755394];...
                [ 0.16001061  0.48003182  0.48003182  0.16001061];...
                [ 0.17367612  0.52102836  0.52102836  0.17367612];...
                [ 0.18868736  0.56606207  0.56606207  0.18868736];...
                [ 0.20519835  0.61559505  0.61559505  0.20519835];...
                [ 0.22338248  0.67014743  0.67014743  0.22338248];...
                [ 0.24343487  0.7303046   0.7303046   0.24343487];...
                [ 0.26557502  0.79672506  0.79672506  0.26557502];...
                [ 0.24987383  0.49974765  0.24987383];...
                [ 0.27271433  0.54542865  0.27271433];...
                [ 0.29847445  0.59694889  0.29847445];...
                [ 0.32763783  0.65527565  0.32763783];...
                [ 0.36078122  0.72156244  0.36078122];...
                [ 0.39859244  0.79718487  0.39859244];...
                [ 0.44189025  0.8837805   0.44189025];...
                [ 0.49164486  0.98328972  0.49164486];...
                [ 0.54899587  1.09799175  0.54899587];...
                [ 0.61526148  1.23052296  0.61526148];...
                [ 0.6919272  1.3838544  0.6919272];...
                [ 0.50168346  0.50168346];...
                [ 0.66821612  0.66821612]};
            
            
            %Pick out the row of coefficients.
            b = single(filterCoeffs.b{roundedCutOff-1});
            a = single(filterCoeffs.a{roundedCutOff-1});
            
        end
        
    end
    
end