#include "cuda.h"
#include "cpu_anim.h"
#include "helper_cuda.h"
#include "helper_functions.h"
#include "h5save.h"
#include<stdio.h>
#include<pthread.h>
#include "datablock.h"
#include "kernels.cuh"
#include "constants.h"
#include <thrust/fill.h>
#include<algorithm>
#include "tm_mode.h"
#include "pml_mode.h"

void anim_gpu(Datablock *d, int ticks){
    if(d->simulationType == TM_SIMULATION)
        anim_gpu_tm(d, ticks);
    else if(d->simulationType == TM_PML_SIMULATION)
        anim_gpu_pml_tm(d, ticks);
}

void anim_exit(Datablock *d){
    if(d->simulationType == TM_SIMULATION)
        clear_memory_TM_simulation(d);
    else if(d->simulationType == TM_PML_SIMULATION)
        clear_memory_TM_PML_simulation(d);

}

void allocate_memory(Datablock *data, Structure structure){
    if(data->simulationType == TM_SIMULATION)
        allocateTMMemory(data, structure);
    else if(data->simulationType == TM_PML_SIMULATION)
        tm_pml_allocate_memory(data, structure);
}

void initializeArrays(Datablock *data, Structure structure){
    if(data->simulationType == TM_SIMULATION)
        initialize_TM_arrays(data, structure);
    else if(data->simulationType == TM_PML_SIMULATION)
        tm_pml_initialize_arrays(data, structure);
}

void clear_memory_constants(Datablock *data){
    if(data->simulationType == TM_SIMULATION)
        tm_clear_memory_constants(data);
    else if(data->simulationType == TM_PML_SIMULATION)
        tm_pml_clear_memory_constants(data);

}


int main(){
    Datablock data(TM_PML_SIMULATION);
    float dt= 0.5;

// FIXME: check the courant factor for the max epsilon.

    float courant = 0.5;
    float dx =  (dt * LIGHTSPEED) / courant;
    Structure structure(1024, 1024, dx, dt);
    copy_symbols(&structure);


    CPUAnimBitmap bitmap(structure.x_index_dim, structure.x_index_dim,
                            &data);

    data.bitmap = &bitmap;
    data.totalTime = 0;
    data.frames = 0;
    data.structure = &structure;
    checkCudaErrors(cudaEventCreate(&data.start, 1) );
    checkCudaErrors(cudaEventCreate(&data.stop, 1) );

    allocate_memory(&data, structure);
    initializeArrays(&data, structure);


//  get the coefficients

    dim3 blocks((structure.x_index_dim + BLOCKSIZE_X - 1) / BLOCKSIZE_X,
                (structure.y_index_dim + BLOCKSIZE_Y - 1) / BLOCKSIZE_Y);
    dim3 threads(BLOCKSIZE_X, BLOCKSIZE_Y);

    pml_tm_get_coefs<<<blocks, threads>>>(data.constants[MUINDEX],
                                     data.constants[EPSINDEX],
                                     data.constants[SIGMAINDEX_X],
                                     data.constants[SIGMAINDEX_Y],
                                     data.constants[SIGMA_STAR_INDEX_X],
                                     data.constants[SIGMA_STAR_INDEX_Y],
                                     data.coefs[0],
                                     data.coefs[1],
                                     data.coefs[2],
                                     data.coefs[3],
                                     data.coefs[4],
                                     data.coefs[5],
                                     data.coefs[6],
                                     data.coefs[7]);
clear_memory_constants(&data);


// set the sources
    HostSources host_sources;
    DeviceSources device_sources;
    host_sources.add_source(512, 512, SINUSOID_SOURCE, 0.05, 1);

    data.sources = &device_sources;
    copy_sources_device_to_host(&host_sources, &device_sources);

    bitmap.anim_and_exit( (void (*)(void *, int)) anim_gpu,
                            (void (*)(void *)) anim_exit);
}
