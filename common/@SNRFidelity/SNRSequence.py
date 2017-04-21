import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='target qubit name')
args = parser.parse_args()

from QGL import *

q = JPMFactory(args.qubit)

seqs = [[MEAS(q, length=1e-6)]]
filenames = compile_to_hardware(seqs, 'MEAS/MEAS')

