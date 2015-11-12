function optimize_mixers_Q(channel)
    assert(~isempty(channel), 'Oops! You must specify a channel to optimize.')
    % create a mixer optimizer object
    cfgFile = fullfile(getpref('qlab', 'cfgDir'), 'optimize_mixer_Q.json');
    optimizer = MixerOptimizer();
    optimizer.Init(cfgFile, channel);
    optimizer.Do();
end