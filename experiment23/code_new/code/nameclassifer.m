clc;clear all;close all;

cd .\voicebox
addpath(genpath('..\voicebox'))
cd ..
%%
%参数设置
fs=44100;

feature_dim = 100;
WinType = 'hanning';  %窗口类型 rectangle hanning hamming
timeWinLen = 30;  %10~30ms
timeMoveLen = 10;
energyUB = 50;%初始短时能量高门限
energyLB = 10;%初始短时能量低门限
zcrUB = 10;%初始短时过零率高门限
zcrLB = 2;%初始短时过零率低门限
maxsilence = 8;  % 8*10ms  = 80ms
%语音段中允许的最大静音长度，如果语音段中的静音帧数未超过此值，则认为语音还没结束；如果超过了
%该值，则对语音段长度count进行判断，若count<minlen，则认为前面的语音段为噪音，舍弃，跳到静音
%状态0；若count>minlen，则认为语音段结束；
minlen  = 20;    % 15*10ms = 150ms
while(1)
    flag = input('do you want to start:(y/n)\n','s');
    if(flag=='n')
        break;
    end
    %% 获取音频
    recObj = audiorecorder(fs,16,1);
    disp('Start speaking.')
    recordblocking(recObj, 2);
    disp('End of Recording.');
    wave_data = getaudiodata(recObj);  %获取录音数据

    %%
    %双端点检测     
    maxlen = length(wave_data);
    FrameLen = round(fs*timeWinLen/(1000));%帧长
    FrameInc = round(fs*timeMoveLen/(1000));%帧移   
    ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType);
    energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType);
    amp = CalAmp(wave_data, FrameLen, FrameInc, WinType);
    [wave_start, wave_end] = EndPointDetect(ZeroCrossRate, energy, energyUB, energyLB, zcrUB, zcrLB, maxsilence, minlen);
    PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
    processed_data=wave_data(wave_start*FrameInc:wave_end*FrameInc,:); 
    data=processed_data;
    
    %MFCC
    m=MFCC(wave_data,WinType);
    % 名字
    num_label=load('label_name_all_mat.txt');
    num_database_length=size(num_label,1);
    ind=1;
    usernum = 5;
    numbernum = 5;
    repnum = 4;
    datapath = "../data/MFCC_feature/MFCC_name/";
    dist = zeros(1,num_database_length);
    for i = 1:usernum
        for j = 1:numbernum
            for k = 1:repnum
                datafile = datapath+"MFCC_"+WinType+string(i)+"_"+string(j)+"_"+string(k)+"_1.txt";
                feature = load(datafile); 
                dist(ind)=dtw(m',feature');
                ind = ind+1;
            end       
        end
    end
    [a,b]=min(dist);
    if num_label(b)== 1
        sprintf('识别结果：庞立')
    elseif num_label(b)== 2
        sprintf('识别结果：林逸阳')
    elseif num_label(b)== 3
        sprintf('识别结果：彭宣尧')
    elseif num_label(b)== 4
        sprintf('识别结果：龙雅琴')
    elseif num_label(b)== 5
        sprintf('识别结果：赵超')
    end
end


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