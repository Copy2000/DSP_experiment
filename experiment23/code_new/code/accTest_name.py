import matplotlib.pyplot as plt
import numpy as np
import matplotlib
import sklearn.model_selection as ms
from sklearn.metrics import mean_squared_error,accuracy_score
import torch
a=[]
for i in range(100):
    torch.manual_seed(i)
    test_size = 0.05
    dis = np.loadtxt('distance_name_all_mat.txt')
    label = np.loadtxt('label_name_all_mat.txt')
    test_num = int(test_size*len(dis))
    # test_index = np.random.randint(0, len(dis), test_num)
    test_index = torch.randperm(len(dis))[:test_num].numpy()
    test_dis = dis[test_index, :]
    test_index = test_index.tolist()
    dataset_index = np.arange(0, len(dis)).tolist()
    dataset_index = np.array([t for t in dataset_index if t not in test_index])
    test_dis = test_dis[:, dataset_index]

    test_true_label = label[test_index]
    dataset_label = label[dataset_index]

    sortind = np.argsort(test_dis, axis=1)
    test_label_hat = []
    for i in range(test_num):
        nnind = dataset_label[sortind[i,:]]
        test_label_hat.append(nnind[0])
    test_label_hat = np.array(test_label_hat)

    print(accuracy_score(test_true_label, test_label_hat))
    a.append(accuracy_score(test_true_label, test_label_hat))
plt.plot(a)
plt.show()
