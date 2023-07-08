
from Cython.Build import cythonize

# encoding: utf-8
# USE :
# python setup.py build_ext --inplace

from distutils.core import setup
from distutils.extension import Extension

import numpy

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore", category=FutureWarning)

# DO NOT USE
# <<<  ---- The line below will break the compilation of LIGHTS.ccp >>>
# define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")]


# /O2 sets a combination of optimizations that optimizes code for maximum speed.
# /Ot (a default setting) tells the compiler to favor optimizations for speed over optimizations for size.
# /Oy suppresses the creation of frame pointers on the call stack for quicker function calls.
setup(
    name='COBRA',
    ext_modules=cythonize(Extension(
            "*", ['*.pyx'], extra_compile_args=["/Qpar", "/fp:fast", "/O2", "/Oy", "/Ot"],
        language="c++",
        )
    ),

    include_dirs=[numpy.get_include()],


    )


#
# setup(
#     name='COBRA',
#     ext_modules=cythonize(["*.pyx"]),
#     include_dirs=[numpy.get_include()], language="c")
