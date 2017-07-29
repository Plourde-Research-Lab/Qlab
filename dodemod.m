h = openfig('20singleshots.fig', 'invisible');
ax = h.get('Children');
lines = ax(1).get('Children');
lines2 = ax(2).get('Children');

% figure(ax(1))
t = linspace(0, 512e-9, 512);
f = 50e6;

Cv = cos(2*pi*f*t);
Sv = sin(2*pi*f*t);

refsignal = exp(1j*2*pi*f*t);

demod = [];
demod2 = [];

data = zeros(size(lines));
data2 = zeros(size(lines));

figure;hold all;
for i=1:length(lines)
    plot(real(lines(i).YData));
end

for i=1:length(lines)
    Is = real(lines(i).YData);
    Qs = imag(lines(i).YData);
    prodsignal = bsxfun(@times,  lines(i).YData, refsignal);
    demod = [demod prodsignal'];
    data(i) = mean(prodsignal);
    prodsignal2 = complex(bsxfun(@times, Is,Cv) - bsxfun(@times, Qs,Sv), bsxfun(@times, Is,Sv) + bsxfun(@times, Qs,Cv));
    demod2 = [demod2 prodsignal2'];
    data2(i) = mean(prodsignal2);
end

figure;
ax1 = subplot(2, 1, 1);
plot(ax1, real(demod));title('BBN');
ax2 = subplot(2, 1, 2);
plot(ax2, real(demod2));title('Madison');

figure;
ax1 = subplot(2, 1, 1);
scatter(ax1, real(data), imag(data));
axis equal;
ax2 = subplot(2, 1, 2);
scatter(ax2, real(data2), imag(data2));
axis equal;


