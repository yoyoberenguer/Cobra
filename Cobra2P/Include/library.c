/* C implementation */
/*
gcc -O2 -fomit-frame-pointer -o library library.c
gcc -ffast-math -O3 -fomit-frame-pointer -o library library.c
*/


#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <math.h>
#include <float.h>
#include <assert.h>
#include <time.h>

// fast round
float round_c(float x);

// Fast sqrt
float Q_inv_sqrt( float number );

// Calculate distance between two pixels (used by bilateral filters).
float distance (float x1, float y1, float x2, float y2);

// Gaussian function (used by bilateral filters).
float gaussian (float v, float sigma);

// From a given set of RGB values, determines min and max.
float fmax_rgb_value(float red, float green, float blue);
float fmin_rgb_value(float red, float green, float blue);
unsigned char max_rgb_value(unsigned char red, unsigned char green, unsigned char blue);
unsigned char min_rgb_value(unsigned char red, unsigned char green, unsigned char blue);

// Convert RGB color model into HSV and reciprocally
float * rgb_to_hsv(float r, float g, float b);
float * hsv_to_rgb(float h, float s, float v);

// Convert RGB color model into HSL and reciprocally
float hue_to_rgb(float m1, float m2, float hue);
float * rgb_to_hsl(float r, float g, float b);
float * hsl_to_rgb(float h, float s, float l);

// Quicksort algorithm
void swap(int* a, int* b);
int partition (int arr[], int low, int high);
int * quickSort(int arr[], int low, int high);


#define M_PI 3.14159265358979323846
#define ONE_SIX 1.0f/6.0f
#define ONE_THIRD 1.0f / 3.0f
#define TWO_THIRD 2.0f / 3.0f
#define ONE_255 1.0f/255.0f
#define ONE_360 1.0f/360.0f


#define cmax(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })

float round_c(float x)
{
return (float)(x + 3*4503599627370496 - 3*4503599627370496);
}

float Q_inv_sqrt( float number )
{
	long i;
	float x2, y;
	const float threehalfs = 1.5F;

	x2 = number * 0.5F;
	y  = number;
	i  = * ( long * ) &y;                       // evil floating point bit level hacking
	i  = 0x5f3759df - ( i >> 1 );               // what the fuck?
	y  = * ( float * ) &i;
	y  = y * ( threehalfs - ( x2 * y * y ) );   // 1st iteration

	return y;
}


unsigned char umax_ (unsigned char a, unsigned char b)
{
  if (a > b) {
  return a;
}
  else return b;
}


int imax_ (int a, int b)
{
  if (a > b) {
  return a;
}
  else return b;
}

float fmax_ (float a, float b)
{
  if (a > b) {
  return a;
}
  else return b;
}


float distance (float x1, float y1, float x2, float y2)
{
  return (float)sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
}

float gaussian (float v, float sigma)
{
  return (float)(1.0f / (2.0f * M_PI * (sigma * sigma))) * (float)exp(-(v * v ) / (2.0f * sigma *
  sigma));
}

inline float fmax_rgb_value(float red, float green, float blue)
{
    if (red>green){
        if (red>blue) {
		    return red;}
		else {
		    return blue;}
    }
    else if (green>blue){
	    return green;}
        else {
	        return blue;}
}


inline float fmin_rgb_value(float red, float green, float blue)
{
    if (red<green){
        if (red<blue){
            return red;}
    else{
	    return blue;}
    }
    else if (green<blue){
	    return green;}
    else{
	    return blue;}
}



inline unsigned char max_rgb_value(unsigned char red, unsigned char green, unsigned char blue)
{
    if (red>green){
        if (red>blue) {
		    return red;}
		else {
		    return blue;}
    }
    else if (green>blue){
	    return green;}
        else {
	        return blue;}
}

inline unsigned char min_rgb_value(unsigned char red, unsigned char green, unsigned char blue)
{
    if (red<green){
        if (red<blue){
            return red;}
    else{
	    return blue;}
    }
    else if (green<blue){
	    return green;}
    else{
	    return blue;}
}


