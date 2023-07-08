/* C implementation */
/*
gcc -O2 -fomit-frame-pointer -o hsl_c hsv_c.c
gcc -ffast-math -O3 -fomit-frame-pointer -o hsv_c hsv_c.c
*/

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <math.h>
#include <float.h>
#include <assert.h>
#include <time.h>


// From a given set of RGB values, determines min and max values.
float fmax_rgb_value(float red, float green, float blue);
float fmin_rgb_value(float red, float green, float blue);

// Convert RGB color model into HSV and reciprocally
// METHOD 1
float * rgb_to_hsv(float r, float g, float b);
float * hsv_to_rgb(float h, float s, float v);

// METHOD 2
struct rgb struct_hsv_to_rgb(float h, float s, float v);
struct hsv struct_rgb_to_hsv(float r, float g, float b);


#define ONE_255 1.0f/255.0f
#define ONE_360 1.0f/360.0f

#define cmax(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })


struct hsv{
    float h;    // hue
    float s;    // saturation
    float v;    // value
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
	        return blue;
	    }
    }
    else if (green<blue){
	    return green;
	}
    else{
	    return blue;
	    }
}



// Convert RGB color model into HSV model (Hue, Saturation, Value)
// all colors inputs have to be float precision (RGB normalized values),
// (python float) in range [0.0 ... 1.0]
// outputs is a C array containing 3 values, HSV (float precision)
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
    float *hsv = (float*)malloc (sizeof (float) * 3);
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
        h = 0.0;}
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
    hsv[0] = h * ONE_360;
    hsv[1] = s;
    hsv[2] = v;
    return hsv;
}

// Convert HSV color model into RGB (red, green, blue)
// all inputs have to be float precision, (python float) in range [0.0 ... 1.0]
// outputs is a C array containing RGB values (float precision) normalized.
// to convert for a pixel colors
// r = r * 255.0
// g = g * 255.0
// b = b * 255.0

inline float * hsv_to_rgb(float h, float s, float v)
{
    // check if all inputs are normalized
    assert ((0.0<= h) <= 1.0);
    assert ((0.0<= s) <= 1.0);
    assert ((0.0<= v) <= 1.0);

    int i;
    float f, p, q, t;
    float *rgb = (float*)malloc (sizeof (float) * 3);
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

/*
METHOD 2
Return a structure instead of pointers
// outputs is a C structure containing 3 values, HSV (float precision)
// to convert in % do the following:
// h = h * 360.0
// s = s * 100.0
// v = v * 100.0
*/
inline struct hsv struct_rgb_to_hsv(float r, float g, float b)
{
    // check if all inputs are normalized
    assert ((0.0<=r) <= 1.0);
    assert ((0.0<=g) <= 1.0);
    assert ((0.0<=b) <= 1.0);

    float mx, mn;
    float h, df, s, v, df_;
    struct hsv hsv_;

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
    hsv_.h = h * ONE_360;
    hsv_.s = s;
    hsv_.v = v;
    return hsv_;
}

// Convert HSV color model into RGB (red, green, blue)
// all inputs have to be float precision, (python float) in range [0.0 ... 1.0]
// outputs is a C structure containing RGB values (float precision) normalized.
// to convert for a pixel colors
// r = r * 255.0
// g = g * 255.0
// b = b * 255.0

inline struct rgb struct_hsv_to_rgb(float h, float s, float v)
{
    // check if all inputs are normalized
    assert ((0.0<= h) <= 1.0);
    assert ((0.0<= s) <= 1.0);
    assert ((0.0<= v) <= 1.0);

    int i;
    float f, p, q, t;
    //struct rgb rgb_={.r=0.0, .g=0.0, .b=0.0};
    struct rgb rgb_={0.0f, 0.0f, 0.0f};

    if (s == 0.0){
        rgb_.r = v;
        rgb_.g = v;
        rgb_.b = v;
        return rgb_;
    }

    i = (int)(h*6.0f);

    f = (h*6.0f) - i;
    p = v*(1.0f - s);
    q = v*(1.0f - s*f);
    t = v*(1.0f - s*(1.0f-f));
    i = i%6;

    if (i == 0){
        rgb_.r = v;
        rgb_.g = t;
        rgb_.b = p;
        return rgb_;
    }
    else if (i == 1){
        rgb_.r = q;
        rgb_.g = v;
        rgb_.b = p;
        return rgb_;
    }
    else if (i == 2){
        rgb_.r = p;
        rgb_.g = v;
        rgb_.b = t;
        return rgb_;
    }
    else if (i == 3){
        rgb_.r = p;
        rgb_.g = q;
        rgb_.b = v;
        return rgb_;
    }
    else if (i == 4){
        rgb_.r = t;
        rgb_.g = p;
        rgb_.b = v;
        return rgb_;
    }
    else if (i == 5){
        rgb_.r = v;
        rgb_.g = p;
        rgb_.b = q;
        return rgb_;
    }
    return rgb_;
}




int main ()
{
float *ar;
float *ar1;
int i, j, k;
float r, g, b;
float h, s, v;

int n = 1000000;
//float *ptr;
clock_t begin = clock();
//struct hsv hsv_;
//struct rgb rgb_;
//
///* here, do your time-consuming job */
//for (i=0; i<=n; ++i){
//    ptr = rgb_to_hsv(25.0/255.0, 60.0/255.0, 128.0/255.0);
//    printf("\nHSV1 : %f %f %f ", ptr[0], ptr[1], ptr[2]);
//    hsv_ = struct_rgb_to_hsv(25.0/255.0, 60.0/255.0, 128.0/255.0);
//    printf("\nHSV2 : %f %f %f ", hsv_.h, hsv_.s, hsv_.v);
//    rgb_ = struct_hsv_to_rgb(hsv_.h, hsv_.s, hsv_.v);
//    printf("\nHSV3 : %f %f %f ", rgb_.r*255.0, rgb_.g * 255.0, rgb_.b * 255.0);
//
//}

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
            r = (float)round(ar1[0] * 255.0f);
            g = (float)round(ar1[1] * 255.0f);
            b = (float)round(ar1[2] * 255.0f);
   	        free(ar1);
            // printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
            // printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
            // printf("\n %f, %f, %f ", h, s, v);

            if (fabs(i - r) > 0.1f) {
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, s, v);
                        n+=1;
                return -1;
            }
            if (fabs(j - g) > 0.1f){
                printf("\n\nRGB VALUES:R:%i G:%i B:%i ", i, j, k);
                    printf("\nRGB VALUES:R:%f G:%f B:%f ", r, g, b);
                printf("\n %f, %f, %f ", h, s, v);
                        n+=1;
                return -1;
            }

            if (fabs(k - b) > 0.1f){
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
