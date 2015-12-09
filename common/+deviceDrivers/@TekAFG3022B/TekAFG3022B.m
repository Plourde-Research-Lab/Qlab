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
        delay = 0
        amp = 1
    end % end device properties
    
    methods
        function obj = TekAFG3022B()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.GPIBorVISA();
        end
        
        function setAll(obj, settings)
            obj.channel = settings.channel;
            obj.width = settings.width;
            obj.amp = settings.amp;
            obj.delay = settings.delay;
            obj.write('TRIG:SOURce EXT');
            obj.write(['SOURce' obj.channel ':FREQ 1000']);
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:LOW 0mV']);
            obj.write(['SOURce' obj.channel ':FUNC PULS']);
            obj.write(['SOURce' obj.channel ':BURSt 1']);
            obj.write(['SOURce' obj.channel ':BURSt:NCYCles 1']);
            obj.set('width', settings.width);
            obj.set('amp', settings.amp);
            obj.set('delay', settings.delay);
            
        end
        
        function obj = set.width(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            value = num2str(value);
            command = ['SOURce' obj.channel ':PULSe:WIDTh ' value 'US'];
            obj.write(command);   
        end
        
        function obj = set.amp(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            
            %Minimum amplitude is 10mV
            if value == 0
               value = .01; 
            end
            value = num2str(value);
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:LOW 0mV']);
            obj.write(['SOURce' obj.channel ':VOLTage:LEVel:IMMediate:HIGH ' value 'V']);
        end
        
        function obj = set.delay(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            value = num2str(value);
            obj.write(['SOURCE' obj.channel ':PULSe:DELay ' value 'US']);
        end
    end
    
end