// Convert RGB color model into HSV model (Hue, Saturation, Value)
// all colors inputs have to be double precision (RGB normalized values),
// (python float) in range [0.0 ... 1.0]
// outputs is a C array containing 3 values, HSV (double precision)
// to convert in % do the following:
// h = h * 360.0
// s = s * 100.0
// v = v * 100.0

inline float * rgb_to_hsv(float r, float g, float b)
{
    // check if all inputs are normalized
    assert ((0.0<=r) <= 1.0);
    assert ((0.0<=g) <= 1.0);
    assert ((0.0<=b) <= 1.0);

    float mx, mn;
    float h, df, s, v, df_;
    float *hsv = (float*) malloc (sizeof (float) * 3);
    // Check if the memory has been successfully
    // allocated by malloc or not
    if (hsv == NULL) {
        printf("Memory not allocated.\n");
        exit(0);
    }

    mx = fmax_rgb_value(r, g, b);
    mn = fmin_rgb_value(r, g, b);

    df = mx-mn;
    df_ = 1.0f/df;
    if (mx == mn)
    {
        h = 0.0f;}
    // The conversion to (int) approximate the final result
    else if (mx == r){
	    h = (float)fmod(60.0f * ((g-b) * df_) + 360.0f, 360);
	}
    else if (mx == g){
	    h = (float)fmod(60.0f * ((b-r) * df_) + 120.0f, 360);
	}
    else if (mx == b){
	    h = (float)fmod(60.0f * ((r-g) * df_) + 240.0f, 360);
    }
    if (mx == 0){
        s = 0.0f;
    }
    else{
        s = df/mx;
    }
    v = mx;
    hsv[0] = h * (float)ONE_360;
    hsv[1] = s;
    hsv[2] = v;
    return hsv;
}


inline float * hsv_to_rgb(float h, float s, float v)
{
    // check if all inputs are normalized
    assert ((0.0<= h) <= 1.0f);
    assert ((0.0<= s) <= 1.0f);
    assert ((0.0<= v) <= 1.0f);

    int i;
    float f, p, q, t;
    float *rgb = (float*) malloc (sizeof (float) * 3);
    // Check if the memory has been successfully
    // allocated by malloc or not
    if (rgb == NULL) {
        printf("Memory not allocated.\n");
        exit(0);
    }

    if (s == 0.0){
        rgb[0] = v;
        rgb[1] = v;
        rgb[2] = v;
        return rgb;
    }

    i = (int)(h*6.0f);

    f = (h*6.0f) - i;
    p = v*(1.0f - s);
    q = v*(1.0f - s*f);
    t = v*(1.0f - s*(1.0f-f));
    i = i%6;

    if (i == 0){
        rgb[0] = v;
        rgb[1] = t;
        rgb[2] = p;
        return rgb;
    }
    else if (i == 1){
        rgb[0] = q;
        rgb[1] = v;
        rgb[2] = p;
        return rgb;
    }
    else if (i == 2){
        rgb[0] = p;
        rgb[1] = v;
        rgb[2] = t;
        return rgb;
    }
    else if (i == 3){
        rgb[0] = p;
        rgb[1] = q;
        rgb[2] = v;
        return rgb;
    }
    else if (i == 4){
        rgb[0] = t;
        rgb[1] = p;
        rgb[2] = v;
        return rgb;
    }
    else if (i == 5){
        rgb[0] = v;
        rgb[1] = p;
        rgb[2] = q;
        return rgb;
    }
    return rgb;
}




