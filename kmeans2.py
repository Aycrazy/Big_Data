import multiprocessing as mp
import pandas as pd
import numpy as np
from multiprocessing import Process, Pool
import math
import time
import sys


#Python Version 3.6.3

def initialize_centroid(data, ks):
    '''
    Setm random seed.
    Initialize centroids using list comprehension

    '''

    np.random.seed(10)

    muks = {idx+1:data[k] for idx,k in enumerate(np.random.randint(0,data.shape[0],4))}

    return muks

def best_norm(row, muks):
    r = [0,np.inf]
    for k, muk in muks.items():
        d = np.linalg.norm(row-muk)
        if d < r[1]:
            r = [k,d]
    return r[0]

def calculate_distance(ds, muks):
    '''

    Calculate distances from muks to given row of data
        return centroid assignment

    ds = data subset
    muks = meank dictionary of centroid label and the coordinates   
    
    '''

    return np.array([best_norm(row,muks) for row in ds])

    

    
def process_distance(data, muks,cpus):
    ''' 

    Paralellize the distance calculation process
    return an array of muk(centroid) assignments for each row

    data = full data set
    muks = dictionary of centroid label and coordinates
    cpus = number of cpus

    '''

    data_splits = np.array_split(data, cpus)
    with mp.Pool(processes = cpus) as pool:
        result = [pool.apply(calculate_distance,(ds, muks,)) for ds in data_splits] 
    return np.array([item for sublist in result for item in sublist])



def move_centroids(data,ks,muk_assns):
    '''

    Take muk assignments and average the value of each column to move the centroid

    '''

    return {k:get_avg_features(data[muk_assns==k]) for k in range(1,ks+1)}

def get_avg_features(data):
    '''

    Parallelize finding the mean for each column given the rows assigned
    to the provided centroid

    '''


    return np.apply_along_axis(np.mean,0,data)


cmf = pd.read_csv('cmf.csv', index_col='Unnamed: 0')
cmf_array = np.array(cmf)


def main(ks, cpus):
    '''

    Run parallelized kmeans

    '''


    c = 0

    while c < 10**4:

        if c:     

            muk_assns = process_distance(cmf_array,muks,cpus)

            temp = muks

            muks = move_centroids(cmf_array, ks, muk_assns)

            norms = [np.linalg.norm(temp[k]-muks[k]) for k in range(1,ks+1)]

            if any(.01 < n for n in norms):

                continue
            else:

                return muk_assns,muks

        else:

            muks = initialize_centroid(cmf_array,ks)

            muk_assns = process_distance(cmf_array,muks,cpus)

        c+=1
        
        
    return muk_assns,muks


if __name__ == '__main__':


    main( int(sys.argv[1]), int(sys.argv[2]))


