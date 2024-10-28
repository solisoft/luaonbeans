FROM alpine:latest as build

ARG DOWNLOAD_FILENAME=redbean-3.0.0.com

RUN apk add --update bash
RUN wget https://redbean.dev/${DOWNLOAD_FILENAME} -O redbean.com
RUN chmod +x redbean.com
RUN wget https://cosmo.zip/pub/cosmos/bin/zip -O zip
RUN chmod +x zip

# normalize the binary to ELF
RUN sh /redbean.com --assimilate
RUN sh /zip --assimilate

COPY . /assets
WORKDIR /assets
# Add your files here
RUN /zip -r /redbean.com .init.lua
RUN /zip -r /redbean.com config
RUN /zip -r /redbean.com .lua
RUN /zip -r /redbean.com app
RUN /zip -r /redbean.com public
RUN /zip -r /redbean.com specs
RUN /zip -r /redbean.com migrations

RUN wget https://cosmo.zip/pub/cosmos/bin/assimilate-x86_64.elf -O /assimilate.elf

# FOR ARMV8
# RUN wget https://cosmo.zip/pub/cosmos/bin/assimilate-aarch64.elf -O /assimilate.elf

RUN chmod +x /assimilate.elf

FROM scratch
COPY --from=build --chmod=777 /assimilate.elf /redbean.com /
RUN ["/assimilate.elf", "/redbean.com"]
CMD ["/redbean.com", "-s", "-p", "8080"]
