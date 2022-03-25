 clc;clear all;close all;
for i = 1:20
   
    % 录音录2秒钟
    recObj = audiorecorder(44100,16,2);
    filename = input('please input filename:\n','s');
    filename = filename+".wav"
    disp('Start speaking.')
    recordblocking(recObj,2);
    disp('End of Recording.');
    % 回放录音数据
    %play(recObj);
    % 获取录音数据
    myRecording = getaudiodata(recObj);
    % 绘制录音数据波形
    plot(myRecording);
    audiowrite(filename,myRecording,44100)
end

