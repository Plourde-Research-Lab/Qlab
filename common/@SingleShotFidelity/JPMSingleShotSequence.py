import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('jpm', help='target jpm name')
args = parser.parse_args()

from QGL import *

j = JPMFactory(args.jpm)

RESET = JPM1(j, parkAmp=-0.3, length=1e-7)
seqs = [[RESET, JPM2(j, parkAmp=-0.146, interactAmp=0.26)*MEAS(j)], [RESET, JPM1(j, parkAmp=-0.146)*MEAS(j)]]

filenames = compile_to_hardware(seqs, 'SingleShot/SingleShot')
# plot_pulse_files(filenames)
