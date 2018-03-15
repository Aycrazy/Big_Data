#!/bin/bash

echo python kmeans.py 1 1
time -p python kmeans.py 1 1


echo python kmeans.py 1 2
time -p python kmeans.py 1 2 

echo python kmeans.py 1 3
time -p python kmeans.py 1 3

echo python kmeans.py 1 4
time -p python kmeans.py 1 4 

echo python kmeans.py 2 1
time -p python kmeans.py 2 1 

echo python kmeans.py 2 2
time -p python kmeans.py 2 2 

echo python kmeans.py 2 3
time -p python kmeans.py 2 3 

echo python kmeans.py 2 4
time -p python kmeans.py 2 4 
