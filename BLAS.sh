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
    echo "BLAS selected, but BLAS_DIR not set.  Checking some places..."
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

if [ -z "${BLAS_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Building BLAS..."
    echo "END MESSAGE"
    
    # Set locations
    NAME=blas-3.2.1
    TARNAME=lapack-3.2.1
    SRCDIR=$(dirname $0)
    INSTALL_DIR=${SCRATCH_BUILD}
    BLAS_DIR=${INSTALL_DIR}/${NAME}

    # Clean up environment
    unset LIBS
    unset MAKEFLAGS
    
(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${INSTALL_DIR}
    if [ -e done-${NAME} -a done-${NAME} -nt ${SRCDIR}/dist/${TARNAME}.tgz \
                         -a done-${NAME} -nt ${SRCDIR}/BLAS.sh ]
    then
        echo "BLAS: The enclosed BLAS library has already been built; doing nothing"
    else
        echo "BLAS: Building enclosed BLAS library"
        
        echo "BLAS: Unpacking archive..."
        rm -rf build-${NAME}
        mkdir build-${NAME}
        pushd build-${NAME}
        # Should we use gtar or tar?
        TAR=$(gtar --help > /dev/null 2> /dev/null && echo gtar || echo tar)
        ${TAR} xzf ${SRCDIR}/dist/${TARNAME}.tgz
        popd
        
        echo "BLAS: Configuring..."
        rm -rf ${NAME}
        mkdir ${NAME}
        pushd build-${NAME}/${TARNAME}/BLAS/SRC
        
        echo "BLAS: Building..."
        ${F77} ${F77FLAGS} -c *.f
        ${AR} ${ARFLAGS} libblas.a *.o
	if [ ${USE_RANLIB} = 'yes' ]; then
	    ${RANLIB} ${RANLIBFLAGS} libblas.a
        fi
        
        echo "BLAS: Installing..."
        cp libblas.a ${BLAS_DIR}
        popd
        
        echo 'done' > done-${NAME}
        echo "BLAS: Done."
    fi
)

    if (( $? )); then
        echo 'BEGIN ERROR'
        echo 'Error while building BLAS.  Aborting.'
        echo 'END ERROR'
        exit 1
    fi

fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ "${BLAS_DIR}" != '/usr' -a "${BLAS_DIR}" != '/usr/local' ]; then
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
