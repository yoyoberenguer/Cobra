/* C implementation */
/*
gcc -O2 -fomit-frame-pointer -o hsl_c hsl_c.c
gcc -ffast-math -O3 -fomit-frame-pointer -o hsl_c hsl_c.c
*/

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <math.h>
#include <float.h>
#include <assert.h>
#include <time.h>


struct hsl{
    float h;    // hue
    float s;    // saturation
    float l;    // value
};

struct rgb{
    float r;
    float g;
    float b;
};


struct rgba{
    float r;
    float g;
    float b;
    float a;
};

// From a given set of RGB values, determines min and max.
float fmax_rgb_value(float red, float green, float blue);
float fmin_rgb_value(float red, float green, float blue);

// METHOD 1
// Convert RGB color model into HSL and reciprocally
float hue_to_rgb(float m1, float m2, float hue);
float * rgb_to_hsl(float r, float g, float b);
float * hsl_to_rgb(float h, float s, float l);

// METHOD 2
struct hsl struct_rgb_to_hsl(float r, float g, float b);
struct rgb struct_hsl_to_rgb(float h, float s, float l);

#define ONE_SIX 1.0f/6.0f
#define ONE_THIRD 1.0f / 3.0f
#define TWO_THIRD 2.0f / 3.0f
#define ONE_255 1.0f/255.0f
#define ONE_360 1.0f/360.0f

#define cmax(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })



// All inputs have to be float precision (python float) in range [0.0 ... 255.0]
// Output: return the maximum value from given RGB values (float precision).
inline float fmax_rgb_value(float red, float green, float blue)
{
    if (red>green){
        if (red>blue) {
		    return red;
	}
		else {
		    return blue;
	    }
    }
    else if (green>blue){
	    return green;
	}
    else {
	    return blue;
	}
}

// All inputs have to be float precision (python float) in range [0.0 ... 255.0]
// Output: return the minimum value from given RGB values (float precision).
inline float fmin_rgb_value(float red, float green, float blue)
{
    if (red<green){
        if (red<blue){
            return red;
        }
    else{
	    return blue;}
    }
    else if (green<blue){
	    return green;
	}
    else{
	    return blue;
	}
}


