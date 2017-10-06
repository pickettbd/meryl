#CXXFLAGS := -fopenmp -D_GLIBCXX_PARALLEL -O3 -fPIC -m64 -pipe -Wno-write-strings
#LDFLAGS  := -fopenmp -lm

TARGET       := posDB
SOURCES      := driver-posDB.C

SRC_INCDIRS := ../libutil ../libbio ../libseq ../libmeryl

TGT_LDFLAGS := -L${TARGET_DIR}/lib
TGT_LDLIBS  := -lkmer -lmeryl -lseq -lbio -lutil
TGT_PREREQS := libkmer.a libmeryl.a libseq.a libbio.a libutil.a

SUBMAKEFILES := 
