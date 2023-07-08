#cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, optimize.use_switch=True

cdef extern from 'Include/hsl_c.c' nogil:
    float * rgb_to_hsl(float r, float g, float b);
    float * hsl_to_rgb(float h, float s, float l);


# C-structure to store 3d array index values
cdef struct xyz:
    int x;
    int y;
    int z;

cdef saturation_buffer_mask_c(unsigned char [:] buffer_,
                              float shift_, float [:, :] mask_array)

cdef saturation_array24_mask_c(unsigned char [:, :, :] array_,
                               float shift_, unsigned char [:, :] mask_array, bint swap_row_column)

cdef saturation_array32_mask_c(unsigned char [:, :, :] array_, unsigned char [:, :] alpha_,
                               float shift_, float [:, :] mask_array=*, bint swap_row_column=*)

cdef saturation_array24_c(unsigned char [:, :, :] array_, float shift_, bint swap_row_column)

cdef saturation_array32_c(unsigned char [:, :, :] array_,
                          unsigned char [:, :] alpha_, float shift_, bint swap_row_column)