// HSL: Hue, Saturation, Luminance
// H: position in the spectrum
// L: color lightness
// S: color saturation
// all inputs have to be float precision, (python float) in range [0.0 ... 1.0]
// outputs is a C array containing HSL values (float precision) normalized.
// h (°) = h * 360
// s (%) = s * 100
// l (%) = l * 100
inline float * rgb_to_hsl(float r, float g, float b)
{ 
    // check if all inputs are normalized
    assert ((0.0<= r) <= 1.0);
    assert ((0.0<= g) <= 1.0);
    assert ((0.0<= b) <= 1.0);

    float *hsl = (float*)malloc (sizeof (float)* 3);
    // Check if the memory has been successfully 
    // allocated by malloc or not 
    if (hsl == NULL) {
        printf("Memory not allocated.\n"); 
        exit(0); 
    } 
    float cmax=0, cmin=0, delta=0, t;
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
    	        if ((fabs(t) > 6.0) && (t > 0.0)) {
                  t = (float)fmod(t, 6.0f);
                }
                else if (t < 0.0){
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
    if ((fabs(h) > 1.0) && (h > 0.0)) {
      h = (float)fmod(h, 1.0f);
    }
    else if (h < 0.0){
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


// Convert HSL color model into RGB (red, green, blue)
// all inputs have to be float precision, (python float) in range [0.0 ... 1.0]
// outputs is a C array containing RGB values (float precision) normalized.
inline float * hsl_to_rgb(float h, float s, float l)
{
    float *rgb = (float*) malloc (sizeof (float) * 3);
    // Check if the memory has been successfully 
    // allocated by malloc or not 
    if (rgb == NULL) { 
        printf("Memory not allocated.\n"); 
        exit(0); 
    } 

    float m2=0, m1=0;

    if (s == 0.0){
        rgb[0] = l;
        rgb[1] = l;
        rgb[2] = l;
        return rgb;
    }
    if (l <= 0.5){
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




// HSL: Hue, Saturation, Luminance
// H: position in the spectrum
// L: color lightness
// S: color saturation
// all inputs have to be float precision, (python float) in range [0.0 ... 1.0]
// outputs is a C array containing HSL values (float precision) normalized.
// h (°) = h * 360
// s (%) = s * 100
// l (%) = l * 100
inline struct hsl struct_rgb_to_hsl(float r, float g, float b)
{
    // check if all inputs are normalized
    assert ((0.0<= r) <= 1.0f);
    assert ((0.0<= g) <= 1.0f);
    assert ((0.0<= b) <= 1.0f);

    // struct hsl hsl_={.h=0.0, .s=0.0, .l=0.0};  C only
    struct hsl hsl_={0.0f, 0.0f, 0.0f};
    float cmax=0.0f, cmin=0.0f, delta=0.0f, t;

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
    	        if ((fabs(t) > 6.0) && (t > 0.0)) {
                  t = (float)fmod(t, 6.0f);
                }
                else if (t < 0.0){
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

    	  if (l <=0.5) {
	            s=(delta/(cmax + cmin));
	      }
	  else {
	        s=(delta/(2.0f - cmax - cmin));
	  }
    }

    hsl_.h = h * ONE_360;
    hsl_.s = s;
    hsl_.l = l;
    return hsl_;
}


// Convert HSL color model into RGB (red, green, blue)
// all inputs have to be float precision, (python float) in range [0.0 ... 1.0]
// outputs is a C array containing RGB values (float precision) normalized.
inline struct rgb struct_hsl_to_rgb(float h, float s, float l)
{

    // struct rgb rgb_={.r=0.0, .g=0.0, .b=0.0}; only C
    struct rgb rgb_={0.0f, 0.0f, 0.0f};

    float m2=0.0f, m1=0.0f;

    if (s == 0.0){
        rgb_.r = l;
        rgb_.g = l;
        rgb_.b = l;
        return rgb_;
    }
    if (l <= 0.5){
        m2 = l * (1.0f + s);
    }
    else{
        m2 = l + s - (l * s);
    }
    m1 = 2.0f * l - m2;

    rgb_.r = hue_to_rgb(m1, m2, (h + ONE_THIRD));
    rgb_.g = hue_to_rgb(m1, m2, h);
    rgb_.b = hue_to_rgb(m1, m2, (h - ONE_THIRD));
    return rgb_;
}


int main(){
float *array;
float *arr;
float h, l, s;
float r, g, b;
int i = 0, j = 0, k = 0;

int n = 1000000;
float *ptr;
clock_t begin = clock();

/* here, do your time-consuming job */
for (i=0; i<=n; ++i){
ptr = rgb_to_hsl(25.0/255.0, 60.0/255.0, 128.0/255.0);
}
clock_t end = clock();
float time_spent = (float)(end - begin) / CLOCKS_PER_SEC;
printf("\ntotal time %f :", time_spent);

printf("\nTesting algorithm(s).");
n = 0;

for (i=0; i<256; i++){
    for (j=0; j<256; j++){
        for (k=0; k<256; k++){

            array = rgb_to_hsl(i/255.0f, j/255.0f, k/255.0f);
            h = array[0];
            s = array[1];
            l = array[2];
            free(array);
            arr = hsl_to_rgb(h, s, l);
            r = (float)round(arr[0] * 255.0f);
            g = (float)round(arr[1] * 255.0f);
            b = (float)round(arr[2] * 255.0f);
	        free(arr);
            // printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
            // printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
            // printf("\n %f, %f, %f ", h, l, s);

            if (fabs(i - r) > 0.1) {
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, l, s);
                        n+=1;
                return -1;
            }
            if (fabs(j - g) > 0.1){
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, l, s);
                        n+=1;
                return -1;
            }

            if (fabs(k - b) > 0.1){
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, l, s);
                n+=1;
		        return -1;

            }

            }

        }
    }


printf("\nError(s) found n=%i", n);
return 0;
}

