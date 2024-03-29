function [data_h2, data_Et, sample_time] = Read_single_OSB_TH(Read, osbs, time_osa, osb_num)
%%%
    %input the array of readout 'Read' from OSA and the address of OSB we
    %want to read and reshape from
    %output the temperature (C) and humidity (%) signal reshaped as the OSB sensor format as well as the sample time points 
%%%
    pruned_size = find(osbs==osb_num);
    pruned_osb_num = pruned_size(1:end-mod(size(pruned_size,1),8));  %remove the last few less than 8 that might be due to termination of recording
    data_h2 = reshape(Read(pruned_osb_num,1),8,[]);  %channel by time (16 X seconds)
    data_Et = reshape(Read(pruned_osb_num,2),8,[]);
    sample_time = reshape(time_osa(pruned_osb_num),8,[]);
    sample_time = sample_time(1,:)-sample_time(1,1);

end