import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('amp', help='amplitude')
args = parser.parse_args()

from QGL import *

jpm1 = JPMFactory('jpm1')

RESETL = JPM1(jpm1, parkAmp=-0.5, length=10e-8)

seqs = [[JPM1(jpm1)*MEAS(jpm1)], [JPM3(jpm1, tiltAmp=0.38)*MEAS(jpm1), RESETL]]
filenames = compile_to_hardware(seqs, 'Bias/Bias')