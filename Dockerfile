FROM alpine:latest as build

ARG DOWNLOAD_FILENAME=redbean-2.2.com

RUN apk add --update bash
RUN wget https://redbean.dev/${DOWNLOAD_FILENAME} -O redbean.com
#RUN wget https://cosmo.zip/pub/cosmos/bin/redbean -O redbean.com
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

FROM scratch

COPY --from=build /redbean.com /
CMD ["/redbean.com", "-s", "-p", "8080"]
