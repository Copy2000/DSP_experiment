function varargout = DSP(varargin)
% DSP MATLAB code for DSP.fig
%      DSP, by itself, creates a new DSP or raises the existing
%      singleton*.
%
%      H = DSP returns the handle to a new DSP or the handle to
%      the existing singleton*.
%
%      DSP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DSP.M with the given input arguments.
%
%      DSP('Property','Value',...) creates a new DSP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DSP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DSP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DSP

% Last Modified by GUIDE v2.5 12-Dec-2021 15:46:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DSP_OpeningFcn, ...
                   'gui_OutputFcn',  @DSP_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DSP is made visible.
function DSP_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DSP (see VARARGIN)

% Choose default command line output for DSP
handles.output = hObject;
ha=axes('units','normalized','position',[0 0 1 1]);
uistack(ha,'down')
II=imread('xjtu.jpg');
image(II)
colormap gray
set(ha,'handlevisibility','off','visible','off');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DSP wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DSP_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
handles.output = hObject;
ha=axes('units','normalized','position',[0 0 1 1]);
uistack(ha,'down')
II=imread('xjtu.jpg');
image(II)
colormap gray
set(ha,'handlevisibility','off','visible','off');

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cd .\voicebox
addpath(genpath('..\voicebox'))
cd ..
%%
%参数设置
fs=44100;
WinType = 'hanning';  %窗口类型 rectangle hanning hamming
timeWinLen = 30;  %10~30ms
timeMoveLen = 10;
energyUB = 50;%初始短时能量高门限
energyLB = 10;%初始短时能量低门限
zcrUB = 10;%初始短时过零率高门限
zcrLB = 2;%初始短时过零率低门限
maxsilence = 8;  % 8*10ms  = 80ms
%语音段中允许的最大静音长度，如果语音段中的静音帧数未超过此值，则认为语音还没结束；如果超过了
%该值，则对语音段长度count进行判断，若count<minlen，则认为前面的语音段为噪音，舍弃，跳到静音
%状态0；若count>minlen，则认为语音段结束；
minlen  = 20;    % 15*10ms = 150ms

    %% 获取音频
    recObj = audiorecorder(fs,16,1);
    set(handles.edit1,'String', 'Start speaking.');
    recordblocking(recObj, 2);
    
    set(handles.edit1,'String', 'End of Recording.');
    wave_data = getaudiodata(recObj);  %获取录音数据
    %%
    %双端点检测     
    maxlen = length(wave_data);
    FrameLen = round(fs*timeWinLen/(1000));%帧长
    FrameInc = round(fs*timeMoveLen/(1000));%帧移   
    ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType);
    energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType);
    amp = CalAmp(wave_data, FrameLen, FrameInc, WinType);
    [wave_start, wave_end] = EndPointDetect(ZeroCrossRate, energy, energyUB, energyLB, zcrUB, zcrLB, maxsilence, minlen);
    PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
%     plot(handles.axes1,wave_data)
%     line([wave_start*FrameInc, wave_start*FrameInc], [-1, 1], 'Color', 'red')
%     line([wave_end*FrameInc, wave_end*FrameInc], [-1, 1], 'Color', 'red')
%     ylabel(handles.axes1,'Sound')
    processed_data=wave_data(wave_start*FrameInc:wave_end*FrameInc,:); 
    data=processed_data;
    %MFCC
    m=MFCC(data,WinType);
    % 数字
    num_label=load('label_num_all_mat.txt');
    num_database_length=size(num_label,1);
    ind=1;
    usernum = 10;
    numbernum = 10;
    repnum = 2;
    datapath = "../data/MFCC_feature/MFCC_processed_num/";
    dist = zeros(1,num_database_length);
    for i = 1:usernum
        for j = 0:numbernum-1
            for k = 1:repnum
                datafile = datapath+"MFCC_Processed_"+WinType+string(i)+"_"+string(j)+"_"+string(k)+"_0.txt";
                feature = load(datafile); 
                dist(ind)=dtw(m',feature');
                ind = ind+1;
            end       
        end
    end
    [a,b]=min(dist);
    sprintf('识别结果：%d',num_label(b))
    text_=['语音识别结果为：',num2str(num_label(b))]
    set(handles.edit1,'String',text_);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cd .\voicebox
addpath(genpath('..\voicebox'))
cd ..
%%
%参数设置
fs=44100;

