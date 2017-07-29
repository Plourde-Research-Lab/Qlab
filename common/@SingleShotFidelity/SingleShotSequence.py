import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='target qubit name')
args = parser.parse_args()

from QGL import *

# q = QubitFactory(args.qubit)
jpm1 = JPMFactory(args.qubit)
# SingleShot(q, showPlot = False)


seqs = [[JPM1(jpm1)*MEAS(jpm1],[JPM2(jpm1, interactAmp=1j)*MEAS(jpm1)]]
filenames = compile_to_hardware(seqs, 'SingleShot/SingleShot')
#plot_pulse_files(filenames)