import Pkg

Pkg.add("PackageCompiler")

using OpenCV
using PackageCompiler

create_sysimage(:OpenCV; sysimage_path="opencvimg.so")
