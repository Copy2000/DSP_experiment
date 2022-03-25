# README

# 1.文件说明![image-20211114005243045](C:\Users\A\AppData\Roaming\Typora\typora-user-images\image-20211114005243045.png)

* 1._processed_name.m_和_processed_num.m_文件是处理raw materials，目的是将2s的音频文件中没有语音的地方剔除（即使用双端检测处理音频），但是想到实验二好像并不需要考虑这个，所以并没有用到这两个文件中生成的文件，若要用到，可在data目录下的processed** 文件中找到。

  ![image-20211114005821018](C:\Users\A\AppData\Roaming\Typora\typora-user-images\image-20211114005821018.png)

* _MFCC1.m_为失败品，不需要理会。

* _MFCC.m_为获得MFCC特征向量的函数，需要在_get_MFCC.m_中使用。

  # 2.MFCC

  MFCC为合并mfcc参数和一阶差分mfcc参数的一个24列矩阵，前面12列为mfcc参数，后面12列为一阶差分mfcc参数。