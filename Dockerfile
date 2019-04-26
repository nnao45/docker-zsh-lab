# 1st stage, for development container
FROM centos:7.6.1810 as builder

# Install package for development 
RUN yum -y groupinstall 'Development tools' && \
    yum -y install git latex2html texlive-epsf ncurses-devel

# build with icmake
RUN mkdir /src
COPY icmake /src/icmake
WORKDIR /src/icmake/icmake
RUN ./icm_bootstrap / && \
    ./icm_install strip all /

# build with yodl 
COPY yodl-3.03.0 /src/yodl-3.03.0
WORKDIR /src/yodl-3.03.0
RUN ./build programs && \
    ./build man && \
    ./build macros && \
    ./build manual && \
    ./build install programs / && \
    ./build install man / && \
    ./build install macros / && \
    ./build install manual / && \
    ./build install docs /

# build for zsh
RUN git clone git://git.code.sf.net/p/zsh/code /src/zsh
WORKDIR /src/zsh
RUN ./Util/preconfig && \
    ./configure --prefix=/usr/local --enable-locale --enable-multibyte -with-tcsetpgrp && \
    make clean && \
    make -j 4

# make install with porg
COPY porg-0.10 /src/porg-0.10
WORKDIR /src/porg-0.10
RUN ./configure --prefix=/usr/local --disable-grop && \
    make && make install
WORKDIR /src/zsh
RUN porg -lD make install

# 2nd stage, for runnning container
FROM centos:7.6.1810
RUN yum -y install man
ADD .zshrc /root
COPY --from=builder /usr/local/bin/zsh /usr/local/bin/zsh
COPY --from=builder /usr/local/lib/zsh /usr/local/lib/zsh
COPY --from=builder /usr/local/share/zsh /usr/local/share/zsh
COPY --from=builder /usr/local/share/man/man1 /usr/local/share/man/man1
WORKDIR /root/
CMD ["/usr/local/bin/zsh"]
