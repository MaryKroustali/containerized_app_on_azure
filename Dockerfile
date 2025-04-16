#FROM mcr.microsoft.com/dotnet/sdk:4.8 AS build
FROM mono:6.12 AS build
WORKDIR /source
# copy csproj and restore as distinct layers
COPY *.sln .
COPY WebApplication8/*.csproj ./WebApplication8/
RUN nuget restore
# copy everything else and build app
COPY WebApplication8/. ./WebApplication8/
WORKDIR /source/WebApplication8
RUN msbuild /p:Configuration=Release
# Stage 2: Run the application using Mono (Linux-compatible)
FROM mono:6.12 AS runtime
# Set working directory in the container
RUN apt-get update && apt-get install -y mono-xsp4
WORKDIR /app
# Copy the built application from the build stage
COPY --from=build /source/WebApplication8/obj/Release/ ./
EXPOSE 80
# Run the DLL with Mono
ENTRYPOINT ["xsp4", "--port", "80", "--address", "0.0.0.0"]
