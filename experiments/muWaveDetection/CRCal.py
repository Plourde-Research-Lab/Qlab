import argparse
import sys, os
parser = argparse.ArgumentParser()
parser.add_argument('pyqlabpath', help='path to PyQLab directory')
parser.add_argument('control', help='control qubit name')
parser.add_argument('target', help='target qubit name')
parser.add_argument('caltype', type=float, help='1 for length, 2 for phase, 3 for amplitude')
parser.add_argument('length', type=float, help='step for length calibration or fixed length in phase calibration (ns)')
args = parser.parse_args()

from QGL import *

q2 = QubitFactory(args.control)
q1 = QubitFactory(args.target)

if args.caltype==1:
	EchoCRLen(q2,q1,args.length*1e-9*np.arange(1,20),riseFall=40e-9,amp=0.8,showPlot=False)
elif args.caltype==2:
	EchoCRPhase(q2,q1,np.linspace(0,2*np.pi,19),length=args.length*1e-9,amp=0.8,riseFall=40e-9, showPlot=False)
else:
	EchoCRAmp(q2,q1,np.linspace(0.6,1,19),length=args.length*1e-9,riseFall=40e-9,showPlot=False)