inline float * rgb_to_hsl(float r, float g, float b)
{
    // check if all inputs are normalized
    assert ((0.0<= r) <= 1.0f);
    assert ((0.0<= g) <= 1.0f);
    assert ((0.0<= b) <= 1.0f);

    float *hsl = (float*) malloc (sizeof (float)* 3);
    // Check if the memory has been successfully
    // allocated by malloc or not
    if (hsl == NULL) {
        printf("Memory not allocated.\n");
        exit(0);
    }
    float cmax=0.0f, cmin=0.0f, delta=0.0f, t=0.0f;
    cmax = fmax_rgb_value(r, g, b);
    cmin = fmin_rgb_value(r, g, b);
    delta = (cmax - cmin);

    float h, l, s;
    l = (cmax + cmin) / 2.0f;

    if (delta == 0) {
    h = 0;
    s = 0;
    }
    else {
    	  if (cmax == r){
    	        t = (g - b) / delta;
    	        if (((float)fabs(t) > 6.0f) && (t > 0.0f)) {
                  t = (float)fmod(t, 6.0f);
                }
                else if (t < 0.0f){
                t = 6.0f - (float)fabs(t);
                }

	            h = 60.0f * t;
          }
    	  else if (cmax == g){
                h = 60.0f * (((b - r) / delta) + 2.0f);
          }

    	  else if (cmax == b){
    	        h = 60.0f * (((r - g) / delta) + 4.0f);
          }

    	  if (l <=0.5f) {
	            s=(delta/(cmax + cmin));
	      }
	  else {
	        s=(delta/(2.0f - cmax - cmin));
	  }
    }

    hsl[0] = h * ONE_360;
    hsl[1] = s;
    hsl[2] = l;
    // printf("\n %f, %f, %f", hsl[0], hsl[1], hsl[2]);
    return hsl;


}


inline float hue_to_rgb(float m1, float m2, float h)
{
    if (((float)fabs(h) > 1.0f) && (h > 0.0f)) {
      h = (float)fmod(h, 1.0f);
    }
    else if (h < 0.0f){
    h = 1.0f - (float)fabs(h);
    }

    if (h < ONE_SIX){
        return m1 + (m2 - m1) * h * 6.0f;
    }
    if (h < 0.5f){
        return m2;
    }
    if (h < TWO_THIRD){
        return m1 + ( m2 - m1 ) * (TWO_THIRD - h) * 6.0f;
    }
    return m1;
}


inline float * hsl_to_rgb(float h, float s, float l)
{
    float *rgb = (float*) malloc (sizeof (float ) * 3);
    // Check if the memory has been successfully
    // allocated by malloc or not
    if (rgb == NULL) {
        printf("Memory not allocated.\n");
        exit(0);
    }

    float m2=0.0f, m1=0.0f;

    if (s == 0.0){
        rgb[0] = l;
        rgb[1] = l;
        rgb[2] = l;
        return rgb;
    }
    if (l <= 0.5f){
        m2 = l * (1.0f + s);
    }
    else{
        m2 = l + s - (l * s);
    }
    m1 = 2.0f * l - m2;

    rgb[0] = hue_to_rgb(m1, m2, (h + ONE_THIRD));
    rgb[1] = hue_to_rgb(m1, m2, h);
    rgb[2] = hue_to_rgb(m1, m2, (h - ONE_THIRD));
    return rgb;
}

// A utility function to swap two elements
inline void swap(int* a, int* b)
{
	int t = *a;
	*a = *b;
	*b = t;
}

/* This function takes last element as pivot, places
the pivot element at its correct position in sorted
	array, and places all smaller (smaller than pivot)
to left of pivot and all greater elements to right
of pivot */
inline int partition (int arr[], int low, int high)
{
	int pivot = arr[high]; // pivot
	int i = (low - 1); // Index of smaller element

	for (int j = low; j <= high- 1; j++)
	{
		// If current element is smaller than the pivot
		if (arr[j] < pivot)
		{
			i++; // increment index of smaller element
			swap(&arr[i], &arr[j]);
		}
	}
	swap(&arr[i + 1], &arr[high]);
	return (i + 1);
}

