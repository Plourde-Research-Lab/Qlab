classdef (Sealed) BNC845 < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIBorEthernet
    % BNC845 signal generator
    %
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        frequency
        power
        phase
        alc
        pulse
        pulseSource
        mod
    end % end device properties
    
    methods
        function obj = BNC845()
            obj.DEFAULT_PORT = 18;
        end
		
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            val = str2double(obj.query('SOURCE:FREQUENCY?'));
        end
        
        function val = get.power(obj)
            val = str2double(obj.query('SOURCE:POWER?'));
        end
        
        function val = get.phase(obj)
            val = str2double(obj.query('SOURCE:PHASE:ADJUST'));
        end
        
        function val = get.output(obj)
            val = str2double(obj.query('OUTPUT:STATE?'));
        end
        
        function val = get.alc(obj)
            val = str2double(obj.query('SOURCE:POWER:ALC?'));
        end
        
        function val = get.pulse(obj)
            val = str2double(obj.query('SOURCE:PULM:STATE?'));
        end
        
        function val = get.pulseSource(obj)
            val = obj.query('SOURCE:PULM:SOURCE?');
        end
        
        
        % property setters
        function obj = set.frequency(obj, value)
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            obj.write(sprintf('SOURCE:FREQUENCY:FIXED %E',value*1e9));
        end
        
        function obj = set.power(obj, value)
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            obj.write(sprintf('SOURCE:POWER:LEVEL:IMMEDIATE:AMPLITUDE %E',value));
        end
        
        function obj = set.output(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'1','1','0','0'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            obj.write(sprintf('OUTPUT:STATE %c', onOffMap(value)));
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            obj.write(sprintf('SOURCE:PHASE:ADJUST %f', value));
        end
        
        function obj = set.alc(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
%             holdMap = containers.Map({'on','1','off','0'},{'OFF','OFF','ON','ON'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            obj.write(sprintf('SOURCE:POWER:ALC %s',onOffMap(value)));
%             obj.write(sprintf('SOURCE:POWER:ALC:HOLD %s',holdMap(value)));
        end
        
        function obj = set.pulse(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            
            obj.write(sprintf('SOURCE:PULM:STATE %s', onOffMap(value)));
        end
        
        function obj = set.pulseSource(obj, value)
            % Validate input
            onOffMap = containers.Map({'int','internal','ext','external'},...
                {'INT','INT','EXT','EXT'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            
            obj.write(sprintf('SOURCE:PULM:SOURCE %s', onOffMap(lower(value))));
        end
        
    end % end instrument parameter accessors
    
    
end % end class definition