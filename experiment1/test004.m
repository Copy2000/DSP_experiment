%此函数是为了得到每次分帧的矩阵
clc
clear all;
FrameLen = 240;%帧长为240点
FrameInc = 80;%帧移为80点
filename="E12.wav";
[audio,fs]=audioread(filename);
%%
%分帧（未加窗）
data=(audio(:,1)+audio(:,2))/2;
figure(1)
plot(data)
a = enframe_self(data, FrameLen, FrameInc)
[x1,x2]=vad(data)
x1=x1*80;
x2=x2*80;
data=data(x1:x2,1);
figure(2)
plot(data)
%%
filename="test"+filename;