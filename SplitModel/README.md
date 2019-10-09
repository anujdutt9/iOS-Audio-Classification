# Split Model

***This folder contains the code to split the CoreML audio classification Model into two models in order to run it on targets less than iOS 13. The current model has more than 100 layers and hence requires iOS13 as a pre-requisite to run. But splitting the model allows us to use the two models in series to make the prediction on audio in targets less than iOS 13.***
