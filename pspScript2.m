lengths = 0.1:0.1:2;
freqs = [pspData0_1s.xpoints; pspData2_0_1us.xpoints];
pspDatas = [pspData0_1s, pspData0_2us, pspData0_3us, pspData0_4us, pspData0_5s, pspData0_6us, pspData0_7us, pspData0_8us, pspData0_9us];
pspDatas = [pspDatas, pspData1us, pspData1_1us, pspData1_2us, pspData1_3us, pspData1_4us, pspData1_5s, pspData1_6us, pspData1_7us, pspData1_8us, pspData1_9us];
pspDatas = [pspDatas, pspData2us];
% pspDatas = [pspDatas, pspData2us, pspData2_1us, pspData2_2us, pspData2_3us, pspData2_4us, pspData2_5s, pspData2_6us, pspData2_7us, pspData1_8us, pspData2_9us];
% pspDatas = [pspDatas, pspData3us];

pspDatas2 = [pspData2_0_1us, pspData2_0_2us, pspData2_0_3us, pspData2_0_4us, pspData2_0_5us, pspData2_0_6us, pspData2_0_7us, pspData2_0_8us, pspData2_0_9us];
pspDatas2 = [pspDatas2, pspData2_1us, pspData2_1_1us, pspData2_1_2us, pspData2_1_3us, pspData2_1_4us, pspData2_1_5us, pspData2_1_6us, pspData2_1_7us, pspData2_1_8us, pspData2_1_9us];
pspDatas2 = [pspDatas2, pspData2_2us];


counts = zeros(length(freqs), length(lengths));

for i=1:length(pspDatas)
    counts(:, i) = [pspDatas(i).data; pspDatas2(i).data];
end

for i=1:length(freqs)
   counts(i, :) = counts(i, :)./max(counts(i, :)); 
end

figure;imagesc(lengths, freqs, counts);
title('Extended Normalized');

% for i=1:15
%     figure;plot(lengths, counts(i, :))
%     title([num2str(freqs(i)) 'GHz']);
% end