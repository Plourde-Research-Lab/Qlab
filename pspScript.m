for i = 0.1:0.1:2
   str = num2str(i);
   display(['Change length to ' num2str(i)])
   pause();
   JPMExpScripter(['Cav_Sweep_' str 'usDriveLength2']);
   data = load_jpm_data('latest');
   hold all;
   plot(data.xpoints, data.data, 'DisplayName', [str 'us']);
   legend('-DynamicLegend');
   
   eval(sprintf(['pspData2_' strrep(str, '.', '_') 'us = data;']));
end