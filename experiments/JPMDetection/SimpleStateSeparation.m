ExpName = 'State Separation 5.0 GHz RO 100avg 500mVTrigger 20dBAdded to Ref';

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

title(ExpName)
legend('$\left| L \right>$', '$\left| R \right>$');

saveas(gcf, fullfile(nodipdata.path, [ExpName ' IQ']))
saveas(gcf, fullfile(nodipdata.path, [ExpName ' IQ'], 'png'))