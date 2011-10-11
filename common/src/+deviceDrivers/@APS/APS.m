%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : APS.m
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : APS object for QLab Experiment Framework
%
%               Wraps libaps for access to APS unit.
%
% Restrictions/Limitations :
%
%   Requires libaps.dll and libaps.h
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%                BCD
%    10/5/2011   BRJ   Making compatible with expManager init sequence
%
% $Author: bdonovan $
% $Date$
% $Locker:  $
% $Name:  $
% $Revision$

% Copyright (C) BBN Technologies Corp. 2008-2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef APS < deviceDrivers.lib.deviceDriverBase
    %APS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        library_path = './lib/';
        device_id = 0;
        num_devices;
        message_manager =[];
        bit_file_path = '';
        bit_file = 'mqco_dac2_latest.bit';
        expected_bit_file_ver = hex2dec('10');
        Address = 0;
        verbose = 0;
        
        mock_aps = 0;

        chan_1;
        chan_2;
        chan_3;
        chan_4;
        
        samplingRate = 1200;   % Global sampling rate in units of MHz (1200, 600, 300, 100, 40)
        triggerSource = 'internal';  % Global trigger source ('internal', or 'external')
        is_running = false;
    end
    properties %(Access = 'private')
        is_open = 0;
        bit_file_programmed = 0;
        max_waveform_points = 4096;
        max_ll_length = 512;
        bit_file_version = 0;
        ELL_VERSION = hex2dec('10');
        
        % variables used to adjust link list padding
        pendingLength = 0;
        pendingValue = 0;
        expectedLength = 0;
        currentLength = 0;

    end
    
    properties (Constant)
        ADDRESS_UNIT = 4;
        MIN_PAD_SIZE = 4;
        
        ELL_MAX_WAVFORM = 8192;
        ELL_MAX_LL = 512;
        
        %% ELL Linklist Masks and Contants
        ELL_ADDRESS            = hex2dec('07FF');
        ELL_TIME_AMPLITUDE     = hex2dec('8000');
        ELL_LL_TRIGGER         = hex2dec('8000');
        ELL_ZERO               = hex2dec('4000');
        ELL_VALID_TRIGGER      = hex2dec('2000');
        ELL_FIRST_ENTRY        = hex2dec('1000');
        ELL_LAST_ENTRY         = hex2dec('800');
        ELL_TA_MAX             = hex2dec('FFFF');
        ELL_TRIGGER_DELAY      = hex2dec('3FFF');
        ELL_TRIGGER_MODE_SHIFT = 14;
        ELL_TRIGGER_DELAY_UNIT = 3.333e-9;
        
        LL_ENABLE = 1;
        LL_DISABLE = 0;
        LL_CONTINUOUS = 0;
        LL_ONESHOT = 1;
        LL_DC = 1;
        
        TRIGGER_SOFTWARE = 1;
        TRIGGER_HARDWARE = 2;
        
        ALL_DACS = -1;
        FORCE_OPEN = 1;
        
        FPGA0 = 0;
        FPGA1 = 2;
        
        channelStruct = struct('amplitude', 1.0, 'offset', 0.0, 'enabled', false, 'waveform', []);
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function d = APS()
            d = d@deviceDrivers.lib.deviceDriverBase('APS');
            d.load_library();
            
            buffer = libpointer('stringPtr','                            ');
            calllib('libaps','APS_ReadLibraryVersion', buffer,length(buffer.Value));
            d.log(sprintf('Loaded %s', buffer.Value));
            
            % build path for bitfiles
            script_path = mfilename('fullpath');
            extended_path = '\APS';
            baseIdx = strfind(script_path,extended_path);
            
            d.bit_file_path = script_path(1:baseIdx);
            
            % init channel structs
            d.chan_1 = d.channelStruct;
            d.chan_2 = d.channelStruct;
            d.chan_3 = d.channelStruct;
            d.chan_4 = d.channelStruct;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function connect(obj,address)
            
            % Experiment Framework function for connecting to
            % A APS, allow numeric or serial number based
            % addressing
            
            if isnumeric(address)
                val = obj.open(address);
            else
                val = obj.openBySerialNum(address);
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function disconnect(obj)
            obj.close()
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function log(aps,line)
            if ~isempty(aps.message_manager)
                aps.message_manager.disp(line)
            else
                if aps.verbose
                    disp(line)
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function load_library(d)
            if (ispc())
                libfname = 'libaps.dll';
            elseif (ismac())
                libfname = 'libaps.dylib';
            else
                libfname = 'libaps.so';
            end
            
            % build library path
            script = mfilename('fullpath');
            script = java.io.File(script);
            path = char(script.getParent());
            d.library_path = [path filesep 'lib' filesep];
            if ~libisloaded('libaps')
                [notfound warnings] = loadlibrary([d.library_path libfname], ...
                    [d.library_path 'libaps.h']);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function num_devices = enumerate(aps)
            % Library may not be opened if a stale object is left in
            % memory by matlab. So we reopen on if need be.
            aps.load_library()
            aps.num_devices = calllib('libaps','APS_NumDevices');
            
            if aps.mock_aps && aps.num_devices == 0
                aps.num_devices = 1;
            end
            
            num_devices = aps.num_devices;
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setAll is called as part of the Experiment initialize instruments
        function setAll(obj,settings)
            % Determine if it needs to be programmed
            bitFileVer = obj.readBitFileVersion();
            if ~isnumeric(bitFileVer) || bitFileVer ~= obj.expected_bit_file_ver
                obj.init();
            end
            
            obj.bit_file_programmed = 1;

            % read in channel settings so we know how to scale waveform
            % data
            ch_fields = {'chan_1', 'chan_2', 'chan_3', 'chan_4'};
            for i = 1:length(ch_fields)
                ch = ch_fields{i};
                obj.(ch).amplitude = settings.(ch).amplitude;
                obj.(ch).offset = settings.(ch).offset;
                obj.(ch).enabled = settings.(ch).enabled;
            end
            settings = rmfield(settings, ch_fields);
            
			% load AWG file before doing anything else
			if isfield(settings, 'seqfile')
				if ~isfield(settings, 'seqforce')
					settings.seqforce = false;
                end
                if ~isfield(settings, 'lastseqfile')
                    settings.lastseqfile = '';
                end
				
				% load an AWG file if the settings file is changed or if force == true
				if (~strcmp(settings.lastseqfile, settings.seqfile) || settings.seqforce)
					obj.loadConfig(settings.seqfile); % TODO
				end
			end
			settings = rmfield(settings, {'lastseqfile', 'seqfile', 'seqforce'});
			
            % parse remaining settings
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
                if ismember(name, methods(obj))
                    feval(['obj.' name], settings.(name));
                elseif ismember(name, properties(obj))
                    obj.(name) = settings.(name);
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function val = open(aps,id, force)
            if (aps.is_open)
                aps.close()
            end
            
            if exist('id','var')
                aps.device_id = id;
            end
            
            if ~exist('force','var')
                force = 0;
            end
            
            val = calllib('libaps','APS_Open' ,aps.device_id, force);
            if (val == 0)
                aps.log(sprintf('APS USB Connection Opened'));
                aps.is_open = 1;
            elseif (val == 1)
                aps.log(sprintf('Could not open device %i.', aps.device_id))
                aps.log(sprintf('Device may be open by a different process'));
            elseif (val == 2)
                aps.log(sprintf('APS Device Not Found'));
            else
                aps.log(sprintf('Unknown return from libaps: %i', val));
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = openBySerialNum(aps,serialNum)
            if (aps.is_open)
                aps.close()
            end
            
            val = calllib('libaps','APS_OpenBySerialNum' ,serialNum);
            if (val >= 0)
                aps.log(sprintf('APS USB Connection Opened'));
                aps.is_open = 1;
                aps.device_id = val;
            elseif (val == -1)
                aps.log(sprintf('Could not open device %i.', aps.device_id))
                aps.log(sprintf('Device may be open by a different process'));
            elseif (val == -2)
                aps.log(sprintf('APS Device Not Found'));
            else
                aps.log(sprintf('Unknown return from LIBAPS: %i', val));
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function close(aps)
            try
                val = calllib('libaps','APS_Close',aps.device_id);
            catch
                val = 0;
            end
            if (val == 0)
                aps.log(sprintf('APS USB Connection Closed\n'));
            else
                aps.log(sprintf('Error closing APS USB Connection: %i\n', val));
            end
            aps.is_open = 0;
        end
        
        function init(obj)
            % bare minimum commands to make the APS usable
            % Determine if APS needs to be programmed
            bitFileVer = obj.readBitFileVersion();
            if ~isnumeric(bitFileVer) || bitFileVer ~= obj.expected_bit_file_ver
                obj.loadBitFile();
            end
            
            obj.bit_file_programmed = 1;
            % set all channels to 1.2 GS/s
            for ch = 1:4
                obj.setFrequency(ch-1, 1200, 0);
            end
            obj.testPllSync();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = readBitFileVersion(aps)
            if aps.mock_aps
                 val = aps.ELL_VERSION;
                 return
            end
            val = calllib('libaps','APS_ReadBitFileVersion', aps.device_id);
            aps.bit_file_version = val;
            if val >= aps.ELL_VERSION
                aps.max_waveform_points = aps.ELL_MAX_WAVFORM;
                aps.max_ll_length = aps.ELL_MAX_LL;
            end
        end
        
        function dbgForceELLMode(aps)
            %% Force constants to ELL mode for debug testing
            aps.max_waveform_points = aps.ELL_MAX_WAVFORM;
            aps.max_ll_length = aps.ELL_MAX_LL;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function programFPGA(aps, data, bytecount,sel)
            if ~(aps.is_open)
                warning('APS:ProgramFPGA','APS is not open');
                return
            end
            aps.log('Programming FPGA ');
            val = calllib('libaps','APS_ProgramFpga',aps.device_id,data, bytecount,sel);
            if (val < 0)
                errordlg(sprintf('APS_ProgramFPGA returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadBitFile(aps,filename)
            
            if ~exist('filename','var')
                filename = [aps.bit_file_path aps.bit_file];
            end
            
            if ~(aps.is_open)
                warning('APS:loadBitFile','APS is not open');
                return
            end
            aps.setupVCX0();
            aps.setupPLL();
            
            % assume we are programming both FPGA with the same bit file
            Sel = 3;
            
            aps.log(sprintf('Loading bit file: %s', filename));
            eval(['[DataFileID, FOpenMessage] = fopen(''', filename, ''', ''r'');']);
            if ~isempty(FOpenMessage)
                error('APS:loadBitFile', 'Input DataFile Not Found');
            end
            
            [filename, permission, machineformat, encoding] = fopen(DataFileID);
            %eval(['disp(''Machine Format = ', machineformat, ''');']);
            
            [DataVec, DataCount] = fread(DataFileID, inf, 'uint8=>uint8');
            aps.log(sprintf('Read %i bytes.', DataCount));
            
            aps.programFPGA(DataVec, DataCount,Sel);
            fclose(DataFileID);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Waveform / Link List Load Functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadWaveform(aps,id,waveform,offset,validate, useSlowWrite)
            % id - channel (0-3)
            % waveform - int16 format waveform data (-8192, 8191)
            % offset - waveform memory offset (think memory location, not
            %   shift of zero), integer multiple of 4
            % validate - bool, reads back waveform data
            % useSlowWrite - bool, when false uses a faster buffered write
            if aps.mock_aps
                aps.log('Mock load waveform')
                return 
            end
            
            if ~(aps.is_open)
                warning('APS:loadWaveForm','APS is not open');
                return
            end
            if isempty(waveform)
                error('APS:loadWaveform','Waveform is required');
                return
            end
            
            if ~exist('offset','var')
                offset = 0;
            end
            
            if ~exist('validate','var')
                validate = 0;
            end
            
            if ~exist('useSlowWrite','var')
                useSlowWrite = 0;
            end
            
            aps.log(sprintf('Loading Waveform length: %i into DAC%i ', length(waveform),id));
            val = calllib('libaps','APS_LoadWaveform', aps.device_id,waveform,length(waveform),offset, id, validate, useSlowWrite);
            if (val < 0)
                errordlg(sprintf('APS_LoadWaveform returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadLinkList(aps,id,offsets,counts, ll_len)
            trigger = [];
            repeat = [];
            bank = 0;
            aps.loadLinkListELL(aps,id,offsets,counts, trigger, repeat, ll_len, bank)
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadLinkListELL(aps,id,offsets,counts, trigger, repeat, ll_len, bank, validate)
            if ~(aps.is_open)
                warning('APS:loadLinkListELL','APS is not open');
                return
            end
            
            if ~exist('validate','var')
                validate = 0;
            end
            
            aps.log(sprintf('Loading Link List length: %i into DAC%i bank %i ', ll_len,id, bank));
            val = calllib('libaps','APS_LoadLinkList',aps.device_id, offsets,counts,trigger,repeat,ll_len,id,bank, validate);
            if (val < 0)
                errordlg(sprintf('APS_LoadLinkList returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function clearLinkListELL(aps,id)
            aps.librarycall('Clear Bank 0','APS_ClearLinkListELL',id,0); % bank 0
            aps.librarycall('Clear Bank 1','APS_ClearLinkListELL',id,1); % bank 1
        end
        
        function loadConfig(aps, filename)
            % loads a complete, 4 channel configuration file
            
            % pseudocode:
            % open file
            % foreach channel
            %   load and scale/shift waveform data
            %   save channel waveform lib in chan_i struct
            %   clear old link list data
            %   load link list data (if any)
            %   save channel LL data in chan_i struct
            %   set link list mode
            
            % clear existing variable names
            clear Version WaveformLibs LinkLists
            load(filename)
            % if any channel has a link list, all channels must have a link
            % list
            % TODO: add more error checking
            if length(LinkLists) > 1 && (length(WaveformLibs) ~= length(LinkLists))
                error('Malformed config file')
            end
            
            aps.clearLinkListELL(0);
            aps.clearLinkListELL(1);
            %aps.clearLinkListELL(2);
            %aps.clearLinkListELL(3);
            
            for ch = 1:length(WaveformLibs)
                if ch <= length(WaveformLibs)
                    % load and scale/shift waveform data
                    wf = WaveformLibs{ch};
                    wf.set_offset(aps.(['chan_' num2str(ch)]).offset);
                    wf.set_scale_factor(aps.(['chan_' num2str(ch)]).amplitude);
                    aps.loadWaveform(ch-1, wf.prep_vector());
                end
            end
            
            for ch = 1:length(WaveformLibs)
                % clear old link list data
                
                % load link list data (if any)
                if ch <= length(LinkLists)
                    wf.ellData = LinkLists{ch};
                    wf.ell = true;
                    if wf.check_ell_format()
                        
                        wf.have_link_list = 1;
                    
                        ell = wf.get_ell_link_list();
                        if isfield(ell,'bankA') && ell.bankA.length > 0
                            
                            bankA = ell.bankA;
                            aps.loadLinkListELL(ch-1,bankA.offset,bankA.count, ...
                                bankA.trigger, bankA.repeat, bankA.length, 0);
                        end

                        if isfield(ell,'bankB')
                            bankB = ell.bankB;
                            aps.loadLinkListELL(ch-1,bankB.offset,bankB.count, ...
                                bankB.trigger, bankB.repeat, bankB.length, 1);
                        end

                        %aps.setLinkListRepeat(ch-1,ell.repeatCount);
                        fprintf('Ch %i repeat count: %d\n', ch, ell.repeatCount);
                        aps.setLinkListRepeat(ch-1,1000);
                    end
                    aps.setLinkListMode(ch-1, aps.LL_ENABLE, aps.LL_CONTINUOUS);
                end
                
                aps.(['chan_' num2str(ch)]).waveform = wf;
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Trigger / Pause / Disable Waveform or FPGA
        %% setLinkListMode
        %% setFrequency
        %%
        %% These function share a common base function to wrap libaps
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = librarycall(aps,mesg,func,varargin)
            % common base call for a number of functions
            if ~(aps.is_open)
                warning('APS:librarycall','APS is not open');
                val = -1;
                return
            end
            if (aps.verbose)
                aps.log(mesg);
            end
                        
            switch size(varargin,2)
                case 0
                    val = calllib('libaps',func,aps.device_id);
                case 1
                    val = calllib('libaps',func,aps.device_id, varargin{1});
                case 2
                    val = calllib('libaps',func,aps.device_id, varargin{1}, varargin{2});
                case 3
                    val = calllib('libaps',func,aps.device_id, varargin{1}, varargin{2}, varargin{3});
                otherwise
                    error('More than 3 varargin arguments to librarycall are not supported\n');
            end
            if (aps.verbose)
                aps.log('Done');
            end
        end
        
        function triggerWaveform(aps,id,trigger_type)
            val = aps.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'APS_TriggerDac',id,trigger_type);
        end
        
        function pauseWaveform(aps,id)
            val = aps.librarycall(sprintf('Pause Waveform %i', id), 'APS_PauseDac',id);
        end
        
        function disableWaveform(aps,id)
            val = aps.librarycall(sprintf('Disable Waveform %i', id), 'APS_DisableDac',id);
        end
        
        function triggerFpga(aps,id,trigger_type)
            val = aps.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'APS_TriggerFpga',id,trigger_type);
        end
        
        function pauseFpga(aps,id)
            val = aps.librarycall(sprintf('Pause Waveform %i', id), 'APS_PauseFpga',id);
        end
        
        function disableFpga(aps,id)
            val = aps.librarycall(sprintf('Disable Waveform %i', id), 'APS_DisableFpga',id);
        end
        
        function run(aps)
            % global run method
            
            trigger_type = aps.TRIGGER_SOFTWARE;
            if strcmp(aps.triggerSource, 'external')
                trigger_type = aps.TRIGGER_HARDWARE;
            end
            
            % based upon enabled channels, trigger both FPGAs, a single
            % FPGA, or individuals DACs
            trigger = [false false false false];
            channels = {'chan_1','chan_2','chan_3','chan_4'};
            for i = 1:4
                trigger(i) = aps.(channels{i}).enabled;
            end
            
            triggeredFPGA = [false false];
            if trigger % all channels enabled
                aps.triggerFpga(aps.ALL_DACS, trigger_type);
                triggeredFPGA = [true true];
            elseif trigger(1:2) %FPGA0
                triggeredFPGA(1) = true;
                aps.triggerFpga(aps.FPGA0, trigger_type)
            elseif trigger(3:4) %FPGA1
                triggeredFPGA(2) = true;
                aps.triggerFpga(aps.FPGA1, trigger_type)
            end
            
            % look at individual channels
            % NOTE: Poorly defined syncronization between channels in this
            % case.
            for channel = 1:4
                if ~triggeredFPGA(ceil(channel / 2)) && trigger(channel)
                    aps.triggerWaveform(channel-1,trigger_type)
                end
            end
            aps.is_running = true;
        end
        
        function stop(aps)
            % global stop method
            aps.disableFpga(aps.ALL_DACS);
        end
        
        function waitForAWGtoStartRunning(aps)
            % for compatibility with Tek driver
            % checks the state of the CSR to verify that a state machine
            % is running
        
            % TODO!! Needs an appropriate method in C library.
            % Kludgy workaround for now.
            if ~aps.is_running
                aps.run();
            end
        end
        
        function setLinkListMode(aps, id, enable, mode)
            % id : DAC channel (0-3)
            % enable : 1 = on, 0 = off
            % mode : 1 = one shot, 0 = continuous
            val = aps.librarycall(sprintf('Dac: %i Link List Enable: %i Mode: %i', id, enable, mode), ...
                'APS_SetLinkListMode',enable,mode,id);
        end
        
        function setLinkListRepeat(aps,id, repeat)
            val = aps.librarycall(sprintf('Dac: %i Link List Repeat: %i', id, repeat), ...
                'APS_SetLinkListRepeat',repeat,id);
        end
        
        function val = testPllSync(aps, id, numSyncChannels)
            if ~exist('id','var')
                id = 0;
            end
            if ~exist('numSyncChannels', 'var')
                numSyncChannels = 4;
            end
            val = aps.librarycall('Test Pll Sync: DAC: %i','APS_TestPllSync',id, numSyncChannels);
            if val ~= 0
                fprintf('Warning: APS::testPllSync returned %i\n', val);
            end
        end
        
        function val = setFrequency(aps,id, freq, testLock)
            if ~exist('testLock','var')
                testLock = 1;
            end
            val = aps.librarycall(sprintf('Dac: %i Freq : %i', id, freq), ...
                'APS_SetPllFreq',id,freq,testLock);
            if val ~= 0
                fprintf('Warning: APS::setFrequency returned %i\n', val);
            end
            
        end
        
        function setupPLL(aps)
            val = aps.librarycall('Setup PLL', 'APS_SetupPLL');
        end
        
        function setupVCX0(aps)
            val = aps.librarycall('Setup VCX0', 'APS_SetupVCXO');
        end
        
        function aps = set.samplingRate(aps, rate)
            % sets the sampling rate for all channels
            % rate - sampling rate in MHz (1200, 600, 300, 100, 40)
            if aps.samplingRate ~= rate
                for ch = 1:4
                    aps.setFrequency(ch-1, rate, 0);
                end
                aps.testPllSync();
            end
        end
        
        function readAllRegisters(aps)
            val = aps.librarycall(sprintf('Read Registers'), ...
                'APS_ReadAllRegisters');
        end
        
        function testWaveformMemory(aps, id, numBytes)
            val = aps.librarycall(sprintf('Test WaveformMemory'), ...
                'APS_TestWaveformMemory',id,numBytes);
        end
        
        function val =  readLinkListStatus(aps,id)
            val = aps.librarycall(sprintf('Read Link List Status'), ...
                'APS_ReadLinkListStatus',id);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Link List Format Conversion
        %%
        %% Converts link lists produced by PaternGen to a format suitable for use with the
        %% APS. Enforces length of waveform mod 4 = 0. Attempts to addjust padding to
        %% compenstate.
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% TODO: Clean up verbose messages
        
        function library = buildWaveformLibrary(aps, waveforms, useVarients, useEndPadding)
            % convert baseWaveforms to waveform array suitable for the APS
            
            if ~exist('useVarients','var')
                useVarients = 1;
            end
            
            if ~exist('useEndPadding','var')
                useEndPadding = 1;
            end
            
            offsets = containers.Map('KeyType','char','ValueType','any');
            lengths = containers.Map('KeyType','char','ValueType','any');
            varients = containers.Map('KeyType','char','ValueType','any');
            
            % allocate space for data;
            data = zeros([1, aps.max_waveform_points],'int16');
            
            idx = 1;
            
            if useEndPadding
                endPadding = 4;
            else
                endPadding = 0;
            end
            
            % loop through waveform library
            keys = waveforms.keys();
            while keys.hasMoreElements()
                key = keys.nextElement();
                orgWF = waveforms.get(key);
                
                varientWFs = {};
                if useVarients
                    endPad = 3;
                else
                    endPad = 0;
                end
                if length(orgWF) == 1
                    endPad = 0;
                end
                
                for leadPad = 0:endPad
                    wf = [];  % clear waveform
                    for i = 1:leadPad
                        wf(end+1) = 0;
                    end
                    wf(end+1:end+length(orgWF)) = orgWF;
                    % add 8 extra zero points to handle
                    % TA pairs of 0 and 1
                    if useEndPadding
                    for i = 1:endPadding
                        wf(end+1) = 0;
                    end
                    end

                    % test for padding to mod 4
                    if length(wf) == 1
                        % time amplitude pair
                        % example to save value repeated four times
                        wf = ones([1,aps.ADDRESS_UNIT]) * wf;
                    end
                    pad = aps.ADDRESS_UNIT - mod(length(wf),aps.ADDRESS_UNIT);
                    if pad ~= 0 && pad < aps.MIN_PAD_SIZE
                        % pad to length 4
                        wf(end+1:end+pad) = zeros([1,pad],'int16');
                    end
                    
                    assert(mod(length(wf),aps.ADDRESS_UNIT) == 0, 'WF Padding Failed')
                    
                    %insert into global waveform array
                    data(idx:idx+length(wf)-1) = wf;
                    
                    if leadPad == 0
                        offsets(key) = idx;
                        lengths(key) = length(wf);
                    end
                    if useVarients
                        varient.offset = idx;
                        % set length of wf remove extra 8 points that
                        % are used to handle 0 and 1 count TA
                        varient.length = length(wf) - endPadding;
                        varient.pad = leadPad;
                        varientWFs{end+1} = varient;
                    end
                    idx = idx + length(wf);
                end
                if useVarients && length(orgWF) > 1
                    varients(key) = varientWFs;
                end
            end
            
            if idx > aps.max_waveform_points
                throw(MException('APS:OutOfMemory',sprintf('Waveform memory %i exceeds APS maximum of %i', idx, aps.max_waveform_points)));
            end
            
            % trim data to only points used
            data = data(1:idx-1);  % one extra point as it is the next insertion point
            
            % double check mod ADDRESS_UNIT
            assert(mod(length(data),aps.ADDRESS_UNIT) == 0,...
                'Global Link List Waveform memory should be mod 4');
            
            library.offsets = offsets;
            library.lengths = lengths;
            library.varients = varients;
            library.waveforms = data;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [offsetVal countVal ] = entryToOffsetCount(aps,entry,library, firstEntry, lastEntry)
            
            entryData.offset = library.offsets(entry.key);
            entryData.length = library.lengths(entry.key);
            
            if library.varients.isKey(entry.key)
                entryData.varientWFs = library.varients(entry.key);
            else
                entryData.varientWFs = [];
            end
            
            aps.expectedLength = aps.expectedLength + entry.length * entry.repeat;
            
            % correct for changing in padding
            
            adjustNegative = 0;
            
            if aps.pendingLength > 0 && ~isempty(entryData.varientWFs)
                % attempt to us a varient
                padIdx = aps.pendingLength + 1;
                assert(padIdx > 0 && padIdx <= aps.ADDRESS_UNIT,sprintf('Padding Index %i Out of Range', padIdx));
                if length(entryData.varientWFs) >= padIdx   % matlab index offset
                    varient = entryData.varientWFs(padIdx);
                    if iscell(varient), varient = varient{1}; end; % remove cell wrapper
                    entryData.offset = varient.offset;
                    entryData.length = varient.length;
                    assert(varient.pad == aps.pendingLength,'Pending length pad does not match');
                    if aps.verbose
                        fprintf('\tUsing WF varient with pad: %i\n', padIdx - 1);
                    end
                end
            elseif aps.pendingLength < 0
                % if pattern is running long and output is zero trim the length
                % may get bumped back up
                if entry.isZero
                    entry.repeat = entry.repeat + aps.pendingLength;
                    adjustNegative = 1;
                    if aps.verbose
                        fprintf('\tTrimming zero pad by: %i from %i\n', aps.pendingLength);
                    end
                end
            end
            
            %% convert from 1 based count to 0 based count
            %% div by 4 required for APS addresses
            address = (entryData.offset - 1) / aps.ADDRESS_UNIT;
            
            % offset register format
            %  15  14  13   12   11  10 9 8 7 6 5 4 3 2 1 0
            % | A | Z | T | LS | LE |      Offset / 4      |
            %
            %  Address - Address of start of waveform / 4
            %  A       - Time Amplitude Pair
            %  Z       - Output is Zero
            %  T       - Entry has valid output trigger delay
            %  LS      - Start of Mini Link List
            %  LE      - End of Mini Link List
            
            offsetVal = bitand(address, aps.ELL_ADDRESS);  % address
            if entry.isTimeAmplitude
                offsetVal = bitor(offsetVal, aps.ELL_TIME_AMPLITUDE);
            end
            
            if entry.isZero
                offsetVal = bitor(offsetVal, aps.ELL_ZERO);
            end
            
            if entry.hasTrigger
                offsetVal = bitor(offsetVal, aps.ELL_VALID_TRIGGER);
            end
            
            if firstEntry  % start of link list
                %TODO hard code firstEntry
                % currently not using
                %offsetVal = bitor(offsetVal, aps.ELL_FIRST_ENTRY);                
            end
            
            if lastEntry % end of link list
                %TODO hard code lastEntry
                offsetVal = bitor(offsetVal, aps.ELL_LAST_ENTRY);
            end
            
            % use entryData to get length as it includes the padded
            % length
            if ~entry.isTimeAmplitude
                countVal = fix(entryData.length/aps.ADDRESS_UNIT);
            else
                countVal = fix(floor(entry.repeat / aps.ADDRESS_UNIT));
                diff = entry.repeat - countVal * aps.ADDRESS_UNIT;
                aps.pendingValue = library.waveforms(entryData.offset);
            end
            if (~entry.isTimeAmplitude && countVal > aps.ELL_ADDRESS) || ...
                    (entry.isTimeAmplitude && countVal > aps.ELL_TA_MAX)
                error('Link List countVal %i is too large', countVal);
            end
            
            aps.currentLength = aps.currentLength + countVal * aps.ADDRESS_UNIT;
            
            % test to see if the pattern is running long and we need to trim
            % pendingLength
            
            aps.pendingLength = aps.expectedLength - aps.currentLength;
            
            if aps.verbose
                fprintf('\tExpected Length: %i Actual Length: %i Pending: %i \n',  ...
                    aps.expectedLength, aps.currentLength, aps.pendingLength);
            end
        end
        
        function [offsetVal countVal ] = peakEntryToOffsetCount(aps,entry,library)            
            entryData.offset = library.offsets(entry.key);
            entryData.length = library.lengths(entry.key);
            
            if library.varients.isKey(entry.key)
                entryData.varientWFs = library.varients(entry.key);
            else
                entryData.varientWFs = [];
            end
            
            expectedLength = aps.expectedLength + entry.length * entry.repeat;
            
            % correct for changing in padding
            
            adjustNegative = 0;
            
            if aps.pendingLength > 0 && ~isempty(entryData.varientWFs)
                % attempt to us a varient
                padIdx = aps.pendingLength + 1;
                assert(padIdx > 0 && padIdx <= aps.ADDRESS_UNIT,sprintf('Padding Index %i Out of Range', padIdx));
                if length(entryData.varientWFs) >= padIdx   % matlab index offset
                    varient = entryData.varientWFs(padIdx);
                    if iscell(varient), varient = varient{1}; end; % remove cell wrapper
                    entryData.offset = varient.offset;
                    entryData.length = varient.length;
                    assert(varient.pad == aps.pendingLength,'Pending length pad does not match');
                    if aps.verbose
                        fprintf('\tUsing WF varient with pad: %i\n', padIdx - 1);
                    end
                end
            elseif aps.pendingLength < 0
                % if pattern is running long and output is zero trim the length
                % may get bumped back up
                if entry.isZero
                    entry.repeat = entry.repeat + aps.pendingLength;
                    adjustNegative = 1;
                    if aps.verbose
                        fprintf('\tTrimming zero pad by: %i from %i\n', aps.pendingLength);
                    end
                end
            end
            
            %% convert from 1 based count to 0 based count
            %% div by 4 required for APS addresses
            address = (entryData.offset - 1) / aps.ADDRESS_UNIT;
            
            offsetVal = bitand(address, aps.ELL_ADDRESS);  % address
            
            % use entryData to get length as it includes the padded
            % length
            if ~entry.isTimeAmplitude
                countVal = fix(entryData.length/aps.ADDRESS_UNIT);
            else
                countVal = fix(floor(entry.repeat / aps.ADDRESS_UNIT));
                diff = entry.repeat - countVal * aps.ADDRESS_UNIT;
                aps.pendingValue = library.waveforms(entryData.offset);
            end
            if (~entry.isTimeAmplitude && countVal > aps.ELL_ADDRESS) || ...
                    (entry.isTimeAmplitude && countVal > aps.ELL_TA_MAX)
                error('Link List countVal %i is too large', countVal);
            end
            
            currentLength = aps.currentLength + countVal * aps.ADDRESS_UNIT;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function triggerVal = entryToTrigger(aps,entry)
            % handle trigger values
            %% Trigger Delay
            %  15  14  13   12   11  10 9 8 7 6 5 4 3 2 1 0
            % | Mode |                Delay                |
            % Delay = time in 3.333 ns increments ( 0 - 54.5 usec )
            
            % TODO:  hard code trigger for now, need to think about how to
            % describe
            triggerMode = 3; % do nothing
            triggerDelay = 0;
            
            triggerMode = bitshift(triggerMode,aps.ELL_TRIGGER_MODE_SHIFT);
            triggerDelay = fix(round(triggerDelay / aps.ELL_TRIGGER_DELAY_UNIT));
            
            triggerVal = bitand(triggerDelay, aps.ELL_TRIGGER_DELAY);
            triggerVal = bitor(triggerVal, triggerMode);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [wf, banks] = convertLinkListFormat(aps, pattern, useVarients, waveformLibrary, miniLinkRepeat, useEndPadding)
            if aps.verbose
               fprintf('APS::convertLinkListFormat useVarients = %i\n', useVarients) 
            end
            
            if ~exist('useVarients','var') || isempty(useVarients)
                useVarients = 1;
            end
            
            if ~exist('useEndPadding','var') || isempty(useVarients)
                useEndPadding = 1;
            end
            
            
            if ~exist('waveformLibrary','var') || isempty(waveformLibrary)
                waveformLibrary = aps.buildWaveformLibrary(pattern.waveforms, useVarients);
            end
            
            if ~exist('miniLinkRepeat', 'var') || isempty(miniLinkRepeat)
                miniLinkRepeat = 1;
            end
            
            wf = APSWaveform();
            wf.data = waveformLibrary.waveforms;
            
            function [bank, idx] = allocateBank()
                bank.offset = zeros([1,aps.max_ll_length],'uint16');
                bank.count = zeros([1,aps.max_ll_length],'uint16');
                bank.trigger = zeros([1,aps.max_ll_length],'uint16');
                bank.repeat = zeros([1,aps.max_ll_length],'uint16');
                bank.length = aps.max_ll_length;
                
                idx = 1;
                % force Qid at start with ls set to setup mini link list
                
                %{
                offsetVal = 0;
                offsetVal = bitor(offsetVal, aps.ELL_ZERO);
                offsetVal = bitor(offsetVal, aps.ELL_FIRST_ENTRY); 
                offsetVal = bitor(offsetVal, aps.ELL_TIME_AMPLITUDE);
                
                triggerVal = 0;
                countVal = 0;
                
                bank.offset(1) = uint16(offsetVal);
                bank.count(1) = uint16(countVal);
                bank.trigger(1) = uint16(triggerVal);
                
                repeat = uint16(1000);
                bank.repeat(1) = repeat;
                idx = 2;
                %}
            end
            
            function bank = trimBank(bank,len)
                bank.offset = bank.offset(1:len);
                bank.count = bank.count(1:len);
                bank.trigger = bank.trigger(1:len);
                bank.repeat = bank.repeat(1:len);
                bank.length = len;
            end
            
            curBank = 1;
            [banks{curBank} idx] = allocateBank();
            
            % clear padding adjust variables
            aps.pendingLength = 0;
            aps.pendingValue = 0;
            aps.expectedLength = 0;
            aps.currentLength = 0;
            
            for i = 1:length(pattern.linkLists)
                linkList = pattern.linkLists{i};
                
                lenLL = length(linkList);
                
                if  lenLL > aps.max_ll_length
                    error('Individual Link List %i exceeds APS maximum link list length', i)
                end
                
                
                if 1 % WARNING forcing new bank for every entry
                if (idx + lenLL) > aps.max_ll_length
                    banks{curBank} = trimBank(banks{curBank},idx-1);
                    curBank = curBank + 1;
                    [banks{curBank} idx] = allocateBank();
                end
                else
                    %if curBank ~= 1
                    if curBank > 0
                        banks{curBank} = trimBank(banks{curBank},idx-1);
                    end
                        curBank = curBank + 1;
                        [banks{curBank} idx] = allocateBank();
                   % end
                end
                
                skipNext = 0;
                for j = 1:lenLL
                    entry = linkList{j};
                    
                    if aps.verbose
                        fprintf('Entry %i: key: %s length: %2i repeat: %4i \n', j, entry.key, entry.length, ...
                            entry.repeat);
                    end
                    
                    % for test, put trigger on first entry of every mini-LL
                    if j == 1
                        entry.hasTrigger = 1;
                    end
                    
                    [offsetVal countVal] = entryToOffsetCount(aps,entry,waveformLibrary, j == 1, j == lenLL - 1);

                    if skipNext
                        % skip after processing entryToOffsetCount
                        % to make sure aps.pending* is set correctly
                        skipNext = 0;
                        continue
                    end
                    
                    % get a peek at the next entry
                    if useEndPadding && j ~= lenLL
                        nextEntry = linkList{j+1};
                        [offsetVal2 countVal2] = peakEntryToOffsetCount(aps,nextEntry,waveformLibrary);

                        if countVal2 < 2      
                            % if TA pair is less than 2 use extra padding at end
                            % of waveform in library
                            if nextEntry.isTimeAmplitude && nextEntry.isZero
                                if aps.verbose
                                    fprintf('Found TA & Z with count = %i. Adjusting waveform end.\n', countVal2);
                                end
                                countVal = countVal + countVal2;
                                
                                skipNext = 1;                            
                            else
                                fprintf('Warning: countVal2 < 2 but not TAZ\n')
                            end
                        end
                    end
                    
                    if countVal < 2
                        fprintf('Warning entry count < 2. This causes problems with APS\n')
                    end
                    
                    % if we are at end end of the link list entry but this is
                    % not the last of the link list entries set the mini link
                    % list start flag
                    if (i < length(pattern.linkLists)) && (j == lenLL)
                        offsetVal = bitor(offsetVal, aps.ELL_FIRST_ENTRY);   
                    end
                    
                    if aps.verbose
                        fprintf('\tLink List Offset: %4i Length: %4i Expanded Length: %4i TA: %i Zero:%i\n', ...
                            bitand(offsetVal,aps.ELL_ADDRESS) * aps.ADDRESS_UNIT, ...
                            countVal, countVal * aps.ADDRESS_UNIT, ...
                            entry.isTimeAmplitude, entry.isZero);
                    end
                    
                    % for first mini-LL entry only, set LS bit
                    if idx == 1
                        offsetVal = bitor(offsetVal, aps.ELL_FIRST_ENTRY); 
                    end
                    
                    triggerVal = aps.entryToTrigger(j == lenLL);
                    
                    banks{curBank}.offset(idx) = uint16(offsetVal);
                    banks{curBank}.count(idx) = uint16(countVal);
                    banks{curBank}.trigger(idx) = uint16(triggerVal);
                    
                   
                    
                    % TODO: hard coded repeat count of 1
                    if j == lenLL
                        repeat = uint16(miniLinkRepeat);
                        banks{curBank}.repeat(idx) = repeat;
                    else
                        banks{curBank}.repeat(idx) = 0;
                    end
                    
                    idx = idx + 1;
                end
            end
            
            %{
            for qq = 1:10
            offsetVal = 0;
            offsetVal = bitor(offsetVal, aps.ELL_ZERO);
            offsetVal = bitor(offsetVal, aps.ELL_TIME_AMPLITUDE);
            
            triggerVal = 0;
            countVal = 0;
            repeatVal = 0;
            
            bank.offset(idx) = uint16(offsetVal);
            bank.count(idx) = uint16(countVal);
            bank.trigger(idx) = uint16(triggerVal);
            bank.repeat(idx) = uint16(repeatVal);
            
            idx = idx + 1;
            end
            %}
            
            % trim last bank
            banks{curBank} = trimBank(banks{curBank},idx-1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [pattern] = linkListToPattern(aps,wf, banks)
            if aps.verbose
               fprintf('APS::linkListToPattern\n') 
            end
            pattern = [];
            if iscell(banks)
                nBanks = length(banks);
            else
                nBanks = 1;
            end
            for i = 1:nBanks
                if aps.verbose
                    fprintf('Processing Bank: %i\n', i);
                end
                if iscell(banks)
                    bank = banks{i};
                else
                    bank = banks;
                end
                
                for j = 1:bank.length
                    
                    offset = bank.offset(j);
                    count = bank.count(j);
                    TA = bitand(offset, aps.ELL_TIME_AMPLITUDE) == aps.ELL_TIME_AMPLITUDE;
                    zero = bitand(offset, aps.ELL_ZERO) == aps.ELL_ZERO;
                    
                    idx = aps.ADDRESS_UNIT*bitand(offset, aps.ELL_ADDRESS) + 1;
                    
                    expandedCount = aps.ADDRESS_UNIT * count;
                    
                    if ~TA && ~zero
                        endIdx = aps.ADDRESS_UNIT*count + idx - 1;
                        if aps.verbose
                            fprintf('Using wf.data(%i:%i) length: %i TA:%i zero:%i\n', idx, endIdx,...
                                length(idx:endIdx), TA , zero);
                        end;
                        newPat = wf.data(idx:endIdx);
                        assert(mod(length(newPat),aps.ADDRESS_UNIT) == 0, ...
                            'Expected len(wf) % 4 == 0');
                    elseif zero
                        if aps.verbose
                            fprintf('Using zeros: %i\n', expandedCount);
                        end
                        newPat = zeros([1, expandedCount],'int16');
                    elseif TA
                        if aps.verbose
                            fprintf('Using TA: %i@%i\n', expandedCount, wf.data(idx));
                        end
                        newPat = wf.data(idx)*ones([1, expandedCount],'int16');
                    end
                    
                    pattern = [pattern newPat];
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [unifiedX unifiedY] = unifySequenceLibraryWaveforms(aps,sequences)
            unifiedX = java.util.Hashtable();
            unifiedY = java.util.Hashtable();
            h = waitbar(0,'Unifying Waveform Tables');
            n = length(sequences);
            for seq = 1:n
                waitbar(seq/n,h);
                sequence = sequences{seq};
                xwaveforms = sequence.llpatx.waveforms;
                ywaveforms = sequence.llpaty.waveforms;
                
                xkeys = xwaveforms.keys;
                ykeys = ywaveforms.keys;
                
                while xkeys.hasMoreElements()
                    key = xkeys.nextElement();
                    if ~unifiedX.containsKey(key)
                        unifiedX.put(key,xwaveforms.get(key));
                    end
                end
                
                while ykeys.hasMoreElements()
                    key = ykeys.nextElement();
                    if ~unifiedY.containsKey(key)
                        unifiedY.put(key,ywaveforms.get(key));
                    end
                end
            end
            
            close(h);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setModeR5(aps)
            aps.bit_file = 'cbl_aps2_r5_d6ma_fx.bit';
            aps.expected_bit_file_ver = 5;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    methods(Static)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function unload_library()
            if libisloaded('libaps')
                unloadlibrary libaps
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function wf = getNewWaveform()
            % Utility function to get a APS wavform object from APS Driver
            try
                wf = APSWaveform();
            catch
                % if APSWaveform is not on the path
                % attempt to add the util directory to the path
                % and reload the waveform
                path = mfilename('fullpath');
                % search path
                spath = ['common' filesep 'src'];
                idx = strfind(path,spath);
                path = [path(1:idx+length(spath)) 'util'];
                addpath(path);
                wf = APSWaveform();
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% External Functions (See external files)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% UnitTest of Link List Format Conversion
        %% See: LinkListFormatUnitTest.m
        LinkListFormatUnitTest(sequence,useEndPadding)
        
        LinkListUnitTest(sequence, dc_offset)
        LinkListUnitTest2
        
        sequence = LinkListSequences(sequence)
        
        function aps = UnitTest(skipLoad)
            % work around for not knowing full name
            % of class - can not use simply APS when in 
            % experiment framework
            classname = mfilename('class');
            
            % tests channel 0 & 1 output for basic bit file testing
            aps = eval(sprintf('%s();', classname));
            aps.verbose = 1;
            apsId = 0;
            
            aps.open(apsId);
            
            if (~aps.is_open)
                aps.close();
                aps.open(apsId);
                if (~aps.is_open)
                    error('Could not open aps')
                end
            end
            
            ver = aps.readBitFileVersion();
            fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
            if ver ~= aps.expected_bit_file_ver
                aps.loadBitFile();
                ver = aps.readBitFileVersion();
                fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
            end

            validate = 0;
            useSlowWrite = 0;

            wf = aps.getNewWaveform();
            wf.data = [zeros([1,2000]) ones([1,2000])];
            wf.set_scale_factor(0.8);
            
            for ch = 0:3
                aps.setFrequency(ch, 1200)
                aps.loadWaveform(ch, wf.get_vector(), 0, validate,useSlowWrite);
                
            end
            
            aps.triggerFpga(0,1);
            aps.triggerFpga(2,1);
            keyboard
            aps.pauseFpga(0);
            aps.pauseFpga(2);
            aps.close();
      
        end
        
    end
end
