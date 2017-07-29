from QGL import *

jpm1 = JPMFactory('jpm1')

RESETL = JPM1(jpm1, parkAmp=-0.5, length=10e-8)

seqs = [[JPM1(jpm1)*MEAS(jpm1)], [JPM3(jpm1, tiltAmp=0.5)*MEAS(jpm1)]]
filenames = compile_to_hardware(seqs, 'StateCalibration/StateCalibration')