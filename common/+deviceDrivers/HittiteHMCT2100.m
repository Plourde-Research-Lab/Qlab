classdef (Sealed) HittiteHMCT2100 < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIBorVISA
    % Hittite HMC-T2100 Microwave Generator
    %
    %
    % Author(s): Caleb Howington
    % Generated on: Mon Jan 4 2016

    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        frequency
        power
        phase
        mod
        alc
        pulse
        pulseSource
    end % end device properties

    methods
        function obj = HittiteHMCT2100()
            %obj = obj@deviceDrivers.lib.uWSource();
        end

		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            val = str2double(obj.query('freq?;'))*1e-9; % convert to GHz
        end
        function val = get.power(obj)
            val = str2double(obj.query('power?'));
        end
        function val = get.output(obj)
            val = obj.query('output?');
        end

        % property setters
        function obj = set.frequency(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf('freq:cw %20.10fGHz', round(value, 5)));
            %Wait for frequency to settle
            pause(0.005);
        end
        function obj = set.power(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf('POWer:LEVel:IMMediate %ddbm', value));
        end
        function obj = set.output(obj, value)
            obj.write(['output ' obj.cast_boolean(value)]);
        end
        % set phase in degrees
%         function obj = set.phase(obj, ~)
%             pass;
%         end
%         function obj = set.mod(obj, ~)
%             pass;
%         end
%         function obj = set.alc(obj, ~)
%             pass;
%         end
%         function obj = set.pulse(obj, ~)
%             pass;
%         end
%         function obj = set.pulseSource(obj, ~)
%             pass;
%         end

%         function errs=check_errors(obj)
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             % Check for errors
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             first=1;
%             errs=[];
%             while 1
%                 a=query(obj,'SYST:ERR?');
%                 loc=find(a==',');
%                 errflag=str2num(a(1:(loc-1)));
%                 if errflag == 0
%                     break;
%                 end
%                 errs=[errs errflag];
%                 if first
%                   fprintf('Error occured on N5183\n')
%                   first=0;
%                 end
%                 fprintf('  -> "%s"\n',a);
%             end
%         end
    end % end instrument parameter accessors

    methods (Static)

        %Helper function to cast boolean inputs to 'on'/'off' strings
        function out = cast_boolean(in)
            if isnumeric(in)
                in = logical(in);
            end
            if islogical(in)
                if in
                    in = 'on';
                else
                    in = 'off';
                end
            end

            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            assert(checkMapObj.isKey(lower(in)), 'Invalid input');
            out = checkMapObj(lower(in));
        end
        function s=def(s,opt,def)
            % function s=def(s,opt,def)
            %% Utility functions
            if ~isfield(s,opt)
                s.(opt)=def;
            end
        end
    end

end % end class definition
