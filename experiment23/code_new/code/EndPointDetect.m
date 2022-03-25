function [wave_start, wave_end] = EndPointDetect(ZeroCrossRate, energy, energyUB, energyLB, zcrUB, zcrLB, maxsilence, minlen)
    %语音段的最短长度，若语音段长度小于此值，则认为其为一段噪音
    status  = 0;     %初始状态为静音状态
    count   = 0;     %初始语音段长度为0
    silence = 0;     %初始静音段长度为0
    energyUB = min(energyUB, max(energy)/4);
    energyLB = min(energyLB, max(energy)/8);
    wave_start = 0;
    wave_end = 0;
    for n=1:length(ZeroCrossRate) %length（zcr）得到的是整个信号的帧数
       switch status
       case {0,1}                   % 0 = 静音, 1 = 可能开始
          if energy(n) > energyUB          % 确信进入语音段
             wave_start = max(n-count-1,1);
             status  = 2;
             silence = 0;
             count   = count + 1;
          elseif energy(n) > energyLB || ZeroCrossRate(n) > zcrLB % 可能处于语音段       
             status = 1;
             count  = count + 1;
          else                       % 静音状态
             status  = 0;
             count   = 0;
          end
       case 2                       % 2 = 语音段
          if energy(n) > energyLB || ...     % 保持在语音段
             ZeroCrossRate(n) > zcrLB
             count = count + 1;
          else                       % 语音将结束
             silence = silence+1;
             if silence < maxsilence % 静音还不够长，尚未结束
                count  = count + 1;
             elseif count < minlen   % 语音长度太短，认为是噪声
                status  = 0;
                silence = 0;
                count   = 0;
             else                    % 语音结束
                status  = 3;
             end
          end
       case 3
          break;
       end
    end  
    count = count-silence/2;
    wave_end = wave_start + count -1;
end

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