apsa = APS();
% apsb = APS();

apsa.connect('A6001ixV');
% apsb.connect('A6001nBT');
apsa.init();
% apsb.init();
apsa.disconnect;apsa.delete;clear apsa;
% apsb.disconnect;apsb.delete;clear apsb;