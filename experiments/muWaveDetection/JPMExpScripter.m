% timeDomain
function out = JPMExpScripter(expName)

    state_cal_measurement('jpm1', [expName 'Cal']);
    out = ExpScripter(expName);
end
