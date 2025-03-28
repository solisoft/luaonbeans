# FOR ARMV8
# RUN wget https://cosmo.zip/pub/cosmos/bin/assimilate-aarch64.elf -O /assimilate.elf


FROM alpine AS build
# Add your files here
COPY . /assets/
ARG REDBEAN_URL='https://cosmo.zip/pub/cosmos/bin/redbean'
ADD --chmod=777 https://cosmo.zip/pub/cosmos/bin/assimilate-x86_64.elf /assimilate
RUN apk add zip \
  && wget -O /redbean.com ${REDBEAN_URL} \
  && cd /assets \
  && zip -r -X /redbean.com * \
  && /assimilate /redbean.com

FROM scratch
WORKDIR /
COPY --from=build --chmod=777 /redbean.com /
ENTRYPOINT ["/redbean.com", "-s", "-p", "8080"]
EXPOSE 8080