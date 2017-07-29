function resetSIM(val)
    sim = deviceDrivers.SIM928;
    sim.connect(19);
    sim.channel = 3;
    sim.value = val;
    sim.delete;
    clear sim

end