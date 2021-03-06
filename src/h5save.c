#include <stdlib.h>
#include "h5save.h"

int create_file(char * name){
    hid_t file_id;
    file_id = H5Fcreate(name, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    return 0;
}

int create_new_dataset(H5block *d){
    hid_t file_id, dataset_id, dataspace_id, status, dcpl, datatype;
    file_id = H5Fopen(d->name, H5F_ACC_RDWR, H5P_DEFAULT);
    hsize_t dims[2];
    dims[0] = d->x_index_dim;
    dims[1] = d->y_index_dim;
    dataspace_id = H5Screate_simple(2, dims, NULL);
    datatype = H5Tcopy(H5T_NATIVE_FLOAT);
     status = H5Tset_order(datatype, H5T_ORDER_LE);
    char buffer[50];
    sprintf(buffer, "/dset%ld", d->ticks);

    dataset_id = H5Dcreate(file_id, buffer, datatype, dataspace_id, H5P_DEFAULT);
    status = H5Dwrite(dataset_id, H5T_NATIVE_FLOAT, H5S_ALL, H5S_ALL, H5P_DEFAULT,
                        d->field);
    status = H5Dclose(dataset_id);
    status = H5Tclose(datatype);
    status = H5Sclose(dataspace_id);
    status = H5Fclose(file_id);
}
    


int test_hdf5(){
    char filename[] = "temp";
    int i, j;
    int ticks = 1;
    int xdim = 1024;
    int ydim = 1024;
    float * data = (float *) malloc(sizeof(float) * xdim * ydim);
    for(i = 0; i < xdim; i++)
        for(j=0; j< ydim; j++){
            data[j * xdim + i] = i * j * 0.7;
        }

    H5block d;
    d.name = "temp";
    d.x_index_dim = 1024;
    d.y_index_dim = 1024;
    d.field = data;
    d.ticks = 1;
    create_file(d.name);
    create_new_dataset(&d);
}

/*int main(){*/
    /*test_hdf5();*/
/*}*/