/* The main function that implements QuickSort
arr[] --> Array to be sorted,
low --> Starting index,
high --> Ending index */
int * quickSort(int arr[], int low, int high)
{
	if (low < high)
	{
		/* pi is partitioning index, arr[p] is now
		at right place */
		int pi = partition(arr, low, high);

		// Separately sort elements before
		// partition and after partition
		quickSort(arr, low, pi - 1);
		quickSort(arr, pi + 1, high);
	}
return arr;
}

/* Function to print an array */
void printArray(int arr[], int size)
{
	int i;
	for (i=0; i < size; i++)
		printf("%d ", arr[i]);
	printf("n");
}


//int main(){
//double *array;
//double *arr;
//double h, l, s;
//double r, g, b;
//int i = 0, j = 0, k = 0;
//
//int n = 1000000;
//double *ptr;
//clock_t begin = clock();
//
///* here, do your time-consuming job */
//for (i=0; i<=n; ++i){
//ptr = rgb_to_hsl(25.0/255.0, 60.0/255.0, 128.0/255.0);
//}
//clock_t end = clock();
//double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
//printf("\ntotal time %f :", time_spent);
//
//printf("\nTesting algorithm(s).");
//n = 0;
//
//for (i=0; i<256; i++){
//    for (j=0; j<256; j++){
//        for (k=0; k<256; k++){
//
//            array = rgb_to_hsl(i/255.0, j/255.0, k/255.0);
//            h = array[0];
//            s = array[1];
//            l = array[2];
//            free(array);
//            arr = hsl_to_rgb(h, s, l);
//            r = round(arr[0] * 255.0);
//            g = round(arr[1] * 255.0);
//            b = round(arr[2] * 255.0);
//	        free(arr);
//            // printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
//            // printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
//            // printf("\n %f, %f, %f ", h, l, s);
//
//            if (abs(i - r) > 0.1) {
//                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
//                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
//                printf("\n %f, %f, %f ", h, l, s);
//                        n+=1;
//                return -1;
//            }
//            if (abs(j - g) > 0.1){
//                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
//                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
//                printf("\n %f, %f, %f ", h, l, s);
//                        n+=1;
//                return -1;
//            }
//
//            if (abs(k - b) > 0.1){
//                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
//                printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
//                printf("\n %f, %f, %f ", h, l, s);
//                n+=1;
//		        return -1;
//
//            }
//
//            }
//
//        }
//    }
//
//
//printf("\nError(s) found n=%i", n);
//return 0;
//}


/*
int main ()
{
float *ar;
float *ar1;
int i, j, k;
float r, g, b;
float h, s, v;

int n = 1000000;
float *ptr;
clock_t begin = clock();


for (i=0; i<=n; ++i){
float *ptr = rgb_to_hsv(25.0f/255.0f, 60.0f/255.0f, 128.0f/255.0f);
}
clock_t end = clock();
float time_spent = (float)(end - begin) / CLOCKS_PER_SEC;
printf("\ntotal time %f :", time_spent);

printf("\nTesting algorithm(s).");
n = 0;
for (i=0; i<256; i++){
    for (j=0; j<256; j++){
        for (k=0; k<256; k++){
            ar = rgb_to_hsv((float)i/255.0f, (float)j/255.0f, (float)k/255.0f);
            h=ar[0];
            s=ar[1];
            v=ar[2];
	        free(ar);
            ar1 = hsv_to_rgb(h, s, v);
            r = round(ar1[0] * 255.0f);
            g = round(ar1[1] * 255.0f);
            b = round(ar1[2] * 255.0f);
   	        free(ar1);
            // printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
            // printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
            // printf("\n %f, %f, %f ", h, s, v);

            if (abs(i - r) > 0.1) {
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, s, v);
                        n+=1;
                return -1;
            }
            if (abs(j - g) > 0.1){
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, s, v);
                        n+=1;
                return -1;
            }

            if (abs(k - b) > 0.1){
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, s, v);
                n+=1;
		        return -1;

            }
        }
    }
}
printf("\nError(s) found. %i ", n);

return 0;
}

*/