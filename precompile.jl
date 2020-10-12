import Pkg

Pkg.add("PackageCompiler")

Pkg.add("Plots")

using OpenCV
using Plots
using PackageCompiler

create_sysimage([:OpenCV, :Plots]; sysimage_path="opencvimg.so")
