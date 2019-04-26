FROM centos:7.6.1810 as builder

RUN yum -y groupinstall 'Development tools'
RUN yum -y install git latex2html texlive-epsf ncurses-devel
RUN mkdir /src
COPY icmake /src/icmake
WORKDIR /src/icmake/icmake
RUN ./icm_bootstrap /
RUN ./icm_install strip all /

COPY yodl-3.03.0 /src/yodl-3.03.0
WORKDIR /src/yodl-3.03.0
RUN ./build programs
RUN ./build man
RUN ./build macros
RUN ./build manual
RUN ./build install programs /
RUN ./build install man /
RUN ./build install macros /
RUN ./build install manual /
RUN ./build install docs /

RUN git clone git://git.code.sf.net/p/zsh/code /src/zsh
WORKDIR /src/zsh
RUN ./Util/preconfig
RUN ./configure --prefix=/usr/local --enable-locale --enable-multibyte -with-tcsetpgrp
RUN make clean
RUN make -j 4

COPY porg-0.10 /src/porg-0.10
WORKDIR /src/porg-0.10
RUN ./configure --prefix=/usr/local --disable-grop
RUN make && make install
WORKDIR /src/zsh
RUN porg -lD make install

FROM centos:7.6.1810
RUN yum -y install man
ADD .zshrc /root
COPY --from=builder /usr/local/bin/zsh /usr/local/bin/zsh
COPY --from=builder /usr/local/lib/zsh /usr/local/lib/zsh
COPY --from=builder /usr/local/share/zsh /usr/local/share/zsh
COPY --from=builder /usr/local/share/man/man1 /usr/local/share/man/man1
WORKDIR /root/
CMD ["/usr/local/bin/zsh"]
