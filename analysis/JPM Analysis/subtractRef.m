function dif = subtractRef

    int = squeeze(read_records(fullfile(getpref('qlab', 'recordLocation'), 'integrate')));
    ref_int = squeeze(read_records(fullfile(getpref('qlab', 'recordLocation'), 'ref_integrate')));
    
    dif = gdivide(int, ref_int);
end