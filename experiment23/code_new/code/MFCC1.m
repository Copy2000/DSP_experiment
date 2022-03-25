clear all;
clc;
WinType = 'hamming';  %窗口类型 rectangle hanning hamming
%%
% filename = string(i)+"_"+string(k)+"_"+string(j)+"_0";
% filename="../data/processed_num_sound/"+WinType+filename+".txt"
% data=load(filename);
x=audioread('../data/num_sound/1_0_1_0.wav');
%%%%%%%%%MEL三角滤波参数%%%%%%%%%%%%%%%%%%%%%%%%%%%
fh=4000; %fs=8000Hz,fh=4000Hz    语音信号的频率一般在300-3400Hz，所以一般情况下采样频率设为8000Hz即可。
max_melf=2595*log10(1+fh/700);
M=24;%三角滤波器的个数。
N=256;%256是语音片段的长度，也是fft的点数，也是24个滤波器(0-4000Hz)总点数
i=0:25;
f=700*(10.^(max_melf/2595*i/(M+1))-1);%将mei频域中的 各滤波器的中心频率 转到实际频率
F=zeros(24,256);
for m=1:24
    for k=1:256
        i=fh*k/N;
        if (f(m)<=i)&&(i<=f(m+1))
            F(m,k)=(i-f(m))/(f(m+1)-f(m));
        else if (f(m+1)<=i)&&(i<=f(m+2))
                F(m,k)=(f(m+2)-i)/(f(m+2)-f(m+1));
            else
                F(m,k)=0;
            end
        end
    end
end
plot((1:256)*4000/256,F);
%%%%%%%%%%%%%%%DCT系数%%%%%%%%%%%
dctcoef=zeros(12,24);
for k=1:12
  n=1:24;
  dctcoef(k,:)=cos((2*n-1)*k*pi/(2*24));
end

%%%%%%%%%%%1.对语音信号进行预加重处理%%%%%%%%%%
%式中alpha的值介于0.9-1.0之间，我们通常取0.97。
%预加重的目的是提升高频部分，使信号的频谱变得平坦，保持在低频到高频的整个频带中，能用同样的信噪比求频谱。
%同时，也是为了消除发生过程中声带和嘴唇的效应，来补偿语音信号受到发音系统所抑制的高频部分，也为了突出高频的共振峰。
len=length(x);
alpha=0.97;
y=zeros(len,1);
for i=2:len
    y(i)=x(i)-alpha*x(i-1);
end
%%%%%%%%%%%%%%%MFCC特征参数的求取%%%%%%%%%%%%
%加窗
h=hamming(256);%256*1
num=N/2;
count=floor(len/num)-1;
c1=zeros(count,12);
for i=1:count
    x_frame=y(num*(i-1)+1:num*(i-1)+N);%256*1
    w = x_frame.* h;%
    Fx=abs(fft(x_frame));
    s=log(F*Fx.^2);%ln
    c1(i,:)=(dctcoef*s)';  
end

%%%%%%%%%%%%差分系数%%%%%%%%%%%
dtm = zeros(size(c1));
for i=3:size(c1,1)-2
dtm(i,:) = -2*c1(i-2,:) - c1(i-1,:) + c1(i+1,:) + 2*c1(i+2,:);
end
dtm = dtm / 3;

%%%%合并mfcc参数和一阶差分mfcc参数%%%%%
ccc = [c1 dtm];
%去除首尾两帧，因为这两帧的一阶差分参数为0
ccc = ccc(3:size(c1,1)-2,:);


