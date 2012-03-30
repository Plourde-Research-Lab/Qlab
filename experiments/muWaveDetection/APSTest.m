%%

settings.chan_1.enabled = true;
settings.chan_1.amplitude = 1.0;
settings.chan_1.offset = 0;
settings.chan_2.enabled = true;
settings.chan_2.amplitude = 1.0;
settings.chan_2.offset = 0;
settings.chan_3.enabled = true;
settings.chan_3.amplitude = 1.0;
settings.chan_3.offset = 0;
settings.chan_4.enabled = true;
settings.chan_4.amplitude = 1.0;
settings.chan_4.offset = 0;
settings.samplingRate = 1200;
settings.triggerSource = 'external';
settings.seqfile = 'U:\APS\Ramsey\RamseyBBNAPS12.h5';
%settings.seqfile = 'U:\APS\PiCal\PiCal56.mat';
%settings.seqfile = 'C:\Qlab software\experiments\muWaveDetection\sequences\EchoTest.mat';
settings.seqforce = true;

awg = deviceDrivers.APS();
awg.verbose=1;
awg.open(0,1);
if ~awg.is_open
    error('Fail')
end
awg.stop();
forceLoadBitFile = 0;
awg.init(forceLoadBitFile);
awg.setAll(settings);
%awg.run();
awg.triggerFpga(awg.FPGA0, awg.TRIGGER_HARDWARE);
awg.triggerFpga(awg.FPGA1, awg.TRIGGER_HARDWARE);


keyboard
awg.disableFpga(0);
awg.disableFpga(2);
awg.stop();
awg.close();
delete(awg); clear awg