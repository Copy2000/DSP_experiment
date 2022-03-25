clear all;
clc;
WinType = "retangle";  %窗口类型 rectangle(boxcar) hanning hamming
%% number
for i = 1:10
    for k=0:9
        for j = 1:2
            filename0 = string(i)+"_"+string(k)+"_"+string(j)+"_0";
            filename="../data/processed_num_sound/"+filename0+".wav"
            data=audioread(filename);
            data=0.5*(data(:,1)+data(:,2));
            m=MFCC(data,WinType);
            processed_data_filename="../data/MFCC_feature/MFCC_num/"+"MFCC_"+WinType+filename0+".txt"
            save(processed_data_filename,'m','-ascii');
        end
    end
end
%% name
% for i = 1:5
%     for k=1:5
%         for j = 1:4
%             filename0 = string(i)+"_"+string(k)+"_"+string(j)+"_1";
%             filename="../data/name_sound/"+filename0+".wav"
%             data=audioread(filename);
%             data=0.5*(data(:,1)+data(:,2));
%             m=MFCC(data,WinType);
%             processed_data_filename="../data/MFCC_feature/MFCC_name/"+"MFCC_"+WinType+filename0+".txt"
%             save(processed_data_filename,'m','-ascii');
%         end
%     end
% end