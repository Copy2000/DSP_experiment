function ccc = MFCC(x,WinType)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 function ccc=mfcc(x);
%对输入的语音序列x进行MFCC参数的提取，返回MFCC参数和一阶
%差分MFCC参数，Mel滤波器的阶数为24
%fft变换的长度为256，采样频率为8000Hz，对x 256点分为一帧
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bank=melbankm(24,256,8000,0,0.5,'m');%24:滤波器个数  256: length of fft  8000:采样频率
%size(bank);%24*129   为什么不是24*256？？
% 归一化mel滤波器组系数
bank=full(bank);
bank=bank/max(bank(:));
tem=(0:floor(256/2))*8000/256;
% figure(1)
% plot(tem,bank)   %fs=sample frequency

% DCT系数,12*24
for k=1:12
  n=0:23;
  dctcoef(k,:)=cos((2*n+1)*k*pi/(2*24));
end


% 归一化倒谱提升窗口
w = 1 + 6 * sin(pi * [1:12] ./ 12);
w = w/max(w);

% 预加重滤波器
xx=double(x);
xx=filter([1 -0.9375],1,xx);%y(n)=x(n)-0.9375x(n-1);

% 语音信号分帧
xx=enframe(xx,256,80);

% 计算每帧的MFCC参数
frame_num=size(xx,1);%size(xx,1)返回xx的行数  249*256
if WinType=="hanning"
    h=hanning(256);
elseif WinType=="rectangle"
    h=boxcar(256);
elseif WinType=="hamming"
    h=hamming(256);
end
for i=1:frame_num
  y = xx(i,:); 
  s = y'.* h;%乘窗  x.*y是对应位置的元素相乘  例如：A=[1 2; 3 4];B=A;A.*B=[1*1 2*2;3*3 4*4]=[1 4;9 16]而A*B=[1*1+2*3,1*2+2*4;3*1+4*3,3*2+4*4]=[7 10;15 22]
  t = abs(fft(s));
%   figure(3)
%   stem(t,'.')
  t = t.^2;      %计算能量%功率谱
  mel=log(bank * t(1:129));
  c1=dctcoef * mel;%这里选择的帧长为256点，然后FFT的点数也为256，由于是对称的，所以只取前面一半的点计算频谱。然后加入到三角滤波器中。
  c2 = c1.*w'; % w为归一化倒谱提升窗口
  m(i,:)=c2';
end

%差分系数
dtm = zeros(size(m));
for i=3:size(m,1)-2
  dtm(i,:) = -2*m(i-2,:) - m(i-1,:) + m(i+1,:) + 2*m(i+2,:);
end
dtm = dtm / 3;

%合并mfcc参数和一阶差分mfcc参数
ccc = [m dtm];
%去除首尾两帧，因为这两帧的一阶差分参数为0
ccc = ccc(3:size(m,1)-2,:);
