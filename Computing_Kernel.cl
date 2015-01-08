#include "Settings_and_Parameters.h"

////////////////////////////////////////////////////////////////////////////////
// Laplacation operator definition, to calculate diffusive fluxes
////////////////////////////////////////////////////////////////////////////////

float LaplacianXY(__global float* pop, int row, int column)
{
	float retval;
	int current, left, right, top, bottom;
	float dx = dX;
	float dy = dY;
	
	current=row * Grid_Width + column;
	left=row * Grid_Width + column-1;
	right=row * Grid_Width + column+1;
	top=(row-1) * Grid_Width + column;
	bottom=(row+1) * Grid_Width + column;
    
	retval = ( (( pop[current] - pop[left] )/dx )
		      -(( pop[right]   - pop[current] )/dx )) / dx +
             ( (( pop[current] - pop[top] )/dy  )
              -(( pop[bottom]  - pop[current] )/dy ) ) / dy;
    
	return retval;
}

////////////////////////////////////////////////////////////////////////////////
// Gradient operator definition, to calculate advective fluxes
////////////////////////////////////////////////////////////////////////////////


float GradientY(__global float* pop, int row, int column)
{
	float retval;
	int current, top;
	float dy = dY;
	
	current=row * Grid_Width + column;
	top=(row-1) * Grid_Width + column;
	
	retval =  (( pop[current] - pop[top] )/dy );
    
	return retval;
}

////////////////////////////////////////////////////////////////////////////////
// Simulation kernel
////////////////////////////////////////////////////////////////////////////////

__kernel void AridLandsKernel (__global float* P, __global float* W, __global float* O)
{
    
	float d2Pdxy2, d2Wdxy2, d2Odxy2;
	float drP, drW, drO;
    
    size_t current = get_global_id(0);
	
	int row		= floor((float)current/(float)Grid_Width);
	int column	= current%Grid_Width;  // The modulo of current and Width_Grid
	
	if(row > 0 && row < Grid_Height-1 && column > 0 && column < Grid_Width-1)
    {
		//Now calculating terms for the O Matrix
		d2Odxy2 = -DifO * LaplacianXY(O, row, column) - AdvO * GradientY(O, row, column);
		drO = (R-alpha*(P[current]+k2*W0)/(P[current]+k2)*O[current]);
        
		//Now calculating terms for the W Matrix
		d2Wdxy2 = -DifW * LaplacianXY(W, row, column);
		drW = (alpha*(P[current]+k2*W0)/(P[current]+k2)*O[current]
               - gmax*W[current]/(W[current]+k1)*P[current]-rw*W[current]);
        
		//Now calculating terms for the P Matrix
		d2Pdxy2 = -DifP * LaplacianXY(P, row, column);
		drP = (cc*gmax*W[current]/(W[current]+k1)*P[current] - dd*P[current]);
        
        //barrier(CLK_LOCAL_MEM_FENCE);
        
		O[current]=O[current]+(drO+d2Odxy2)*dT;
		W[current]=W[current]+(drW+d2Wdxy2)*dT;
		P[current]=P[current]+(drP+d2Pdxy2)*dT;
        
    }
    
    //barrier(CLK_LOCAL_MEM_FENCE);
    
	// Handle Boundaries
	if(row==0)
    {
        W[row * Grid_Width + column]=W[(Grid_Height-2) * Grid_Width+column];
        O[row * Grid_Width + column]=O[(Grid_Height-2) * Grid_Width+column];
        P[row * Grid_Width + column]=P[(Grid_Height-2) * Grid_Width+column];
    }
	else if(row==Grid_Height-1)
    {
        W[row * Grid_Width + column]=W[1*Grid_Width+column];
        O[row * Grid_Width + column]=O[1*Grid_Width+column];
        P[row * Grid_Width + column]=P[1*Grid_Width+column];
    }
	else if(column==0)
    {
        W[row * Grid_Width + column]=W[row * Grid_Width + Grid_Width-2];
        O[row * Grid_Width + column]=O[row * Grid_Width + Grid_Width-2];
        P[row * Grid_Width + column]=P[row * Grid_Width + Grid_Width-2];
    }
	else if(column==Grid_Width-1)
    {
        W[row * Grid_Width + column]=W[row * Grid_Width + 1];
        O[row * Grid_Width + column]=O[row * Grid_Width + 1];
        P[row * Grid_Width + column]=P[row * Grid_Width + 1];
    }	
	
} // End Aridlandskernel

