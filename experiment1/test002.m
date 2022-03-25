%此文件是test001执行一次的函数
clc
clear all;
filename="E12.wav";
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