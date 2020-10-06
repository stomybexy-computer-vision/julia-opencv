FROM julia

RUN mkdir /usr/share/man/man1/

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends python3.6 build-essential

RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends git cmake wget
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends libjpeg-dev libtiff-dev libpng-dev
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends libgtk-3-dev
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends libxvidcore-dev libx264-dev
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends libatlas-base-dev gfortran

# Build libcxxwrap-julia
WORKDIR /home/lib

COPY . .

RUN mkdir libcxxwrap-julia-build

RUN git clone https://github.com/JuliaInterop/libcxxwrap-julia.git

WORKDIR /home/lib/libcxxwrap-julia-build

RUN cmake -DJulia_EXECUTABLE=/usr/local/julia/bin/julia ../libcxxwrap-julia
RUN cmake --build . --config Release
RUN mkdir -p ~/.julia/artifacts
RUN echo "[3eaa8342-bff7-56a5-9981-c04077f7cee7]" > ~/.julia/artifacts/Overrides.toml
RUN echo 'libcxxwrap_julia = "/home/lib/libcxxwrap-julia-build"' >> ~/.julia/artifacts/Overrides.toml

# Install Cxx Wrap
WORKDIR /home/lib
RUN julia -q install_cxx_wrap.jl

# Install OpenCV
WORKDIR /home/lib
RUN git clone --depth 1 https://github.com/opencv/opencv.git
RUN git clone --depth=1 https://github.com/opencv/opencv_contrib.git
RUN mkdir opencv/build
WORKDIR /home/lib/opencv/build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_CUDA=OFF \
    -D WITH_JULIA=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/home/lib/opencv_contrib/modules \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D BUILD_EXAMPLES=ON ..

RUN make -j6
RUN make install

# Upgrade libstdc++ bundled with julia
RUN cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/local/julia/lib/julia/libstdc++.so.6


# Create sysimage to speed up OpenCV load
WORKDIR /home/lib
RUN julia -q precompile.jl

RUN echo "alias julia='julia -J /home/lib/opencvimg.so'" >> ~/.bashrc

CMD ["julia", "-J", "/home/lib/opencvimg.so"]
