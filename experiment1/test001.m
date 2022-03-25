%此函数是为了多次分帧加窗获得预处理后的wav文件
clc
clear all
for i=0:9
%%
    for j=1:2
        %获取数据信息
        filename="E"+i+j+".wav";
        [audio,fs]=audioread(filename);
        %%
        %分帧（未加窗）
        data=(audio(:,1)+audio(:,2))/2;
        figure(1)
        plot(data)
        [x1,x2]=vad(data)
        x1=x1*80;
        x2=x2*80;
        data=data(x1:x2,1);
        figure(2)
        plot(data)
        %%
        filename="test"+filename;
        audiowrite(filename,data,44100)
    end
end