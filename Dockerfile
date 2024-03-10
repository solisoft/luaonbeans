FROM alpine:latest as build

ARG DOWNLOAD_FILENAME=redbean-2.2.com

RUN apk add --update zip bash
RUN wget https://redbean.dev/${DOWNLOAD_FILENAME} -O redbean.com
RUN chmod +x redbean.com

# normalize the binary to ELF
RUN sh /redbean.com --assimilate

COPY . /assets
WORKDIR /assets
# Add your files here
RUN zip -r /redbean.com .init.lua
RUN zip -r /redbean.com .lua
RUN zip -r /redbean.com app
RUN zip -r /redbean.com public
RUN zip -r /redbean.com specs
RUN zip -r /redbean.com migrations
RUN zip -r /redbean.com config

FROM scratch

COPY --from=build /redbean.com /
CMD ["/redbean.com", "-s", "-p", "8080"]
