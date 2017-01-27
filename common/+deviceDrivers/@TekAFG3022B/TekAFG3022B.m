classdef (Sealed) TekAFG3022B <  deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIBorVISA
    % Tektronix arbitrary function generator
    %
    %
    % Author(s): Caleb Howington
    % Generated on: Oct 3 2015
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        channel = 2
        width = 100e-9
        value = 1
    end % end device properties
    
    methods
        function obj = TekAFG3022B()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.GPIBorVISA();
        end
        
        function setAll(obj, settings)
            obj.channel = settings.channel;
%             obj.write(['TRIG:SOURce EXT'])
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:LOW 0mV'])
            obj.write(['SOURce' obj.channel ':FUNC PULS'])
            obj.write(['SOURce' obj.channel ':BURSt 1'])
            obj.write(['SOURce' obj.channel ':BURSt:NCYCles 1'])
            obj.set('width', settings.width);
            obj.set('value', settings.value);
            
        end
        
        function obj = set.width(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(['SOURce' num2str(obj.channel) ':PULSe:WIDTh ' num2str(value) 'nS'])   
        end
        
        function obj = set.value(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(['SOURce' num2str(obj.channel) ':VOLTage:LEVel:IMMediate:HIGH '  num2str(value) 'V']);
            
        end
    end
    
end