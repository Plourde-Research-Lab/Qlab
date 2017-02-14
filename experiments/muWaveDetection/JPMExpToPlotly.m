function  JPMExpToPlotly( name )
%JPMEXPTOPLOTLY Summary of this function goes here
%   Detailed explanation goes here
    JPMExpScripter(name);
    data = load_jpm_data('latest');
    figure;
    if data.dimension > 1
        imagesc(data.xpoints, data.ypoints, sqrt(real(data.data).^2 + imag(data.data).^2));
    else
        plot(data.xpoints, sqrt(real(data.data).^2 + imag(data.data).^2));
    end
    title(name);
    fig2plotly;
end

