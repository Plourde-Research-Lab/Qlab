import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('jpm', help='target jpm name')
args = parser.parse_args()

from QGL import *

j = JPMFactory(args.jpm)

seqs = [[JPM2(j, interactAmp = d*1j)*MEAS(j)] for d in np.linspace(0, j.pulseParams['tiltAmp'], 2)]
filenames = compile_to_hardware(seqs, 'SingleShot/SingleShot')
# plot_pulse_files(filenames)
