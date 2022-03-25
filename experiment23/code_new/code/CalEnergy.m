function energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType)
    if strcmp(WinType ,'hanning') == 1
        energy = sum(abs(enframe(wave_data, hanning(FrameLen), FrameInc)).^2, 2);
    elseif strcmp(WinType, 'hamming') == 1
        energy = sum(abs(enframe(wave_data, hamming(FrameLen), FrameInc)).^2, 2);
    else
        energy = sum(abs(enframe(wave_data, FrameLen, FrameInc)).^2, 2);     
    end

end