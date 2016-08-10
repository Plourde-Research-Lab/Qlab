import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('qubit', help='qubit name')
args = parser.parse_args()

from QGL import *

q = QubitFactory(args.qubit)

InversionRecovery(q1, 1e-6*np.linspace(0,100,101), showPlot=False)

Ramsey(q1, 2.5e-7*np.arange(0,101),TPPIFreq = 500000, showPlot=False)

Echo = [[X90(q1), Id(q1, length = l), Y(q1), Id(q1, length = l), X90(q1), MEAS(q1)] for l in 1e-6*np.linspace(0,10,101)]
filenames = compile_to_hardware(Echo, 'Echo/Echo')