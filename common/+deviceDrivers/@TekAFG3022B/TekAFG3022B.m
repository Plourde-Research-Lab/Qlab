classdef (Sealed) TekAFG3022B <  deviceDrivers.lib.GPIBorVISA
    % Tektronix arbitrary function generator
    %
    %
    % Author(s): Caleb Howington
    % Generated on: Oct 3 2015
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        channel = 2
        width = 100
        amp = 1
    end % end device properties
    
    methods
        function obj = TekAFG3022B()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.GPIBorVISA();
        end
        
        function setAll(obj, settings)
            obj.channel = settings.channel;
            obj.write(['TRIG:SOURce EXT'])
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:LOW 0mV'])
            obj.write(['SOURce' obj.channel ':FUNC PULS'])
            obj.write(['SOURce' obj.channel ':BURSt 1'])
            obj.write(['SOURce' obj.channel ':BURSt:NCYCles 1'])
            obj.set('width', settings.width);
            obj.set('amp', settings.amp);
            
        end
        
        function obj = set.width(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(['SOURce' obj.channel ':PULSe:WIDTh ' value 'US'])   
        end
        
        function obj = set.amp(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:HIGH ' value 'V']);
        end
    end
    
end