clc
clear all
load trainedClassifyer
load featurehamming2
res=zeros(20,2);
for i=1:20
    b=ceil(rand(1)*10)
    while b==0
        b=ceil(rand(1)*10);
    end
    res(i,1)=ceil(b/2-1);
    a=featurehamming2(b,:);
    yfit = trainedClassifier.predictFcn(a)
    res(i,2)=yfit;
end