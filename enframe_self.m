%信号分帧
function f=enframe_self(data,win,inc)
%win为帧长，inc为帧移
nx = length(data(:));
nwin=length(win);
if(nwin==1)
    len = win;
else
    len=nwin;
end
if(nargin<3)
    inc=len;
end
nf=fix((nx-len+inc)/inc);
f=zeros(nf,len);
indf=inc*(0:(nf-1)).';
inds=(1:len);
f(:)=data(indf(:,ones(1,len))+inds(ones(nf,1),:));
if (nwin>1)
    w=win(:)';
    f=f.*w(ones(nf,1),:);
end