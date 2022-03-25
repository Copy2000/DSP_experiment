clear all
clc
WinType = "hamming";  %窗口类型 rectangle(boxcar) hanning hamming
%% number
% for i = 1:10
%     for k=0:9
%         for j = 1:2
%             filename0 = string(i)+"_"+string(k)+"_"+string(j)+"_0";
%             filename="../data/processed_num_sound/"+WinType+filename0+".txt"
%             data=load(filename);
%             y=fft(data);
%             plot(abs(y))
%             grid on
%         end
%     end
% end
%% processed_name
for i = 1:5
    for k=5:5
        for j = 1:4
            filename0 = string(i)+"_"+string(k)+"_"+string(j)+"_1";
            filename="../data/processed_name_sound/"+WinType+filename0+".txt"
            data=load(filename);
            y=fft(data);
            plot(abs(y))
            grid on
        end
    end
end