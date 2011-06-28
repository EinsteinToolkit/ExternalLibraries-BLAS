#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${BLAS_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "BLAS selected, but BLAS_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="libblas.a libblas.so"
    DIRS="/usr/lib /usr/local/lib /usr/lib/atlas ${HOME}"
    for file in $FILES; do
        for dir in $DIRS; do
            if test -r "$dir/$file"; then
                BLAS_DIR="$dir"
                break
            fi
        done
    done
    
    if [ -z "$BLAS_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "BLAS not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found BLAS in ${BLAS_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${BLAS_DIR}" -o "${BLAS_DIR}" = 'BUILD' ]; then
    echo "BEGIN MESSAGE"
    echo "Building BLAS..."
    echo "END MESSAGE"
    
    # Set locations
    THORN=BLAS
    NAME=blas-3.3.1
    TARNAME=lapack-3.3.1
    SRCDIR=$(dirname $0)
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    BLAS_DIR=${INSTALL_DIR}
    
    if [ "${F77}" = "none" ]; then
        echo 'BEGIN ERROR'
        echo "Building BLAS requires a fortran compiler, but there is none configured: F77 = $F77.  Aborting."
        echo 'END ERROR'
        exit 1
    fi

(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${SCRATCH_BUILD}
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${TARNAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/BLAS.sh ]
    then
        echo "BLAS: The enclosed BLAS library has already been built; doing nothing"
    else
        echo "BLAS: Building enclosed BLAS library"
        
        # Set up environment
        unset LIBS
	if [ ${USE_RANLIB} != 'yes' ]; then
            RANLIB=': ranlib'
        fi
        
        echo "BLAS: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "BLAS: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR} xzf ${SRCDIR}/dist/${TARNAME}.tgz
        
        echo "BLAS: Configuring..."
        cd ${TARNAME}/BLAS/SRC
        
        echo "BLAS: Building..."
        if echo ${F77} | grep -i xlf > /dev/null 2>&1; then
            FIXEDF77FLAGS=-qfixed
        fi
        #${F77} ${F77FLAGS} ${FIXEDF77FLAGS} -c *.f
        #${AR} ${ARFLAGS} libblas.a *.o
	#if [ ${USE_RANLIB} = 'yes' ]; then
	#    ${RANLIB} ${RANLIBFLAGS} libblas.a
        #fi
        cat > make.cactus <<EOF
SRCS = $(echo *.f)
libblas.a: \$(SRCS:%.f=%.o)
	${AR} ${ARFLAGS} \$@ \$^
	${RANLIB} ${RANLIBFLAGS} \$@
%.o: %.f
	${F77} ${F77FLAGS} ${FIXEDF77FLAGS} -c \$*.f -o \$*.o
EOF
        ${MAKE} -f make.cactus
        
        echo "BLAS: Installing..."
        cp libblas.a ${BLAS_DIR}
        popd
        
        echo "BLAS: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "BLAS: Done."
    fi
)

    if (( $? )); then
        echo 'BEGIN ERROR'
        echo 'Error while building BLAS. Aborting.'
        echo 'END ERROR'
        exit 1
    fi

fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ "${BLAS_DIR}" != '/usr/lib' -a "${BLAS_DIR}" != '/usr/local/lib' ]; then
    BLAS_INC_DIRS=
    BLAS_LIB_DIRS="${BLAS_DIR}"
fi
: ${BLAS_LIBS='blas'}

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_BLAS     = 1"
echo "BLAS_DIR      = ${BLAS_DIR}"
echo "BLAS_INC_DIRS = ${BLAS_INC_DIRS}"
echo "BLAS_LIB_DIRS = ${BLAS_LIB_DIRS}"
echo "BLAS_LIBS     = ${BLAS_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(BLAS_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(BLAS_LIB_DIRS)'
echo 'LIBRARY           $(BLAS_LIBS)'
