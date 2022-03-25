function ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType)
%     if WinType == 'hanning'
    if strcmp(WinType, 'hanning') == 1
        tmp1  = enframe(wave_data(1:end-1), hanning(FrameLen), FrameInc);%分帧，所得矩阵为fix（（x(1:end-1)-FrameLen+FrameInc）/FrameInc）*FrameLen
        tmp2  = enframe(wave_data(2:end)  , hanning(FrameLen), FrameInc);%分帧，所得矩阵为fix（（x(2:end)-FrameLen+FrameInc）/FrameInc）*FrameLen
    elseif strcmp(WinType , 'hamming') == 1
        tmp1  = enframe(wave_data(1:end-1), hamming(FrameLen), FrameInc);%分帧，所得矩阵为fix（（x(1:end-1)-FrameLen+FrameInc）/FrameInc）*FrameLen
        tmp2  = enframe(wave_data(2:end)  , hamming(FrameLen), FrameInc);%分帧，所得矩阵为fix（（x(2:end)-FrameLen+FrameInc）/FrameInc）*FrameLen
    else
        tmp1  = enframe(wave_data(1:end-1), (FrameLen), FrameInc);%分帧，所得矩阵为fix（（x(1:end-1)-FrameLen+FrameInc）/FrameInc）*FrameLen
        tmp2  = enframe(wave_data(2:end)  , (FrameLen), FrameInc);%分帧，所得矩阵为fix（（x(2:end)-FrameLen+FrameInc）/FrameInc）*FrameLen        
    end
    signs = (tmp1.*tmp2)<0;%tmp1.*tmp2所得矩阵小于等于零的赋值为1，大于零的赋值为0
    diffs = (tmp1 -tmp2)>0.02;%tmp1-tmp2所得矩阵小于0.02的赋值为0，大于等于0.02的赋值为1
    ZeroCrossRate = sum(signs.*diffs, 2);
end
