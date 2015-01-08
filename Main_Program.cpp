//
//  Main_Program.cpp
//
//  Created by Johan Van de Koppel on 03-09-14.
//  Copyright (c) 2014 Johan Van de Koppel. All rights reserved.
//

#include <stdio.h>
#include <sys/time.h>
#include <iostream>

#include "Settings_and_Parameters.h"
#include "Device_Utilities.h"

#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#define MAX_SOURCE_SIZE (0x100000)

// Forward definitions from functions at the end of this code file
void randomInit(float*, int, int, int);

////////////////////////////////////////////////////////////////////////////////
// Main program code for Aridlands
////////////////////////////////////////////////////////////////////////////////

int main()
{
    
    /*----------Constant and variable definition------------------------------*/
    
	unsigned int Grid_Memory = sizeof(float) * Grid_Size;
	unsigned int size_storegrid = Grid_Width * Grid_Height * MAX_STORE;
	unsigned int mem_size_storegrid = sizeof(float) * size_storegrid;
    
    /*----------Defining and allocating memeory on host-----------------------*/
    
    // Defining and allocating the memory blocks for P, W, and O on the host (h)
	float * h_P = (float *)malloc(Grid_Width*Grid_Height*sizeof(float));
	float * h_W = (float *)malloc(Grid_Width*Grid_Height*sizeof(float));
	float * h_O = (float *)malloc(Grid_Width*Grid_Height*sizeof(float));
    
    // Defining and allocating storage blocks for P, W, and O on the host (h)
    float * h_store_popP=(float*) malloc(mem_size_storegrid);
	float * h_store_popO=(float*) malloc(mem_size_storegrid);
	float * h_store_popW=(float*) malloc(mem_size_storegrid);
    
    /*----------Initializing the host arrays----------------------------------*/
    
	randomInit(h_P, Grid_Width, Grid_Height, Plants);
	randomInit(h_O, Grid_Width, Grid_Height, Surface_Water);
	randomInit(h_W, Grid_Width, Grid_Height, Soil_Water);
    
    /*----------Printing info to the screen ----------------------------------*/

	//system("clear");
    printf("\n");
	printf(" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n");
	printf(" * Arid Land Patterns                                    * \n");
	printf(" * OpenCL implementation : Johan van de Koppel, 2014     * \n");
	printf(" * Following a model by Rietkerk et al 2002              * \n");
	printf(" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n\n");
    
	printf(" Current grid dimensions: %d x %d cells\n\n",
           Grid_Width, Grid_Height);
    
    /*----------Setting up the device ----------------------------------------*/

    cl_device_id* devices;
    cl_int err;
    
    cl_context context = CreateGPUcontext(devices);
    
    // Print the name of the device that is used
    printf(" Implementing PDE on device %d: ", Device_No);
    print_device_info(devices, (int)Device_No);
    printf("\n");
    
    // Create a command queue on the device
    cl_command_queue command_queue = clCreateCommandQueue(context, devices[Device_No], 0, &err);
    
    /*----------Create Buffer Objects for P, W, and O on the device-----------*/
    cl_mem  d_P = clCreateBuffer(context, CL_MEM_READ_WRITE, Grid_Memory, NULL, &err);
    cl_mem  d_W = clCreateBuffer(context, CL_MEM_READ_WRITE, Grid_Memory, NULL, &err);
    cl_mem  d_O = clCreateBuffer(context, CL_MEM_READ_WRITE, Grid_Memory, NULL, &err);
    
	/* Copy input data to the memory buffer */
	err = clEnqueueWriteBuffer(command_queue, d_P, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_P, 0, NULL, NULL);
	err = clEnqueueWriteBuffer(command_queue, d_W, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_W, 0, NULL, NULL);
	err = clEnqueueWriteBuffer(command_queue, d_O, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_O, 0, NULL, NULL);
    
    /*----------Building the PDE kernel---------------------------------------*/
    
    cl_program program = BuildKernelFile("Computing_Kernel.cl", context, &devices[Device_No], &err);
    if (err!=0)  printf(" > Compile Program Error number: %d \n\n", err);
    
    /* Create OpenCL kernel */
    cl_kernel kernel = clCreateKernel(program, "AridLandsKernel", &err);
    if (err!=0) printf(" > Create Kernel Error number: %d \n\n", err);
   
	/* Set OpenCL kernel bindings */
	err = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&d_P);
	err = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&d_W);
	err = clSetKernelArg(kernel, 2, sizeof(cl_mem), (void *)&d_O);
    
    /*----------Pre-simulation settings---------------------------------------*/
    
    /* create and start timer */
    struct timeval Time_Measured;
    gettimeofday(&Time_Measured, NULL);
    double Time_Begin=Time_Measured.tv_sec+(Time_Measured.tv_usec/1000000.0);

    /* Progress bar initiation */
    int RealBarWidth=std::min((int)NumFrames,(int)ProgressBarWidth);
    int BarCounter=0;
    float BarThresholds[RealBarWidth];
    for (int i=0;i<RealBarWidth;i++) {BarThresholds[i] = (float)(i+1)/RealBarWidth*NumFrames;};
    
    /* Print the reference bar */
    printf(" Progress: [");
    for (int i=0;i<RealBarWidth;i++) { printf("-"); }
    printf("]\n");
    fprintf(stderr, "           >");
    
    /*----------Kernel parameterization---------------------------------------*/
    
	size_t global_item_size = Grid_Width*Grid_Height;
	size_t local_item_size = Block_Number_X*Block_Number_Y;
    
    /*----------Calculation loop----------------------------------------------*/
    for (int Counter=0;Counter<NumFrames;Counter++)
    {
        for (int Runtime=0;Runtime<(int)EndTime/NumFrames/dT;Runtime++)
        {
            /* Execute OpenCL kernel as data parallel */
            err = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL,
                                     &global_item_size, &local_item_size, 0, NULL, NULL);
        }
        
        /* Transfer result to host */
        err  = clEnqueueReadBuffer(command_queue, d_P, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_P, 0, NULL, NULL);
        err |= clEnqueueReadBuffer(command_queue, d_W, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_W, 0, NULL, NULL);
        err |= clEnqueueReadBuffer(command_queue, d_O, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_O, 0, NULL, NULL);

        if (err!=0) printf("Read Buffer Error: %d\n\n", err);
        
        //Store values at this frame.
        memcpy(h_store_popP+(Counter*Grid_Size),h_P,Grid_Memory);
        memcpy(h_store_popO+(Counter*Grid_Size),h_O,Grid_Memory);
        memcpy(h_store_popW+(Counter*Grid_Size),h_W,Grid_Memory);
        
        // Progress the progress bar if time
        if ((float)(Counter+1)>=BarThresholds[BarCounter]) {
            fprintf(stderr,"*");
            BarCounter = BarCounter+1;}
        
    }
    
    printf("<\n\n");
    
    /*----------Report on time spending---------------------------------------*/
    
    gettimeofday(&Time_Measured, NULL);
    double Time_End=Time_Measured.tv_sec+(Time_Measured.tv_usec/1000000.0);
	printf(" Processing time: %4.5f (s) \n", Time_End-Time_Begin);
    
    /*----------Write to file now---------------------------------------------*/
    
    // The location of the code is obtain from the __FILE__ macro
    const std::string SourceFullPath (__FILE__);
    const std::string PathName = SourceFullPath.substr (0,SourceFullPath.find_last_of("/")+1);
    const std::string DataPath = PathName + "AridLands.dat";
    
    FILE * fp=fopen(DataPath.c_str(),"wb");

    int width_matrix = Grid_Width;
    int height_matrix = Grid_Height;
    int NumStored = NumFrames;
    int EndTimeVal = EndTime;

	// Storing parameters
	fwrite(&width_matrix,sizeof(int),1,fp);
	fwrite(&height_matrix,sizeof(int),1,fp);
	fwrite(&NumStored,sizeof(int),1,fp);
	fwrite(&EndTimeVal,sizeof(int),1,fp);
	
	for(int store_i=0;store_i<NumFrames;store_i++)
    {
		fwrite(&h_store_popP[store_i*Grid_Size],sizeof(float),Grid_Size,fp);
		fwrite(&h_store_popO[store_i*Grid_Size],sizeof(float),Grid_Size,fp);
		fwrite(&h_store_popW[store_i*Grid_Size],sizeof(float),Grid_Size,fp);
    }
	
	printf("\r Simulation results saved! \n\n");
    
	fclose(fp);
    
	/*----------Clean up memory-----------------------------------------------*/
	
    // Freeing host space
    free(h_P);
	free(h_O);
	free(h_W);
    
	free(h_store_popP);
	free(h_store_popO);
	free(h_store_popW);
 
	// Freeing kernel and block space
	err = clFlush(command_queue);
	err = clFinish(command_queue);
	err = clReleaseKernel(kernel);
	err = clReleaseProgram(program);
	err = clReleaseMemObject(d_P);
	err = clReleaseMemObject(d_W);
	err = clReleaseMemObject(d_O);
	err = clReleaseCommandQueue(command_queue);
	err = clReleaseContext(context);
    free(devices);
    
    #if defined(__APPLE__) && defined(__MACH__)
        system("say Simulation finished");
    #endif

	//return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Allocates a matrix with random float entries
////////////////////////////////////////////////////////////////////////////////

void randomInit(float* data, int x_siz, int y_siz, int type)
{
	int i,j;
	for(i=0;i<y_siz;i++)
	{
		for(j=0;j<x_siz;j++)
		{
			//for every element find the correct initial
			//value using the conditions below
			if(i==0||i==y_siz-1||j==0||j==x_siz-1)
                data[i*x_siz+j]=0.0f; // This value for the boundaries
			else
			{
				if(type==Plants)
                    
				{
                    // A randomized initiation here
					if((rand() / (float)RAND_MAX)<0.05f)
                        data[i*x_siz+j] = 100.0f;
                    else
                        data[i*x_siz+j] = 0.0f;
				}
				else if(type==Surface_Water)
                    data[i*x_siz+j]=(float)(R/(alpha*W0));
				else if(type==Soil_Water)
                    data[i*x_siz+j]=(float)(R/rw/4);
			}
		}
	}
    
} // End randomInit
