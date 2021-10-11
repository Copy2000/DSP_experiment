clc;clear all;close all;

cd .\voicebox
addpath(genpath('..\voicebox'))
cd ..
%%
%��������
singer_index = '��';
feature_dim = 100;
WinType = 'hamming';  %�������� rectangle hanning hamming
timeWinLen = 30;  %10~30ms
timeMoveLen = 10;
energyUB = 20;%��ʼ��ʱ����������
energyLB = 10;%��ʼ��ʱ����������
zcrUB = 10;%��ʼ��ʱ�����ʸ�����
zcrLB = 5;%��ʼ��ʱ�����ʵ�����
maxsilence = 8;  % 8*10ms  = 80ms
%���������������������ȣ�����������еľ���֡��δ������ֵ������Ϊ������û���������������
%��ֵ����������γ���count�����жϣ���count<minlen������Ϊǰ���������Ϊ��������������������
%״̬0����count>minlen������Ϊ�����ν�����
minlen  = 15;    % 15*10ms = 150ms

%%
%�洢���
result_feature = [];  %��¼ÿ����������������ͨ����0ʹ�ó�����ͬ
result_label = [];  %�����źŶ�Ӧ������
result_len = [];  %�����źų���
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
%˫�˵���
for i = 0:9
    for j = 0:9
        filename = "../data/��Ƶ��-��־��/"+string(i)+string(j);
        filename = char(filename+".wav")
        [x, fs] = audioread(filename);
        wave_data = (x(:,1)+x(:,2))/2;
        wave_data = wave_data/max(abs(wave_data)); 
        maxlen = length(wave_data);
        FrameLen = round(fs*timeWinLen/(1000));%֡��
        FrameInc = round(fs*timeMoveLen/(1000));%֡��   
        ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType);
        energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType);
        amp = CalAmp(wave_data, FrameLen, FrameInc, WinType);
        [wave_start, wave_end] = EndPointDetect(ZeroCrossRate, energy, energyUB, energyLB, zcrUB, zcrLB, maxsilence, minlen);
%         coff = mfcc(wave_data(wave_start*FrameInc:wave_end*FrameInc,:), fs);
        PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
        sound(wave_data(wave_start*FrameInc:wave_end*FrameInc,:), fs)
%         pause(0.1) 


        %������Ƶ
        [feature, ZeroCrossRate, energy, amp] = Process(wave_data(wave_start*FrameInc:wave_end*FrameInc), feature_dim, WinType);
        
        %д���ļ�
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
%         %д���ļ�
%         curlen = wave_end*FrameInc-wave_start*FrameInc+1;
%         temp = zeros(1, maxlen);
%         temp(1:curlen) = wave_data(wave_start*FrameInc:wave_end*FrameInc);
%         result_feature = [result_feature;temp];
%         result_label = [result_label;i];  %�����źŶ�Ӧ������
%         result_len = [result_len;curlen];  %�����źų���
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
    %�����ε���̳��ȣ��������γ���С�ڴ�ֵ������Ϊ��Ϊһ������
    status  = 0;     %��ʼ״̬Ϊ����״̬
    count   = 0;     %��ʼ�����γ���Ϊ0
    silence = 0;     %��ʼ�����γ���Ϊ0
    energyUB = min(energyUB, max(energy)/4);
    energyLB = min(energyLB, max(energy)/8);
    wave_start = 0;
    wave_end = 0;
    for n=1:length(ZeroCrossRate) %length��zcr���õ����������źŵ�֡��
       switch status
       case {0,1}                   % 0 = ����, 1 = ���ܿ�ʼ
          if energy(n) > energyUB          % ȷ�Ž���������
             wave_start = max(n-count-1,1);
             status  = 2;
             silence = 0;
             count   = count + 1;
          elseif energy(n) > energyLB || ZeroCrossRate(n) > zcrLB % ���ܴ���������       
             status = 1;
             count  = count + 1;
          else                       % ����״̬
             status  = 0;
             count   = 0;
          end
       case 2                       % 2 = ������
          if energy(n) > energyLB || ...     % ������������
             ZeroCrossRate(n) > zcrLB
             count = count + 1;
          else                       % ����������
             silence = silence+1;
             if silence < maxsilence % ����������������δ����
                count  = count + 1;
             elseif count < minlen   % ��������̫�̣���Ϊ������
                status  = 0;
                silence = 0;
                count   = 0;
             else                    % ��������
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
        tmp1  = enframe(wave_data(1:end-1), hanning(FrameLen), FrameInc);%��֡�����þ���Ϊfix����x(1:end-1)-FrameLen+FrameInc��/FrameInc��*FrameLen
        tmp2  = enframe(wave_data(2:end)  , hanning(FrameLen), FrameInc);%��֡�����þ���Ϊfix����x(2:end)-FrameLen+FrameInc��/FrameInc��*FrameLen
    elseif strcmp(WinType , 'hamming') == 1
        tmp1  = enframe(wave_data(1:end-1), hamming(FrameLen), FrameInc);%��֡�����þ���Ϊfix����x(1:end-1)-FrameLen+FrameInc��/FrameInc��*FrameLen
        tmp2  = enframe(wave_data(2:end)  , hamming(FrameLen), FrameInc);%��֡�����þ���Ϊfix����x(2:end)-FrameLen+FrameInc��/FrameInc��*FrameLen
    else
        tmp1  = enframe(wave_data(1:end-1), (FrameLen), FrameInc);%��֡�����þ���Ϊfix����x(1:end-1)-FrameLen+FrameInc��/FrameInc��*FrameLen
        tmp2  = enframe(wave_data(2:end)  , (FrameLen), FrameInc);%��֡�����þ���Ϊfix����x(2:end)-FrameLen+FrameInc��/FrameInc��*FrameLen        
    end
    signs = (tmp1.*tmp2)<0;%tmp1.*tmp2���þ���С�ڵ�����ĸ�ֵΪ1��������ĸ�ֵΪ0
    diffs = (tmp1 -tmp2)>0.02;%tmp1-tmp2���þ���С��0.02�ĸ�ֵΪ0�����ڵ���0.02�ĸ�ֵΪ1
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