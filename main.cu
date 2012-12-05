#include <stdio.h>
#include <stdlib.h>
#include "sha1_.cu"
#include <string.h>

#define N 8
#define SPACE 10000
#define BLOCK_SIZE 16   





__global__ void kernel(unsigned char* digest, unsigned char* find, bool* bingo) {

	// keep the context in shared memory
	__shared__ unsigned char ctx[16][16][N];

	// keep the digest in the shared memory, too
	//__shared__ unsigned char target[20];
	
	// the digest we calculate 
	__shared__ unsigned char result[16][16][20];
	
	// 00 - 99
	int high = blockIdx.x * blockDim.x + threadIdx.x; if (high >= 10000) return;
	// 00- 99 
	int low  = blockIdx.y * blockDim.y + threadIdx.y; if (low >= 10000) return;
	
	/*
	// only one thread of a block has the responsibility to dump the digest
	if (threadIdx.x==0 && threadIdx.y==0) {
		for (int i=0; i<20; i++)
			target[i] = digest[i];
	}
	__syncthreads(); // !!
	*/

	// generate and assign context
	ctx[threadIdx.x][threadIdx.y][0] = (unsigned char)(high /1000 + 48);
	ctx[threadIdx.x][threadIdx.y][1] = (unsigned char)((high % 1000) / 100 + 48);
	ctx[threadIdx.x][threadIdx.y][2] = (unsigned char)((high % 100) / 10 + 48);
	ctx[threadIdx.x][threadIdx.y][3] = (unsigned char)(high % 10 + 48);
	ctx[threadIdx.x][threadIdx.y][4] = (unsigned char)(low/1000 + 48);
	ctx[threadIdx.x][threadIdx.y][5] = (unsigned char)((low % 1000) / 100 + 48);
	ctx[threadIdx.x][threadIdx.y][6] = (unsigned char)((low % 100) / 10 + 48);
	ctx[threadIdx.x][threadIdx.y][7] = (unsigned char)((low % 10 + 48));
	
	// sha1
	sha1(result[threadIdx.x][threadIdx.y], ctx[threadIdx.x][threadIdx.y], N);
	
	// compare the result to the digest 
	int flag = 1;
	for (int i=0; i<20; i++) {
		if (result[threadIdx.x][threadIdx.y][i] != digest[i]) {
			flag = 0;
			break;
		}
	}


	//find !!
	if (flag==1) {
		find[0] = ctx[threadIdx.x][threadIdx.y][0];
		find[1] = ctx[threadIdx.x][threadIdx.y][1];
		find[2] = ctx[threadIdx.x][threadIdx.y][2];
		find[3] = ctx[threadIdx.x][threadIdx.y][3];
		find[4] = ctx[threadIdx.x][threadIdx.y][4];
		find[5] = ctx[threadIdx.x][threadIdx.y][5];
		find[6] = ctx[threadIdx.x][threadIdx.y][6];
		find[7] = ctx[threadIdx.x][threadIdx.y][7];
		*bingo = true;
	}
}


int main(int argc, char** argv) {
    

	cudaEvent_t start, stop;
	float elapsedTime;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	if (argc <1) {
		printf("wrong arguments\n");
		return -1;
	}


	// readin
    char* input = argv[1];


	unsigned char cypher[20];
    
	for (int i=0; i<20;i++) {
        unsigned char high = input[2*i];
        unsigned char low = input[2*i+1];
		unsigned char combine;
        switch(high) {
case '1': combine = 0x10; break;
case '2': combine = 0x20; break;
case '3': combine = 0x30; break;
case '4': combine = 0x40; break;		  
case '5': combine = 0x50; break;
case '6': combine = 0x60; break;
case '7': combine = 0x70; break;
case '8': combine = 0x80; break;
case '9': combine = 0x90; break;
case 'a': combine = 0xa0; break;
case 'b': combine = 0xb0; break;
case 'c': combine = 0xc0; break;
case 'd': combine = 0xd0; break;
case 'e': combine = 0xe0; break;
case 'f': combine = 0xf0; break;
default: combine = 0x00;
		}
		switch(low) {
case '1': combine |= 0x01; break;
case '2': combine |= 0x02; break;
case '3': combine |= 0x03; break;
case '4': combine |= 0x04; break;		  
case '5': combine |= 0x05; break;
case '6': combine |= 0x06; break;
case '7': combine |= 0x07; break;
case '8': combine |= 0x08; break;
case '9': combine |= 0x09; break;
case 'a': combine |= 0x0a; break;
case 'b': combine |= 0x0b; break;
case 'c': combine |= 0x0c; break;
case 'd': combine |= 0x0d; break;
case 'e': combine |= 0x0e; break;
case 'f': combine |= 0x0f; break;
default: combine |= 0x00;
		}
		cypher[i] = combine;
    }

	printf("\ncypher:");
	for (int i=0; i<20; i++) {
		printf("%x", cypher[i]);
	}
	printf("\n");


	// cypher has been prepared
    unsigned char *digest, *digest_d, *find_d, *find;
	
	digest = cypher;

	dim3 blocksPerGrid((10000+15)/16, (10000+15)/16);
	dim3 threadsPerBlock(16, 16);

	// digest
	cudaMalloc((void**) &digest_d, sizeof(unsigned char)*20);
	cudaMemcpy(digest_d, digest, sizeof(unsigned char)*20, cudaMemcpyHostToDevice);

	// find output
	cudaMalloc((void**) &find_d, sizeof(unsigned char)*N);
	find = (unsigned char*) malloc(sizeof(unsigned char)*N);

	// bingo
	bool *bingo, *bingo_d;
	bingo = (bool *) malloc(sizeof(bool));
	*bingo = false;
	cudaMalloc((void**) &bingo_d, sizeof(bool));
	cudaMemcpy(bingo_d, bingo, sizeof(bool), cudaMemcpyHostToDevice);
	

	cudaEventRecord(start, 0);
	kernel<<<blocksPerGrid, threadsPerBlock>>>(digest_d, find_d, bingo_d);
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsedTime, start, stop);

	// get the output
	cudaMemcpy(find, find_d, sizeof(unsigned char)*N, cudaMemcpyDeviceToHost);
	cudaMemcpy(bingo, bingo_d, sizeof(bool), cudaMemcpyDeviceToHost);

	if (*bingo==true) {
		printf("\nbingo!\n");

		printf("\nplain:");
		for (int i=0; i<N; i++)
			printf("%c", find[i]);
	} else {
		printf("not found!");
	}
	printf("\ntime:%f\n", elapsedTime);
	

	cudaFree(find_d);
	cudaFree(digest_d);
	cudaFree(bingo_d);
	free(find);
	free(bingo);
	return 0;
}
