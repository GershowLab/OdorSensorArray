function [Read, osbs, time_osa] = Read_OSA(osa_fname)
%%%
    %input osa_fname for the path to a text file
    %output Read table for all sensor readings, the address of OSB, and the
    %milisecond precision time points
%%%
    osa_table = readtable(osa_fname);
    read_pos = find(osa_table.code==1);  %code: 0 for setting, 1 for odor, 2 for temperature
    time_osa = osa_table.ms_timer(read_pos);   %ms clock
    valid = osa_table.valid(read_pos);  %validity of the reading
    invalid = find(valid==0);
    osbs = osa_table.osb_index(read_pos);  %OSB index
    allread = [osa_table.data_1  osa_table.data_2];  %raw readings
    Read = allread(read_pos,:);
    Read(invalid,:) = NaN;
end