function [name, device, instrSettings] = InstFact(name)
    
%     Caleb Howington, SU
%     April 3 2014
%     InstrumentFactory.m does not work when calling 
%     exp.add_instrument(InstrumentFactory('name'))
%     as per the example instructions. This does. 
    
    %load the instrument library
    instrLibrary = json.read(getpref('qlab', 'CurInstrFile'));
    %Pull out the instrument settings dictionary
    instrSettings = instrLibrary.instrDict.(name);
    deviceClass = instrSettings.x__class__;
    %Creat Device, apply class
    device = deviceDrivers.(deviceClass);
    %Connect Device
    device.connect(instrSettings.address);

end