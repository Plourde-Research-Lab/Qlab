function resetSim
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    resetVoltage = -6;
    sim = InstrumentFactory('DC');
    sim.connect('19');
    sim.set('value', resetVoltage);
    sim.set('output', 1);
    sim.disconnect;
    sim.delete;
    clear sim
end

