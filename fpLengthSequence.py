import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('length', help='Bias Pulse length in nanoseconds')
args = parser.parse_args()

sys.path.append(args.pyqlabpath)
execfile(os.path.join(args.pyqlabpath, 'startup.py'))

print(str(float(args.length)*1e-9) + 'ns')
q1 = QubitFactory('q1')
q2 = QubitFactory('q2')
slow_pulse = flat_top_gaussian(q1, 1e-6, 10e-6, .5)
seqs = [[slow_pulse*Utheta(q2, amp=1, length=float(args.length)*1e-9, phase=np.pi/2)]]
files = compile_to_hardware(seqs, 'Bias/contrast')
