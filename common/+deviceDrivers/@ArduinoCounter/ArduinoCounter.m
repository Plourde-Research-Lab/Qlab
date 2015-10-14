classdef (Sealed) ArduinoCounter < deviceDrivers.lib.Serial
    %ARDUINOCOUNTER Driver for Arduino Counter 
    %   V0.1 for counting JPM Switching Events
    %   Arduino receives TTL pulses from comparator
    
    properties (Access = public)
        acquireMode = 'averager'
        data
        reps = 1000
        segments = 1
    end
    
    properties (Access = private)
       done 
    end
    
    properties (Constant = true)
        MAX_CHANNELS  =  2;
    end
    
    events
       DataReady 
    end
    
    methods (Access = public)
        function obj = ArduinoCounter()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
            obj.baudRate = 115200;
            
            obj.data = zeros(1, obj.segments);
        end
        
        function setAll(obj, settings)
           obj.reps = settings.reps;
           obj.segments = settings.segments;
           obj.resetCount()
        end
        
        function resetCount(obj)
            cmd = 't';
            obj.write(cmd)
        end
        
        function out = getCount(obj)
           out = fscanf(obj.interface);
        end
        
        function acquire(obj)
%             obj.data = str2double(obj.getCount());
%             notify(obj, 'DataReady');
%             obj.done = true;
            obj.data = [];
            for index = 1:obj.segments
                obj.data = [obj.data, str2num(obj.getCount())];
            end
            notify(obj, 'DataReady');
            obj.done=true;
        end
        
        function status = wait_for_acquisition(obj, timeOut)
            if ~exist('timeOut','var')
                timeOut = obj.timeOut;
            end
            
            %Loop until all are processed
            t = tic();
            while toc(t) < timeOut
                if obj.done
                    status = 0;
                    return
                else
                    pause(0.2);
                end
            end
            status = -1;
            warning('ArduinoCounter:TIMEOUT', 'Arduino Counter timed out while waiting for acquisition');
        end
        
        function stop(obj)
            obj.done = true;
            obj.disconnect(); 
        end
        
    end
end

