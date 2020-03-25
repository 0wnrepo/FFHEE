#include<params.hpp>
#include"FFTinit.cuh"
#include"coroutines.cuh"
#include"TwistFFT.cuh"
#include"TwistIFFT.cuh"

namespace SPCULIOS{
    template<uint32_t N = TFHEpp::DEF_N>
    __device__ inline void MulInFD(double* res, const double* a, const double* b){
        const unsigned int tid = threadIdx.x;
        const unsigned int bdim = blockDim.x;

        for (int i = tid; i < N / 2; i+=bdim) {
            const double aimbim = a[i + N / 2] * b[i + N / 2];
            const double arebim = a[i] * b[i + N / 2];
            res[i] = a[i] * b[i] - aimbim;
            res[i + N / 2] = a[i + N / 2] * b[i] + arebim;
        }
        __syncthreads();
    }

    __global__ void PolyMullvl1(uint32_t* res, const uint32_t* a,
                            const uint32_t* b)
    {
        __shared__ double buff[2][TFHEpp::DEF_N];
        TwistIFFTlvl1(buff[0], a);
        TwistIFFTlvl1(buff[1], b);
        MulInFD<TFHEpp::DEF_N>(buff[0], buff[0], buff[1]);
        TwistFFTlvl1(res, buff[0]);
    }
}