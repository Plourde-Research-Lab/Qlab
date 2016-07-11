NumPnts = data.expSettings.sweeps.Cavity.numPoints;

D = data.data(:,1:6);
E = sqrt(real(D).^2 + imag(D).^2);
F = mean(E');
G = F';
H = sqrt(real(data.data).^2 + imag(data.data).^2);

for x = 1:NumPnts
    
    I(:,x) = H(:,x) - G;
    
end

figure: plot(data.xpoints,sqrt(real(I).^2 + imag(I).^2));
%hold all; plot(data.xpoints,sqrt(real(I).^2 + imag(I).^2));

clear D
clear E
clear F
clear G
clear H
clear I

