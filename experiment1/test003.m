%次函数是为了得到预处理后20个wav的data
clc
clear all;
k=1;
for i =0:9
    for j=1:2
        filename="testE"+i+j+".wav";
        [audio,Fs] = audioread(filename);
        data{k}=audio;
        k=k+1;
    end
end


