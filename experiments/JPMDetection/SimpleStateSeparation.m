ExpName = 'State Separation  4.9GHz 10dBAtt Filtered';

ExpScripter([ExpName ' Dip'])
dipdata = load_data('latest');
absdipdata = abs(dipdata.data);

ExpScripter([ExpName ' No Dip'])
nodipdata = load_data('latest');
absnodipdata = abs(nodipdata.data);

x_values = linspace(min([min(dipdata.data), min(nodipdata.data)]), max([max(dipdata.data), max(nodipdata.data)]), 100);

figure;
hold all;
dippd = fitdist(absdipdata, 'normal');
histogram(absdipdata, 100);
% plot(x_values, pdf(dippd, x_values))


nodippd = fitdist(absnodipdata, 'normal');
histogram(absnodipdata, 100);
% plot(x_values, pdf(nodippd, x_values))

figure;
scatter(real(dipdata.data), imag(dipdata.data));
hold all;
scatter(real(nodipdata.data), imag(nodipdata.data))