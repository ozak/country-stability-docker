# docker build -t omerozak/stata-jupyter-docker
# docker run -d -p 8888:8888 omerozak/stata-jupyter-docker
# docker push omerozak/stata-jupyter-docker
# Create docker with stata18-mp and mambaforge

# syntax=docker/dockerfile:1.2

# Parameters
# This could be overridden when building 

ARG STATAVERSION=18
ARG STATATAG=2024-08-07
ARG STATAHUBID=dataeditors


## ================== Define base images =====================

# define the source for Stata
#FROM ${STATAHUBID}/stata-mp${STATAVERSION}:${STATATAG} as stata
FROM dataeditors/stata18-mp:2024-08-07 as stata

# Create docker for replication
FROM condaforge/mambaforge

# updates just in case
RUN apt update

# Install Git (if not already installed)
RUN apt-get install -y git

# Create
ENV PROJ_LIB "/opt/conda/share/proj"

# Create environment
RUN conda install mamba -y -c conda-forge --override-channels

# Initialize shell to work with conda
RUN conda init bash

COPY --from=stata /usr/local/stata/ /usr/local/stata/
RUN echo "export PATH=/usr/local/stata:${PATH}" >> /root/.bashrc
ENV PATH "$PATH:/usr/local/stata" 

# To run stata, you need to mount the Stata license file
# by passing it in during runtime: -v stata.lic:/usr/local/stata/stata.lic

# Create and configure the country-stability environment
RUN conda init bash && mamba init bash && mamba create -n country-stability -c conda-forge --override-channels python=3.11 ipython=8.10.0 \
  dask=2023.6.0 dask-labextension=6.1.0 geopandas=0.12.2 geos=3.11.1 gdal=3.6.2 geoplot=0.5.1 georasters ipyparallel=8.4.1 \
  jupyter=1.0.0 jupyterlab=3.5.3 jupyter_contrib_nbextensions nb_conda_kernels=2.3.1 nbclassic=0.5.1 nbclient=0.7.2 \
  nbconvert=7.2.9 mapclassify matplotlib matplotlib-base nodejs numpy nb_conda_kernels pandas pandas-datareader plotly \
  pip pycountry pyproj requests scipy seaborn shapely scikit-learn stata_kernel statsmodels unidecode xlrd \
  && echo 'source activate country-stability' > ~/.bashrc \
  && mamba run -n country-stability pip install geonamescache linearmodels isounidecode geocoder stargazer jupyter_nbextensions_configurator \
  && mamba run -n country-stability python -m stata_kernel.install \
  && mamba run -n country-stability jupyter lab build --dev-build \
  && mamba env list
  
RUN /bin/bash -c "source activate country-stability"
#RUN mamba activate country-stability 

# Set environment activation command
#RUN echo "mamba activate country-stability"  >> /root/.bashrc
#RUN echo "mamba activate country-stability"  >> /home/.bashrc
#RUN echo "$CONDA_PREFIX"

#ENV CONDA_PREFIX "$CONDA_PREFIX"

#RUN mamba run -n country-stability \
#  wget https://raw.githubusercontent.com/ticoneva/codemirror-legacy-stata/main/stata.js -P $CONDA_PREFIX/share/jupyter/lab/staging/node_modules/@codemirror/legacy-modes/mode/ && \
#  mamba run -n country-stability file="$CONDA_PREFIX/share/jupyter/lab/staging/node_modules/@jupyterlab/codemirror/lib/language.js" && \
#  mamba run -n country-stability squirrel_block="{name: 'Squirrel',displayName: trans.__('Squirrel'),mime: 'text/x-squirrel',extensions: ['nut'],async load() {const m = await import('@codemirror/legacy-modes/mode/clike');return legacy(m.squirrel);}}" && \
#  mamba run -n country-stability insert_text="{name: 'stata',displayName: trans.__('Stata'),mime: 'text/x-stata',extensions: ['do','ado'],async load() {const m = await import('@codemirror/legacy-modes/mode/stata');return legacy(m.stata);}}" && \
#  mamba run -n country-stability sed -i "/$(echo $squirrel_block | sed 's/[\/&]/\\&/g')/a $(echo $insert_text | sed 's/[\/&]/\\&/g')" "$file" && \
#  mamba run -n country-stability jupyter lab build --dev-build && \
#  mamba run -n country-stability python -m ipykernel install --user --name=conda-env-country-stability-py

# Set environment activation command
RUN echo "source activate country-stability"  >> /root/.bashrc
RUN echo "source activate country-stability"  >> /home/.bashrc

RUN /bin/bash -c "source activate country-stability"

# Expose the port JupyterLab will run on (default is 9000)
EXPOSE 9000

# Start JupyterLab when the container runs
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=9000", "--no-browser", "--allow-root", "--NotebookApp.token='docker'"]
