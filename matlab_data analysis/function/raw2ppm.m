function ppm = raw2ppm(ref,raw)
    
    ppm = 0.5*exp((ref-raw)/512);

end