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
        height = 1
    end % end device properties
    
    methods
        function obj = TekAFG3022B()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.GPIBorVISA();
        end
        
        function setAll(obj, settings)
            obj.set.width(settings.width);
            obj.set.height(settings.height);
            
        end
        
        function obj = set.width(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(['SOURce' obj.channel ':PULSe:WIDTh ' slow_width])   
        end
        
        function obj = set.height(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:HIGH ' slow_amp]);
        end
    end
    
end