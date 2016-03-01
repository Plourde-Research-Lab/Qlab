import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('length', help='Measurement Pulse length in microseconds')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))

q1 = QubitFactory('q1')
q2 = QubitFactory('q2')
slow_pulse = flat_top_gaussian(q1, 1e-6, 10e-6, .5)
seqs = [[MEAS(q1, length=float(args.length)*1e-6), slow_pulse*Utheta(q2, amp=1, length=30e-9, phase=np.pi/2)]]
files = compile_to_hardware(seqs, 'Cav/cav')