function amp = CalAmp(wave_data, FrameLen, FrameInc, WinType)
    if strcmp(WinType ,'hanning') == 1
        amp = sum(abs(enframe(wave_data, hanning(FrameLen), FrameInc)), 2);
    elseif strcmp(WinType, 'hamming') == 1
        amp = sum(abs(enframe(wave_data, hamming(FrameLen), FrameInc)), 2);
    else
        amp = sum(abs(enframe(wave_data, FrameLen, FrameInc)), 2);     
    end

end