WinType = 'hanning';  %窗口类型 rectangle hanning hamming
timeWinLen = 30;  %10~30ms
timeMoveLen = 10;
energyUB = 50;%初始短时能量高门限
energyLB = 10;%初始短时能量低门限
zcrUB = 10;%初始短时过零率高门限
zcrLB = 2;%初始短时过零率低门限
maxsilence = 8;  % 8*10ms  = 80ms
%语音段中允许的最大静音长度，如果语音段中的静音帧数未超过此值，则认为语音还没结束；如果超过了
%该值，则对语音段长度count进行判断，若count<minlen，则认为前面的语音段为噪音，舍弃，跳到静音
%状态0；若count>minlen，则认为语音段结束；
minlen  = 20;    % 15*10ms = 150ms
    %% 获取音频
    recObj = audiorecorder(fs,16,1);
    set(handles.edit1,'String', 'Start speaking.');
    recordblocking(recObj, 2);
    set(handles.edit1,'String', 'End of Recording.');
    wave_data = getaudiodata(recObj);  %获取录音数据

    %%
    %双端点检测
    energyUB = 50;%初始短时能量高门限
    energyLB = 30;%初始短时能量低门限
    zcrUB = 10;%初始短时过零率高门限
    zcrLB = 5;%初始短时过零率低门限
    maxsilence = 30;  % 8*10ms  = 80ms  4:50
    %语音段中允许的最大静音长度，如果语音段中的静音帧数未超过此值，则认为语音还没结束；如果超过了
    %该值，则对语音段长度count进行判断，若count<minlen，则认为前面的语音段为噪音，舍弃，跳到静音
    %状态0；若count>minlen，则认为语音段结束；
    minlen  = 5;    % 15*10ms = 150ms
    maxlen = length(wave_data);
    FrameLen = round(fs*timeWinLen/(1000));%帧长
    FrameInc = round(fs*timeMoveLen/(1000));%帧移   
    ZeroCrossRate = CalZeroCrossingRate(wave_data, FrameLen, FrameInc, WinType);
    energy = CalEnergy(wave_data, FrameLen, FrameInc, WinType);
    amp = CalAmp(wave_data, FrameLen, FrameInc, WinType);
    [wave_start, wave_end] = EndPointDetect(ZeroCrossRate, energy, energyUB, energyLB, zcrUB, zcrLB, maxsilence, minlen);
    PlotWave(wave_data, energy, ZeroCrossRate, wave_start, wave_end, FrameInc)
    processed_data=wave_data(wave_start*FrameInc:wave_end*FrameInc,:); 
    data=processed_data;
    
    %MFCC
    m=MFCC(wave_data,WinType);
    % 名字
    num_label=load('label_name_all_mat.txt');
    num_database_length=size(num_label,1);
    ind=1;
    usernum = 5;
    numbernum = 5;
    repnum = 4;
    datapath = "../data/MFCC_feature/MFCC_name/";
    dist = zeros(1,num_database_length);
    for i = 1:usernum
        for j = 1:numbernum
            for k = 1:repnum
                datafile = datapath+"MFCC_"+WinType+string(i)+"_"+string(j)+"_"+string(k)+"_1.txt";
                feature = load(datafile); 
                dist(ind)=dtw(m',feature');
                ind = ind+1;
            end       
        end
    end
    [a,b]=min(dist);
    if num_label(b)== 1
        set(handles.edit1,'String','识别结果：庞立');
    elseif num_label(b)== 2
        set(handles.edit1,'String','识别结果：林逸阳');
    elseif num_label(b)== 3
        set(handles.edit1,'String','识别结果：彭宣尧');
    elseif num_label(b)== 4
        set(handles.edit1,'String','识别结果：龙雅琴');
    elseif num_label(b)== 5
        set(handles.edit1,'String','识别结果：赵超');
    end


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
handles.output = hObject;
ha=axes('units','normalized','position',[0 0 1 1]);
uistack(ha,'down')
II=imread('xjtu.jpg');
image(II)
colormap gray
set(ha,'handlevisibility','off','visible','off');
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); 
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles.output = hObject;
ha=axes('units','normalized','position',[0 0 1 1]);
uistack(ha,'down')
II=imread('xjtu.jpg');
image(II)
colormap gray
set(ha,'handlevisibility','off','visible','off');
