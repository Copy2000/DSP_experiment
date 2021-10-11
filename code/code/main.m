clc;clear all;close all;

cd .\voicebox
addpath(genpath('..\voicebox'))
cd ..
%%
%参数设置
singer_index = '杨';
feature_dim = 100;
WinType = 'hamming';  %窗口类型 rectangle hanning hamming
timeWinLen = 30;  %10~30ms
timeMoveLen = 10;
energyUB = 20;%初始短时能量高门限
energyLB = 10;%初始短时能量低门限
zcrUB = 10;%初始短时过零率高门限
zcrLB = 5;%初始短时过零率低门限
maxsilence = 8;  % 8*10ms  = 80ms
%语音段中允许的最大静音长度，如果语音段中的静音帧数未超过此值，则认为语音还没结束；如果超过了
%该值，则对语音段长度count进行判断，若count<minlen，则认为前面的语音段为噪音，舍弃，跳到静音
%状态0；若count>minlen，则认为语音段结束；
minlen  = 15;    % 15*10ms = 150ms

%%
%存储结果
result_feature = [];  %记录每个语音特征向量，通过补0使得长度相同
result_label = [];  %语音信号对应的数字
result_len = [];  %语音信号长度
feature_path = ['../data/feature_', WinType, '_', singer_index, '.txt'];
label_path = ['../data/label_', WinType, '_', singer_index, '.txt'];
len_path = ['../data/len_', WinType, '_', singer_index, '.txt'];
energy_path = ['../data/energy_', WinType, '_', singer_index, '.txt'];
zcr_path = ['../data/zcr_', WinType, '_', singer_index, '.txt'];
amp_path = ['../data/amp_', WinType, '_', singer_index, '.txt'];
file_feature = fopen(feature_path, 'w'); 
file_label = fopen(label_path, 'w'); 
file_len = fopen(len_path, 'w'); 
file_energy = fopen(energy_path, 'w');
file_zcr = fopen(zcr_path, 'w');
file_amp = fopen(amp_path, 'w');
%%
%双端点检测
for i = 0:9
    for j = 0:9
        filename = "../data/音频总-杨志勇/"+string(i)+string(j);
        filename = char(filename+".wav")
        [x, fs] = audioread(filename);
        wave_data = (x(:,1)+x(:,2))/2;
        wave_data = wave_data/max(abs(wave_data)); 
        maxlen = length(wave_data);
        FrameLen = round(fs*timeWinLen/(1000));%帧长
        FrameInc = round(fs*timeMoveLen/(1000));%帧移   
        ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType);
        energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType);
        amp = CalAmp(wave_data, FrameLen, FrameInc, WinType);
        [wave_start, wave_end] = EndPointDetect(ZeroCrossRate, energy, energyUB, energyLB, zcrUB, zcrLB, maxsilence, minlen);
%         coff = mfcc(wave_data(wave_start*FrameInc:wave_end*FrameInc,:), fs);
        PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
        sound(wave_data(wave_start*FrameInc:wave_end*FrameInc,:), fs)
%         pause(0.1) 


        %处理音频
        [feature, ZeroCrossRate, energy, amp] = Process(wave_data(wave_start*FrameInc:wave_end*FrameInc), feature_dim, WinType);
        
        %写入文件
        fprintf(file_feature , '%f ', feature');
        fprintf(file_feature, '\n');
        fprintf(file_label , '%d ', i);
        fprintf(file_label, '\n');
        fprintf(file_energy , '%f ', energy');
        fprintf(file_energy, '\n');
        fprintf(file_zcr, '%f ', ZeroCrossRate');
        fprintf(file_zcr, '\n');
        fprintf(file_amp, '%f ', amp');
        fprintf(file_amp, '\n');
%         %写入文件
%         curlen = wave_end*FrameInc-wave_start*FrameInc+1;
%         temp = zeros(1, maxlen);
%         temp(1:curlen) = wave_data(wave_start*FrameInc:wave_end*FrameInc);
%         result_feature = [result_feature;temp];
%         result_label = [result_label;i];  %语音信号对应的数字
%         result_len = [result_len;curlen];  %语音信号长度
%         fprintf(file_feature , '%f ', temp);
%         fprintf(file_feature, '\n');
%         fprintf(file_label , '%d ', i);
%         fprintf(file_label, '\n');
%         fprintf(file_len, '%d', curlen);
%         fprintf(file_len, '\n');
    end
end

fclose(file_feature);
fclose(file_label);
fclose(file_len);
fclose(file_energy);
fclose(file_zcr);
%%

function [feature, ZeroCrossRate, energy, amp] = Process(wave_data, feature_dim, WinType)
    data_len = length(wave_data);
    FrameLen = floor(data_len/(feature_dim+1));
    FrameInc = floor(data_len/(feature_dim+1));
    ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType);
    energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType);
    amp = CalAmp(wave_data, FrameLen, FrameInc, WinType);
    ZeroCrossRate = ZeroCrossRate(1:100);
    energy = energy(1:100);
    amp = amp(1:100);
    feature = [ZeroCrossRate' energy' amp'];
%     if strcmp(WinType ,'hanning') == 1
%         feature = mean((enframe(wave_data, hanning(FrameLen), FrameInc)), 2);
%     elseif strcmp(WinType ,'hamming') == 1
%         feature = mean((enframe(wave_data, hamming(FrameLen), FrameInc)), 2);
%     else
%         feature = mean((enframe(wave_data, FrameLen, FrameInc)), 2);     
%     end    
%     feature = feature(1:feature_dim);
end

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

function amp = CalAmp(wave_data, FrameLen, FrameInc, WinType)
    if strcmp(WinType ,'hanning') == 1
        amp = sum(abs(enframe(wave_data, hanning(FrameLen), FrameInc)), 2);
    elseif strcmp(WinType, 'hamming') == 1
        amp = sum(abs(enframe(wave_data, hamming(FrameLen), FrameInc)), 2);
    else
        amp = sum(abs(enframe(wave_data, FrameLen, FrameInc)), 2);     
    end

end

function energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType)
    if strcmp(WinType ,'hanning') == 1
        energy = sum(abs(enframe(wave_data, hanning(FrameLen), FrameInc)).^2, 2);
    elseif strcmp(WinType, 'hamming') == 1
        energy = sum(abs(enframe(wave_data, hamming(FrameLen), FrameInc)).^2, 2);
    else
        energy = sum(abs(enframe(wave_data, FrameLen, FrameInc)).^2, 2);     
    end

end

function PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
    subplot(3, 1, 1)
    plot(wave_data)
    line([wave_start*FrameInc, wave_start*FrameInc], [-1, 1], 'Color', 'red')
    line([wave_end*FrameInc, wave_end*FrameInc], [-1, 1], 'Color', 'red')
    ylabel 'Sound'
%     axis([1, length(wave_data), 0, max(wave_data)])
    subplot(3, 1, 2)
    plot(energy)
    line([wave_start, wave_start], [0, max(energy)], 'Color', 'red')
    line([wave_end, wave_end], [0, max(energy)], 'Color', 'red')
    ylabel 'Energy'
%     axis([1, length(wave_data), 0, max(wave_data)])
    subplot(3, 1, 3)
    plot(ZeroCrossRate)
    line([wave_start, wave_start], [min(ZeroCrossRate), max(ZeroCrossRate)], 'Color', 'red')
    line([wave_end, wave_end], [min(ZeroCrossRate), max(ZeroCrossRate)], 'Color', 'red')
    ylabel 'ZeroCrossRate'
end