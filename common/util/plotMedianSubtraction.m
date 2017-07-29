function plotMedianSubtraction
%plotCutSubtracted2DMeasData(NORMALIZATION_DIRECTION, DATA_VARIABLE) Plot
%a 2D data subtracting a median cut from each slice.
%   plotCutSubtracted2DMeasData(DATA_VARIABLE, NORMALIZATION_DIRECTION)
%   plots cut-substracted data. The slices are averaged and removed from
%   the data.


% Get Current Figure and Copy

% fig = copyobj(gcf,0);
ax = get(gca,'Children');
x = ax.get('XData');
y = ax.get('YData');
z = ax.get('CData');

% Get axis names
a = findobj(gcf,'type','axe');
xl = get(get(a,'xlabel'),'string');
yl = get(get(a,'ylabel'),'string');
tl = get(get(a,'title'),'string');

if strfind(lower(xl), 'freq')
    subz = z - (ones(size(z,1),1) * median(z));
elseif strfind(lower(yl), 'freq');
    subz = z - (median(z,2) * ones(1, size(z,2)));
end

imagesc(x, y, abs(subz));
xlabel(xl);ylabel(yl);title(tl);

end