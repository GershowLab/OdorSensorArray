function [closest_time,closest_pos] = timealign(sample_time,fine_time)

closest_time = zeros(1,length(sample_time));
closest_pos = zeros(1,length(sample_time));
for tt = 1:length(sample_time)
    [~,pos] = min(abs(sample_time(tt)-fine_time));
    closest_time(tt) = fine_time(pos);
    closest_pos(tt) = pos;
end

end